-- CivicVote production capability layer
--
-- This migration upgrades the initial single-choice proof-of-concept into a
-- multi-contest, eligibility-assigned ballot system. It is intentionally
-- server-authoritative: Flutter can request actions, but only database policies
-- and RPCs decide who may verify, assign, publish, or submit a ballot.
--
-- IMPORTANT: This separates future anonymous ballot rows from voter assignment
-- rows. It materially improves the data model over the legacy `votes` table,
-- but jurisdiction-specific ballot secrecy requirements still need independent
-- cryptographic and legal review (see docs/SECURITY_MODEL.md).

create table if not exists public.user_roles (
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('verifier', 'election_manager', 'auditor', 'administrator')),
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id) on delete set null,
  primary key (user_id, role)
);

create or replace function private.has_role(p_role text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.user_roles user_role
    where user_role.user_id = (select auth.uid())
      and user_role.role = p_role
  );
$$;

create or replace function private.has_any_role(p_roles text[])
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.user_roles user_role
    where user_role.user_id = (select auth.uid())
      and user_role.role = any(p_roles)
  );
$$;

revoke all on function private.has_role(text) from public;
revoke all on function private.has_any_role(text[]) from public;

alter table public.elections
  add column if not exists requires_mfa boolean not null default false,
  add column if not exists published_at timestamptz;

create table if not exists public.contests (
  id uuid primary key default gen_random_uuid(),
  election_id uuid not null references public.elections(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 180),
  instructions text not null default 'Choose one option.',
  contest_type text not null default 'single_choice'
    check (contest_type in ('single_choice', 'referendum')),
  seats integer not null default 1 check (seats = 1),
  position integer not null check (position > 0),
  is_required boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (election_id, position)
);

alter table public.candidates add column if not exists contest_id uuid;

-- Preserve all existing candidate records by creating one default contest for
-- every old election, then attaching its existing candidates to that contest.
insert into public.contests (election_id, title, instructions, contest_type, seats, position)
select
  election.id,
  election.title,
  'Choose one candidate.',
  'single_choice',
  1,
  1
from public.elections election
on conflict (election_id, position) do nothing;

update public.candidates candidate
set contest_id = contest.id
from public.contests contest
where candidate.election_id = contest.election_id
  and contest.position = 1
  and candidate.contest_id is null;

alter table public.candidates alter column contest_id set not null;
alter table public.candidates
  drop constraint if exists candidates_election_id_ballot_position_key;
alter table public.candidates
  add constraint candidates_contest_ballot_position_key unique (contest_id, ballot_position);
alter table public.candidates
  add constraint candidates_contest_id_fkey
  foreign key (contest_id) references public.contests(id) on delete restrict;

create index if not exists contests_election_position_idx
  on public.contests (election_id, position);
create index if not exists candidates_contest_position_idx
  on public.candidates (contest_id, ballot_position);

create table if not exists public.ballot_assignments (
  id uuid primary key default gen_random_uuid(),
  election_id uuid not null references public.elections(id) on delete cascade,
  voter_id uuid not null references auth.users(id) on delete cascade,
  eligibility_status text not null default 'eligible'
    check (eligibility_status in ('eligible', 'ineligible', 'suspended')),
  submission_state text not null default 'eligible'
    check (submission_state in ('eligible', 'submitted', 'ineligible')),
  assigned_at timestamptz not null default now(),
  assigned_by uuid references auth.users(id) on delete set null,
  submitted_at timestamptz,
  receipt_code text unique,
  updated_at timestamptz not null default now(),
  unique (election_id, voter_id),
  constraint ballot_assignment_submission_consistency check (
    (submission_state = 'submitted' and submitted_at is not null and receipt_code is not null)
    or (submission_state <> 'submitted')
  )
);

-- Future ballots intentionally contain no voter_id, assignment_id, receipt, or
-- foreign key that can be joined to an identity by a client-facing API.
create table if not exists public.anonymous_votes (
  id uuid primary key default gen_random_uuid(),
  election_id uuid not null references public.elections(id) on delete restrict,
  contest_id uuid not null references public.contests(id) on delete restrict,
  candidate_id uuid not null references public.candidates(id) on delete restrict,
  cast_at timestamptz not null default now()
);

create index if not exists ballot_assignments_voter_idx
  on public.ballot_assignments (voter_id, election_id);
create index if not exists anonymous_votes_candidate_idx
  on public.anonymous_votes (candidate_id);
create index if not exists anonymous_votes_contest_idx
  on public.anonymous_votes (contest_id);

