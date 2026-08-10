-- CivicVote / Supabase migration
--
-- Security model:
--   * Clients can read public election/candidate/result data.
--   * Clients can read only their own voter profile.
--   * The votes table has no client SELECT or INSERT policy.
--   * Votes are submitted only through cast_vote(), a transaction that checks
--     authentication, verification, election timing, candidate membership, and
--     the one-vote-per-election constraint in the database.
--
-- Do not put a service-role key in the Flutter app. The app uses only a
-- Supabase publishable key and this migration's RLS/RPC boundary.

create schema if not exists private;
revoke all on schema private from public;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 120),
  voter_reference text,
  verification_status text not null default 'pending'
    check (verification_status in ('pending', 'verified', 'rejected')),
  jurisdiction text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.elections (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 180),
  description text not null default '',
  jurisdiction text not null,
  status text not null default 'upcoming'
    check (status in ('upcoming', 'live', 'completed')),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  registered_voters integer not null default 0 check (registered_voters >= 0),
  is_public boolean not null default false,
  results_visible boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint elections_valid_window check (ends_at > starts_at)
);

create table if not exists public.candidates (
  id uuid primary key default gen_random_uuid(),
  election_id uuid not null references public.elections(id) on delete cascade,
  full_name text not null check (char_length(full_name) between 1 and 160),
  party_name text not null default '',
  party_abbreviation text not null default '',
  manifesto text not null default '',
  accent_color text not null default '#1D5FD0'
    check (accent_color ~ '^#[0-9A-Fa-f]{6}$'),
  ballot_position integer not null check (ballot_position > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (election_id, ballot_position),
  unique (id, election_id)
);

-- This table is intentionally not exposed to the mobile client. Keeping the
-- voter id only here lets the database enforce a single ballot without letting
-- a user query a voter-to-candidate history.
create table if not exists public.votes (
  id uuid primary key default gen_random_uuid(),
  election_id uuid not null references public.elections(id) on delete restrict,
  candidate_id uuid not null,
  voter_id uuid not null references auth.users(id) on delete restrict,
  cast_at timestamptz not null default now(),
  unique (election_id, voter_id),
  foreign key (candidate_id, election_id)
    references public.candidates(id, election_id) on delete restrict
);

-- A receipt is not a ballot record. It is a short submission confirmation that
-- can be shown to the voter without revealing their selected candidate.
create table if not exists public.vote_receipts (
  id uuid primary key default gen_random_uuid(),
  vote_id uuid not null unique references public.votes(id) on delete cascade,
  receipt_code text not null unique,
  created_at timestamptz not null default now()
);

create index if not exists elections_public_start_idx
  on public.elections (is_public, starts_at);
create index if not exists candidates_election_position_idx
  on public.candidates (election_id, ballot_position);
create index if not exists votes_candidate_idx
  on public.votes (candidate_id);

-- Keep this trigger separate from the client sign-up flow. Passwords remain in
-- Supabase Auth; no password or authentication secret is ever copied here.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (
    id,
    display_name,
    voter_reference,
    verification_status
  )
  values (
    new.id,
    coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
      nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
      'Voter'
    ),
    null,
    'pending'
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Every table in the public API has RLS explicitly enabled. A table with no
-- policy remains inaccessible to app clients even if a table is exposed.
alter table public.profiles enable row level security;
alter table public.elections enable row level security;
alter table public.candidates enable row level security;
alter table public.votes enable row level security;
alter table public.vote_receipts enable row level security;

revoke all on table public.profiles from anon, authenticated;
revoke all on table public.elections from anon, authenticated;
revoke all on table public.candidates from anon, authenticated;
revoke all on table public.votes from anon, authenticated;
revoke all on table public.vote_receipts from anon, authenticated;

grant select on table public.profiles to authenticated;
grant select on table public.elections to anon, authenticated;
grant select on table public.candidates to anon, authenticated;

create policy "voters can read their own profile"
on public.profiles
for select
to authenticated
using ((select auth.uid()) = id);

create policy "public can read published elections"
on public.elections
for select
to anon, authenticated
using (is_public = true);

create policy "public can read candidates on published elections"
on public.candidates
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.elections election
    where election.id = candidates.election_id
      and election.is_public = true
  )
);

