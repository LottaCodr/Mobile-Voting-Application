-- Public-election ballots must allow a voter to intentionally leave a contest
-- blank (an undervote) and still cast the rest of the ballot. Authorities that
-- run an organizational election with mandatory responses may still opt a
-- contest into `is_required = true` explicitly.

begin;

alter table public.contests
  alter column is_required set default false;

-- Keep the fictional CivicVote fixtures aligned with the voter-facing preview.
update public.contests
set is_required = false,
    updated_at = now()
where id in (
  '40000000-0000-0000-0000-000000000001',
  '40000000-0000-0000-0000-000000000002',
  '40000000-0000-0000-0000-000000000003',
  '40000000-0000-0000-0000-000000000004'
);

comment on column public.contests.is_required is
  'False by default so public-election voters may cast an undervote. Set true only when the governing election rules explicitly require a response.';

commit;