create table if not exists public.result_snapshots (
  candidate_id uuid primary key references public.candidates(id) on delete cascade,
  election_id uuid not null references public.elections(id) on delete cascade,
  contest_id uuid not null references public.contests(id) on delete cascade,
  contest_title text not null,
  full_name text not null,
  party_name text not null default '',
  party_abbreviation text not null default '',
  accent_color text not null default '#1D5FD0',
  votes integer not null default 0 check (votes >= 0),
  updated_at timestamptz not null default now()
);

create or replace function private.refresh_result_snapshot(p_candidate_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.result_snapshots (
    candidate_id,
    election_id,
    contest_id,
    contest_title,
    full_name,
    party_name,
    party_abbreviation,
    accent_color,
    votes,
    updated_at
  )
  select
    candidate.id,
    candidate.election_id,
    candidate.contest_id,
    contest.title,
    candidate.full_name,
    candidate.party_name,
    candidate.party_abbreviation,
    candidate.accent_color,
    (
      select count(*)::integer
      from public.anonymous_votes anonymous_vote
      where anonymous_vote.candidate_id = candidate.id
    ),
    now()
  from public.candidates candidate
  join public.contests contest on contest.id = candidate.contest_id
  where candidate.id = p_candidate_id
  on conflict (candidate_id) do update
  set
    election_id = excluded.election_id,
    contest_id = excluded.contest_id,
    contest_title = excluded.contest_title,
    full_name = excluded.full_name,
    party_name = excluded.party_name,
    party_abbreviation = excluded.party_abbreviation,
    accent_color = excluded.accent_color,
    votes = excluded.votes,
    updated_at = excluded.updated_at;
end;
$$;

create or replace function private.sync_candidate_result_snapshot()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.refresh_result_snapshot(new.id);
  return new;
end;
$$;

create or replace function private.bump_anonymous_result_snapshot()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.refresh_result_snapshot(new.candidate_id);
  return new;
end;
$$;

drop trigger if exists candidates_sync_result_snapshot on public.candidates;
create trigger candidates_sync_result_snapshot
  after insert or update of full_name, party_name, party_abbreviation, accent_color, contest_id on public.candidates
  for each row execute function private.sync_candidate_result_snapshot();

drop trigger if exists anonymous_votes_bump_result_snapshot on public.anonymous_votes;
create trigger anonymous_votes_bump_result_snapshot
  after insert on public.anonymous_votes
  for each row execute function private.bump_anonymous_result_snapshot();

insert into public.result_snapshots (
  candidate_id,
  election_id,
  contest_id,
  contest_title,
  full_name,
  party_name,
  party_abbreviation,
  accent_color,
  votes,
  updated_at
)
select
  candidate.id,
  candidate.election_id,
  candidate.contest_id,
  contest.title,
  candidate.full_name,
  candidate.party_name,
  candidate.party_abbreviation,
  candidate.accent_color,
  0,
  now()
from public.candidates candidate
join public.contests contest on contest.id = candidate.contest_id
on conflict (candidate_id) do nothing;

-- Replace the original count view with result snapshots. It still exposes only
-- aggregate counts and only after an authority makes results visible.
drop view if exists public.election_results;
create view public.election_results
with (security_barrier = true)
as
with visible_results as (
  select
    snapshot.election_id,
    snapshot.contest_id,
    snapshot.contest_title,
    snapshot.candidate_id,
    snapshot.full_name,
    snapshot.party_name,
    snapshot.party_abbreviation,
    snapshot.accent_color,
    snapshot.votes
  from public.result_snapshots snapshot
  join public.elections election on election.id = snapshot.election_id
  where election.is_public = true
    and election.results_visible = true
)
select
  election_id,
  contest_id,
  contest_title,
  candidate_id,
  full_name,
  party_name,
  party_abbreviation,
  accent_color,
  votes,
  coalesce(sum(votes) over (partition by contest_id), 0)::integer as total_votes,
  rank() over (partition by contest_id order by votes desc, full_name asc)::integer as rank
from visible_results;

grant select on table public.election_results to anon, authenticated;

create table if not exists public.notification_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  election_reminders boolean not null default true,
  verification_updates boolean not null default true,
  results_updates boolean not null default true,
  updated_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  notification_type text not null default 'general',
  title text not null check (char_length(title) between 1 and 160),
  body text not null check (char_length(body) between 1 and 500),
  action_route text,
  dedupe_key text unique,
  created_at timestamptz not null default now(),
  read_at timestamptz,
  delivered_at timestamptz
);

create index if not exists notifications_user_created_idx
  on public.notifications (user_id, created_at desc);

create table if not exists public.audit_events (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references auth.users(id) on delete set null,
  event_type text not null,
  target_type text not null,
  target_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default now()
);

create index if not exists audit_events_occurred_idx
  on public.audit_events (occurred_at desc);