-- This deliberately aggregate-only view is the sole public read path for
-- counts. PostgreSQL views created by the migration owner can read the hidden
-- vote table, but the view selects no voter id, vote id, timestamp, or
-- voter/candidate mapping.
create or replace view public.election_results
with (security_barrier = true)
as
with candidate_counts as (
  select
    candidate.election_id,
    candidate.id as candidate_id,
    candidate.full_name,
    candidate.party_name,
    candidate.party_abbreviation,
    candidate.accent_color,
    count(vote.id)::integer as votes
  from public.candidates candidate
  join public.elections election on election.id = candidate.election_id
  left join public.votes vote on vote.candidate_id = candidate.id
  where election.is_public = true
    and election.results_visible = true
  group by
    candidate.election_id,
    candidate.id,
    candidate.full_name,
    candidate.party_name,
    candidate.party_abbreviation,
    candidate.accent_color
)
select
  election_id,
  candidate_id,
  full_name,
  party_name,
  party_abbreviation,
  accent_color,
  votes,
  coalesce(sum(votes) over (partition by election_id), 0)::integer as total_votes,
  rank() over (partition by election_id order by votes desc, full_name asc)::integer as rank
from candidate_counts;

revoke all on table public.election_results from anon, authenticated;
grant select on table public.election_results to anon, authenticated;

-- `security definer` is required because clients have no write access to votes.
-- The function fixes search_path and fully qualifies every relation to avoid
-- search-path attacks. Only authenticated users may execute it.
create or replace function public.cast_vote(
  p_election_id uuid,
  p_candidate_id uuid
)
returns table (receipt_code text, cast_at timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_voter_id uuid := (select auth.uid());
  v_vote_id uuid;
  v_receipt_code text;
  v_cast_at timestamptz := now();
begin
  if v_voter_id is null then
    raise exception 'You must be signed in to submit a ballot.' using errcode = '28000';
  end if;

  perform 1
  from public.profiles profile
  where profile.id = v_voter_id
    and profile.verification_status = 'verified';
  if not found then
    raise exception 'Your voter profile is not verified.' using errcode = '42501';
  end if;

  -- A shared row lock keeps the election state stable through this transaction
  -- without serialising all voters behind an exclusive election-row lock.
  perform 1
  from public.elections election
  where election.id = p_election_id
    and election.status = 'live'
    and election.starts_at <= v_cast_at
    and election.ends_at > v_cast_at
  for share;
  if not found then
    raise exception 'This election is not open for voting.' using errcode = '22023';
  end if;

  if not exists (
    select 1
    from public.candidates candidate
    where candidate.id = p_candidate_id
      and candidate.election_id = p_election_id
  ) then
    raise exception 'That candidate is not on this election ballot.' using errcode = '22023';
  end if;

  insert into public.votes (election_id, candidate_id, voter_id, cast_at)
  values (p_election_id, p_candidate_id, v_voter_id, v_cast_at)
  on conflict (election_id, voter_id) do nothing
  returning id into v_vote_id;

  if v_vote_id is null then
    raise exception 'A ballot has already been cast for this election.' using errcode = '23505';
  end if;

  v_receipt_code := upper(
    substring(replace(gen_random_uuid()::text, '-', '') from 1 for 12)
  );

  insert into public.vote_receipts (vote_id, receipt_code)
  values (v_vote_id, v_receipt_code);

  return query select v_receipt_code, v_cast_at;
end;
$$;

revoke all on function public.cast_vote(uuid, uuid) from public;
grant execute on function public.cast_vote(uuid, uuid) to authenticated;

comment on column public.profiles.voter_reference is
  'Masked display reference only. Do not store a raw government identity number here.';
comment on table public.votes is
  'Private ballot storage. No app client table access; use cast_vote RPC only.';
comment on view public.election_results is
  'Public aggregate counts only. It intentionally excludes all voter and ballot identifiers.';