create or replace function private.log_audit(
  p_event_type text,
  p_target_type text,
  p_target_id uuid,
  p_metadata jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.audit_events (actor_id, event_type, target_type, target_id, metadata)
  values ((select auth.uid()), p_event_type, p_target_type, p_target_id, coalesce(p_metadata, '{}'::jsonb));
end;
$$;

create or replace function private.create_default_notification_preferences()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.notification_preferences (user_id)
  values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_profile_created_notification_preferences on public.profiles;
create trigger on_profile_created_notification_preferences
  after insert on public.profiles
  for each row execute function private.create_default_notification_preferences();

insert into public.notification_preferences (user_id)
select profile.id from public.profiles profile
on conflict (user_id) do nothing;

alter table public.user_roles enable row level security;
alter table public.contests enable row level security;
alter table public.ballot_assignments enable row level security;
alter table public.anonymous_votes enable row level security;
alter table public.result_snapshots enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.notifications enable row level security;
alter table public.audit_events enable row level security;

revoke all on table public.user_roles from anon, authenticated;
revoke all on table public.ballot_assignments from anon, authenticated;
revoke all on table public.anonymous_votes from anon, authenticated;
revoke all on table public.notification_preferences from anon, authenticated;
revoke all on table public.notifications from anon, authenticated;
revoke all on table public.audit_events from anon, authenticated;
revoke all on table public.contests from anon, authenticated;
revoke all on table public.result_snapshots from anon, authenticated;

grant select on table public.contests to anon, authenticated;
grant select on table public.result_snapshots to anon, authenticated;
grant select on table public.notifications to authenticated;
grant select on table public.profiles to authenticated;

create policy "public can read contests on published elections"
on public.contests
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.elections election
    where election.id = contests.election_id
      and election.is_public = true
  )
);

create policy "authorities can read all contests"
on public.contests
for select
to authenticated
using ((select private.has_any_role(array['administrator', 'election_manager', 'verifier', 'auditor'])));

create policy "managers can manage contests"
on public.contests
for all
to authenticated
using ((select private.has_any_role(array['administrator', 'election_manager'])))
with check ((select private.has_any_role(array['administrator', 'election_manager'])));

create policy "authorities can read all elections"
on public.elections
for select
to authenticated
using ((select private.has_any_role(array['administrator', 'election_manager', 'verifier', 'auditor'])));

create policy "managers can manage elections"
on public.elections
for all
to authenticated
using ((select private.has_any_role(array['administrator', 'election_manager'])))
with check ((select private.has_any_role(array['administrator', 'election_manager'])));

create policy "authorities can read all candidates"
on public.candidates
for select
to authenticated
using ((select private.has_any_role(array['administrator', 'election_manager', 'verifier', 'auditor'])));

create policy "managers can manage candidates"
on public.candidates
for all
to authenticated
using ((select private.has_any_role(array['administrator', 'election_manager'])))
with check ((select private.has_any_role(array['administrator', 'election_manager'])));

create policy "administrators can read roles"
on public.user_roles
for select
to authenticated
using ((select private.has_role('administrator')));

create policy "administrators can manage roles"
on public.user_roles
for all
to authenticated
using ((select private.has_role('administrator')))
with check ((select private.has_role('administrator')));

create policy "authorities can read verification profiles"
on public.profiles
for select
to authenticated
using (
  (select auth.uid()) = id
  or (select private.has_any_role(array['administrator', 'verifier', 'election_manager', 'auditor']))
);

create policy "authorities can manage assignments"
on public.ballot_assignments
for all
to authenticated
using ((select private.has_any_role(array['administrator', 'verifier', 'election_manager'])))
with check ((select private.has_any_role(array['administrator', 'verifier', 'election_manager'])));

create policy "public can read released result snapshots"
on public.result_snapshots
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.elections election
    where election.id = result_snapshots.election_id
      and election.is_public = true
      and election.results_visible = true
  )
);

create policy "voters can read their notifications"
on public.notifications
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "authorities can inspect audit events"
on public.audit_events
for select
to authenticated
using ((select private.has_any_role(array['administrator', 'auditor'])));

-- The original proof-of-concept write function is disabled. New submissions use
-- submit_ballot(), which does not write a voter id next to a candidate choice.
revoke all on function public.cast_vote(uuid, uuid) from authenticated;

create or replace function public.get_my_roles()
returns table (role text)
language sql
stable
security definer
set search_path = ''
as $$
  select 'voter'::text
  where (select auth.uid()) is not null
  union
  select user_role.role
  from public.user_roles user_role
  where user_role.user_id = (select auth.uid());
$$;

create or replace function public.get_my_elections()
returns table (
  id uuid,
  title text,
  description text,
  jurisdiction text,
  status text,
  starts_at timestamptz,
  ends_at timestamptz,
  registered_voters integer,
  results_visible boolean,
  is_public boolean,
  requires_mfa boolean,
  contest_count integer,
  submission_state text
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    election.id,
    election.title,
    election.description,
    election.jurisdiction,
    election.status,
    election.starts_at,
    election.ends_at,
    election.registered_voters,
    election.results_visible,
    election.is_public,
    election.requires_mfa,
    count(contest.id)::integer as contest_count,
    assignment.submission_state
  from public.ballot_assignments assignment
  join public.elections election on election.id = assignment.election_id
  left join public.contests contest on contest.election_id = election.id
  where assignment.voter_id = (select auth.uid())
    and assignment.eligibility_status = 'eligible'
    and election.is_public = true
  group by
    election.id,
    assignment.submission_state
  order by election.starts_at asc;
$$;

create or replace function public.get_my_ballot_status(p_election_id uuid)
returns table (
  election_id uuid,
  submission_state text,
  requires_mfa boolean,
  receipt_code text,
  submitted_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    assignment.election_id,
    assignment.submission_state,
    election.requires_mfa,
    assignment.receipt_code,
    assignment.submitted_at
  from public.ballot_assignments assignment
  join public.elections election on election.id = assignment.election_id
  where assignment.election_id = p_election_id
    and assignment.voter_id = (select auth.uid());
$$;

create or replace function public.submit_ballot(
  p_election_id uuid,
  p_choices jsonb
)
returns table (receipt_code text, submitted_at timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_voter_id uuid := (select auth.uid());
  v_assignment_id uuid;
  v_receipt_code text;
  v_now timestamptz := now();
  v_requires_mfa boolean;
  v_required_contests integer;
  v_choice_count integer;
begin
  if v_voter_id is null then
    raise exception 'You must be signed in to submit a ballot.' using errcode = '28000';
  end if;

  if jsonb_typeof(p_choices) <> 'array' then
    raise exception 'Ballot choices must be provided as an array.' using errcode = '22023';
  end if;

  select election.requires_mfa
  into v_requires_mfa
  from public.elections election
  where election.id = p_election_id
    and election.status = 'live'
    and election.starts_at <= v_now
    and election.ends_at > v_now
  for share;
  if not found then
    raise exception 'This election is not open for voting.' using errcode = '22023';
  end if;

  if v_requires_mfa
    and coalesce((select auth.jwt() ->> 'aal'), 'aal1') <> 'aal2' then
    raise exception 'A second factor is required before submitting this ballot.' using errcode = '42501';
  end if;

  perform 1
  from public.profiles profile
  where profile.id = v_voter_id
    and profile.verification_status = 'verified';
  if not found then
    raise exception 'Your voter profile is not verified.' using errcode = '42501';
  end if;

  select assignment.id
  into v_assignment_id
  from public.ballot_assignments assignment
  where assignment.election_id = p_election_id
    and assignment.voter_id = v_voter_id
    and assignment.eligibility_status = 'eligible'
    and assignment.submission_state = 'eligible'
  for update;
  if not found then
    raise exception 'You are not assigned an eligible ballot for this election, or it is already submitted.'
      using errcode = '42501';
  end if;

  if exists (
    select 1
    from jsonb_to_recordset(p_choices) as choice(contest_id uuid, candidate_id uuid)
    group by choice.contest_id
    having count(*) > 1
  ) then
    raise exception 'Only one option can be selected in each contest.' using errcode = '22023';
  end if;

  select count(*)::integer
  into v_required_contests
  from public.contests contest
  where contest.election_id = p_election_id
    and contest.is_required = true;

  select count(*)::integer
  into v_choice_count
  from jsonb_to_recordset(p_choices) as choice(contest_id uuid, candidate_id uuid);

  if v_choice_count < v_required_contests then
    raise exception 'Choose one option in every required contest before submitting.' using errcode = '22023';
  end if;

  if exists (
    select 1
    from public.contests contest
    where contest.election_id = p_election_id
      and contest.is_required = true
      and not exists (
        select 1
        from jsonb_to_recordset(p_choices) as choice(contest_id uuid, candidate_id uuid)
        where choice.contest_id = contest.id
      )
  ) then
    raise exception 'A required contest is missing from this ballot.' using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_to_recordset(p_choices) as choice(contest_id uuid, candidate_id uuid)
    left join public.candidates candidate
      on candidate.id = choice.candidate_id
      and candidate.contest_id = choice.contest_id
      and candidate.election_id = p_election_id
    left join public.contests contest
      on contest.id = choice.contest_id
      and contest.election_id = p_election_id
    where candidate.id is null or contest.id is null
  ) then
    raise exception 'One or more choices do not belong to this ballot.' using errcode = '22023';
  end if;

  insert into public.anonymous_votes (election_id, contest_id, candidate_id, cast_at)
  select
    p_election_id,
    choice.contest_id,
    choice.candidate_id,
    v_now
  from jsonb_to_recordset(p_choices) as choice(contest_id uuid, candidate_id uuid);

  v_receipt_code := upper(substring(replace(gen_random_uuid()::text, '-', '') from 1 for 12));

  update public.ballot_assignments
  set
    submission_state = 'submitted',
    submitted_at = v_now,
    receipt_code = v_receipt_code,
    updated_at = v_now
  where id = v_assignment_id;

  insert into public.notifications (
    user_id,
    notification_type,
    title,
    body,
    action_route,
    dedupe_key
  )
  values (
    v_voter_id,
    'ballot_submitted',
    'Ballot submission recorded',
    'Your ballot was accepted. Your receipt proves submission and does not reveal any selection.',
    '/ballot/' || p_election_id::text,
    'ballot-submitted:' || v_assignment_id::text
  )
  on conflict (dedupe_key) do nothing;

  perform private.log_audit(
    'ballot_submitted',
    'ballot_assignment',
    v_assignment_id,
    jsonb_build_object('election_id', p_election_id)
  );

  return query select v_receipt_code, v_now;
end;
$$;

create or replace function public.get_my_notification_preferences()
returns table (
  election_reminders boolean,
  verification_updates boolean,
  results_updates boolean
)
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null then
    raise exception 'You must be signed in.' using errcode = '28000';
  end if;

  insert into public.notification_preferences (user_id)
  values ((select auth.uid()))
  on conflict (user_id) do nothing;

  return query
  select
    preference.election_reminders,
    preference.verification_updates,
    preference.results_updates
  from public.notification_preferences preference
  where preference.user_id = (select auth.uid());
end;
$$;

create or replace function public.set_my_notification_preferences(p_preferences jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null then
    raise exception 'You must be signed in.' using errcode = '28000';
  end if;

  insert into public.notification_preferences (
    user_id,
    election_reminders,
    verification_updates,
    results_updates,
    updated_at
  )
  values (
    (select auth.uid()),
    coalesce((p_preferences ->> 'election_reminders')::boolean, true),
    coalesce((p_preferences ->> 'verification_updates')::boolean, true),
    coalesce((p_preferences ->> 'results_updates')::boolean, true),
    now()
  )
  on conflict (user_id) do update
  set
    election_reminders = excluded.election_reminders,
    verification_updates = excluded.verification_updates,
    results_updates = excluded.results_updates,
    updated_at = excluded.updated_at;
end;
$$;

create or replace function public.mark_notification_read(p_notification_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.notifications notification
  set read_at = coalesce(notification.read_at, now())
  where notification.id = p_notification_id
    and notification.user_id = (select auth.uid());
end;
$$;

create or replace function public.admin_dashboard_metrics()
returns table (
  pending_verifications integer,
  live_elections integer,
  eligible_assignments integer,
  submitted_ballots integer
)
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not (select private.has_any_role(array['administrator', 'verifier', 'election_manager', 'auditor'])) then
    raise exception 'Administrative access is required.' using errcode = '42501';
  end if;

  return query
  select
    (select count(*)::integer from public.profiles where verification_status = 'pending'),
    (select count(*)::integer from public.elections where status = 'live'),
    (select count(*)::integer from public.ballot_assignments where eligibility_status = 'eligible'),
    (select count(*)::integer from public.ballot_assignments where submission_state = 'submitted');
end;
$$;

create or replace function public.admin_recent_audit_events()
returns table (
  id uuid,
  event_type text,
  target_type text,
  occurred_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not (select private.has_any_role(array['administrator', 'auditor'])) then
    raise exception 'Audit access is required.' using errcode = '42501';
  end if;

  return query
  select event.id, event.event_type, event.target_type, event.occurred_at
  from public.audit_events event
  order by event.occurred_at desc
  limit 30;
end;
$$;

create or replace function public.admin_pending_voters()
returns table (
  id uuid,
  display_name text,
  verification_status text,
  jurisdiction text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not (select private.has_any_role(array['administrator', 'verifier'])) then
    raise exception 'Verification access is required.' using errcode = '42501';
  end if;

  return query
  select
    profile.id,
    profile.display_name,
    profile.verification_status,
    profile.jurisdiction,
    profile.created_at
  from public.profiles profile
  where profile.verification_status = 'pending'
  order by profile.created_at asc;
end;
$$;

create or replace function public.admin_set_voter_verification(
  p_voter_id uuid,
  p_verification_status text,
  p_jurisdiction text default null,
  p_masked_reference text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_title text;
  v_body text;
begin
  if not (select private.has_any_role(array['administrator', 'verifier'])) then
    raise exception 'Verification access is required.' using errcode = '42501';
  end if;
  if p_verification_status not in ('verified', 'rejected', 'pending') then
    raise exception 'An invalid verification state was supplied.' using errcode = '22023';
  end if;

  update public.profiles
  set
    verification_status = p_verification_status,
    jurisdiction = coalesce(p_jurisdiction, jurisdiction),
    voter_reference = coalesce(p_masked_reference, voter_reference),
    updated_at = now()
  where id = p_voter_id;
  if not found then
    raise exception 'The voter profile was not found.' using errcode = '22023';
  end if;

  v_title := case p_verification_status
    when 'verified' then 'Voter verification complete'
    when 'rejected' then 'Voter verification needs attention'
    else 'Voter verification is pending'
  end;
  v_body := case p_verification_status
    when 'verified' then 'Your voter profile has been verified. Eligible ballots will appear when assigned.'
    when 'rejected' then 'Contact the election authority to resolve your verification status.'
    else 'Your voter profile is awaiting authority review.'
  end;

  insert into public.notifications (user_id, notification_type, title, body, action_route)
  select p_voter_id, 'verification_update', v_title, v_body, '/profile'
  where exists (
    select 1
    from public.notification_preferences preference
    where preference.user_id = p_voter_id
      and preference.verification_updates = true
  );

  perform private.log_audit(
    'voter_verification_updated',
    'profile',
    p_voter_id,
    jsonb_build_object('verification_status', p_verification_status)
  );
end;
$$;

create or replace function public.admin_assign_voter_to_election(
  p_voter_id uuid,
  p_election_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not (select private.has_any_role(array['administrator', 'verifier', 'election_manager'])) then
    raise exception 'Assignment access is required.' using errcode = '42501';
  end if;

  perform 1 from public.profiles where id = p_voter_id and verification_status = 'verified';
  if not found then
    raise exception 'Only verified voter profiles can receive a ballot assignment.' using errcode = '22023';
  end if;
  perform 1 from public.elections where id = p_election_id;
  if not found then
    raise exception 'The election was not found.' using errcode = '22023';
  end if;

  insert into public.ballot_assignments (election_id, voter_id, assigned_by)
  values (p_election_id, p_voter_id, (select auth.uid()))
  on conflict (election_id, voter_id) do update
  set
    eligibility_status = 'eligible',
    submission_state = case
      when public.ballot_assignments.submission_state = 'submitted' then 'submitted'
      else 'eligible'
    end,
    assigned_by = excluded.assigned_by,
    updated_at = now();

  perform private.log_audit(
    'voter_assigned_to_election',
    'election',
    p_election_id,
    jsonb_build_object('voter_id', p_voter_id)
  );
end;
$$;

create or replace function public.admin_create_election(p_election jsonb)
returns table (
  id uuid,
  title text,
  description text,
  jurisdiction text,
  status text,
  starts_at timestamptz,
  ends_at timestamptz,
  registered_voters integer,
  results_visible boolean,
  is_public boolean,
  requires_mfa boolean,
  contest_count integer,
  submission_state text
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_election_id uuid;
begin
  if not (select private.has_any_role(array['administrator', 'election_manager'])) then
    raise exception 'Election management access is required.' using errcode = '42501';
  end if;

  insert into public.elections (
    title,
    description,
    jurisdiction,
    status,
    starts_at,
    ends_at,
    registered_voters,
    is_public,
    results_visible,
    requires_mfa,
    published_at
  )
  values (
    nullif(trim(p_election ->> 'title'), ''),
    coalesce(p_election ->> 'description', ''),
    nullif(trim(p_election ->> 'jurisdiction'), ''),
    coalesce(p_election ->> 'status', 'upcoming'),
    (p_election ->> 'starts_at')::timestamptz,
    (p_election ->> 'ends_at')::timestamptz,
    coalesce((p_election ->> 'registered_voters')::integer, 0),
    coalesce((p_election ->> 'is_public')::boolean, false),
    coalesce((p_election ->> 'results_visible')::boolean, false),
    coalesce((p_election ->> 'requires_mfa')::boolean, true),
    case when coalesce((p_election ->> 'is_public')::boolean, false) then now() else null end
  )
  returning public.elections.id into v_election_id;

  insert into public.contests (election_id, title, instructions, contest_type, seats, position)
  values (v_election_id, 'General contest', 'Choose one option.', 'single_choice', 1, 1);

  perform private.log_audit('election_created', 'election', v_election_id, '{}'::jsonb);

  return query
  select
    election.id,
    election.title,
    election.description,
    election.jurisdiction,
    election.status,
    election.starts_at,
    election.ends_at,
    election.registered_voters,
    election.results_visible,
    election.is_public,
    election.requires_mfa,
    1::integer,
    'unavailable'::text
  from public.elections election
  where election.id = v_election_id;
end;
$$;

create or replace function public.admin_update_election(p_election jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_election_id uuid := (p_election ->> 'id')::uuid;
begin
  if not (select private.has_any_role(array['administrator', 'election_manager'])) then
    raise exception 'Election management access is required.' using errcode = '42501';
  end if;

  update public.elections
  set
    title = coalesce(nullif(trim(p_election ->> 'title'), ''), title),
    description = coalesce(p_election ->> 'description', description),
    jurisdiction = coalesce(nullif(trim(p_election ->> 'jurisdiction'), ''), jurisdiction),
    status = coalesce(p_election ->> 'status', status),
    starts_at = coalesce((p_election ->> 'starts_at')::timestamptz, starts_at),
    ends_at = coalesce((p_election ->> 'ends_at')::timestamptz, ends_at),
    registered_voters = coalesce((p_election ->> 'registered_voters')::integer, registered_voters),
    is_public = coalesce((p_election ->> 'is_public')::boolean, is_public),
    results_visible = coalesce((p_election ->> 'results_visible')::boolean, results_visible),
    requires_mfa = coalesce((p_election ->> 'requires_mfa')::boolean, requires_mfa),
    published_at = case
      when coalesce((p_election ->> 'is_public')::boolean, is_public) and published_at is null then now()
      else published_at
    end,
    updated_at = now()
  where id = v_election_id;
  if not found then
    raise exception 'The election was not found.' using errcode = '22023';
  end if;

  if coalesce((p_election ->> 'results_visible')::boolean, false) then
    insert into public.notifications (
      user_id,
      notification_type,
      title,
      body,
      action_route,
      dedupe_key
    )
    select
      assignment.voter_id,
      'results_published',
      'Published election results',
      'Aggregate results are now available for one of your assigned elections.',
      '/results/' || v_election_id::text,
      'results-published:' || assignment.voter_id::text || ':' || v_election_id::text
    from public.ballot_assignments assignment
    join public.notification_preferences preference on preference.user_id = assignment.voter_id
    where assignment.election_id = v_election_id
      and preference.results_updates = true
    on conflict (dedupe_key) do nothing;
  end if;

  if coalesce(p_election ->> 'status', '') = 'live' then
    insert into public.notifications (
      user_id,
      notification_type,
      title,
      body,
      action_route,
      dedupe_key
    )
    select
      assignment.voter_id,
      'election_open',
      'Assigned ballot is open',
      'An authority-assigned ballot is now open. Review every contest before the deadline.',
      '/ballot/' || v_election_id::text,
      'election-open:' || assignment.voter_id::text || ':' || v_election_id::text
    from public.ballot_assignments assignment
    join public.notification_preferences preference on preference.user_id = assignment.voter_id
    where assignment.election_id = v_election_id
      and assignment.submission_state = 'eligible'
      and preference.election_reminders = true
    on conflict (dedupe_key) do nothing;
  end if;

  perform private.log_audit('election_updated', 'election', v_election_id, p_election - 'id');
end;
$$;

create or replace function public.admin_create_contest(p_contest jsonb)
returns table (
  id uuid,
  election_id uuid,
  title text,
  instructions text,
  contest_type text,
  seats integer,
  "position" integer,
  is_required boolean
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_contest_id uuid;
begin
  if not (select private.has_any_role(array['administrator', 'election_manager'])) then
    raise exception 'Election management access is required.' using errcode = '42501';
  end if;

  insert into public.contests (
    election_id,
    title,
    instructions,
    contest_type,
    seats,
    position,
    is_required
  )
  values (
    (p_contest ->> 'election_id')::uuid,
    nullif(trim(p_contest ->> 'title'), ''),
    coalesce(p_contest ->> 'instructions', 'Choose one option.'),
    coalesce(p_contest ->> 'contest_type', 'single_choice'),
    1,
    coalesce(
      nullif((p_contest ->> 'position')::integer, 0),
      (
        select coalesce(max(existing_contest.position), 0) + 1
        from public.contests existing_contest
        where existing_contest.election_id = (p_contest ->> 'election_id')::uuid
      )
    ),
    coalesce((p_contest ->> 'is_required')::boolean, true)
  )
  returning public.contests.id into v_contest_id;

  perform private.log_audit('contest_created', 'contest', v_contest_id, p_contest);

  return query
  select
    contest.id,
    contest.election_id,
    contest.title,
    contest.instructions,
    contest.contest_type,
    contest.seats,
    contest.position,
    contest.is_required
  from public.contests contest
  where contest.id = v_contest_id;
end;
$$;

create or replace function public.admin_create_candidate(p_candidate jsonb)
returns table (
  id uuid,
  election_id uuid,
  contest_id uuid,
  full_name text,
  party_name text,
  party_abbreviation text,
  manifesto text,
  accent_color text,
  ballot_position integer
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_candidate_id uuid;
begin
  if not (select private.has_any_role(array['administrator', 'election_manager'])) then
    raise exception 'Election management access is required.' using errcode = '42501';
  end if;

  if not exists (
    select 1
    from public.contests contest
    where contest.id = (p_candidate ->> 'contest_id')::uuid
      and contest.election_id = (p_candidate ->> 'election_id')::uuid
  ) then
    raise exception 'The selected contest does not belong to this election.' using errcode = '22023';
  end if;

  insert into public.candidates (
    election_id,
    contest_id,
    full_name,
    party_name,
    party_abbreviation,
    manifesto,
    accent_color,
    ballot_position
  )
  values (
    (p_candidate ->> 'election_id')::uuid,
    (p_candidate ->> 'contest_id')::uuid,
    nullif(trim(p_candidate ->> 'full_name'), ''),
    coalesce(p_candidate ->> 'party_name', ''),
    coalesce(p_candidate ->> 'party_abbreviation', ''),
    coalesce(p_candidate ->> 'manifesto', ''),
    coalesce(p_candidate ->> 'accent_color', '#1D5FD0'),
    coalesce(
      nullif((p_candidate ->> 'ballot_position')::integer, 0),
      (
        select coalesce(max(existing_candidate.ballot_position), 0) + 1
        from public.candidates existing_candidate
        where existing_candidate.contest_id = (p_candidate ->> 'contest_id')::uuid
      )
    )
  )
  returning public.candidates.id into v_candidate_id;

  perform private.log_audit('candidate_created', 'candidate', v_candidate_id, p_candidate);

  return query
  select
    candidate.id,
    candidate.election_id,
    candidate.contest_id,
    candidate.full_name,
    candidate.party_name,
    candidate.party_abbreviation,
    candidate.manifesto,
    candidate.accent_color,
    candidate.ballot_position
  from public.candidates candidate
  where candidate.id = v_candidate_id;
end;
$$;

revoke all on function public.get_my_roles() from public;
revoke all on function public.get_my_elections() from public;
revoke all on function public.get_my_ballot_status(uuid) from public;
revoke all on function public.submit_ballot(uuid, jsonb) from public;
revoke all on function public.get_my_notification_preferences() from public;
revoke all on function public.set_my_notification_preferences(jsonb) from public;
revoke all on function public.mark_notification_read(uuid) from public;
revoke all on function public.admin_dashboard_metrics() from public;
revoke all on function public.admin_recent_audit_events() from public;
revoke all on function public.admin_pending_voters() from public;
revoke all on function public.admin_set_voter_verification(uuid, text, text, text) from public;
revoke all on function public.admin_assign_voter_to_election(uuid, uuid) from public;
revoke all on function public.admin_create_election(jsonb) from public;
revoke all on function public.admin_update_election(jsonb) from public;
revoke all on function public.admin_create_contest(jsonb) from public;
revoke all on function public.admin_create_candidate(jsonb) from public;

grant execute on function public.get_my_roles() to authenticated;
grant execute on function public.get_my_elections() to authenticated;
grant execute on function public.get_my_ballot_status(uuid) to authenticated;
grant execute on function public.submit_ballot(uuid, jsonb) to authenticated;
grant execute on function public.get_my_notification_preferences() to authenticated;
grant execute on function public.set_my_notification_preferences(jsonb) to authenticated;
grant execute on function public.mark_notification_read(uuid) to authenticated;
grant execute on function public.admin_dashboard_metrics() to authenticated;
grant execute on function public.admin_recent_audit_events() to authenticated;
grant execute on function public.admin_pending_voters() to authenticated;
grant execute on function public.admin_set_voter_verification(uuid, text, text, text) to authenticated;
grant execute on function public.admin_assign_voter_to_election(uuid, uuid) to authenticated;
grant execute on function public.admin_create_election(jsonb) to authenticated;
grant execute on function public.admin_update_election(jsonb) to authenticated;
grant execute on function public.admin_create_contest(jsonb) to authenticated;
grant execute on function public.admin_create_candidate(jsonb) to authenticated;

-- Realtime is opt-in in Supabase. On hosted projects this adds the safe,
-- aggregate-only tables to replication. The exception block keeps the migration
-- compatible with local PostgreSQL environments without Supabase Realtime.
do $$
begin
  alter publication supabase_realtime add table public.result_snapshots;
  alter publication supabase_realtime add table public.notifications;
exception
  when duplicate_object or undefined_object or feature_not_supported then null;
end;
$$;

comment on table public.ballot_assignments is
  'Authority-managed eligibility and submission metadata. It intentionally stores no candidate choice.';
comment on table public.anonymous_votes is
  'Voter-free ballot choices written only by submit_ballot().';
comment on table public.audit_events is
  'Authority audit trail. Ballot events never include a candidate or contest selection.';
