# Security model and verification plan

## Scope and boundary

This repository implements a defensible **application foundation**: Supabase Auth, Row Level Security, authority roles, election-specific assignment, anonymous ballot rows, receipt-safe status recovery, and audit-aware operations.

It is **not a certification claim**. A binding election additionally requires an authority-approved voter-roll process, legal review, independent security assessment, privacy impact assessment, operational monitoring, recovery/support procedures, accessibility accommodations, and jurisdiction-specific election certification.

## Data separation

| Store | Contains | Does not contain |
| --- | --- | --- |
| `profiles` | User-facing display/verification metadata | Passwords, candidate choices |
| `ballot_assignments` | Voter-to-election eligibility, submitted state, receipt code | Candidate or contest selection |
| `anonymous_votes` | Election, contest, candidate, cast time | Voter id, assignment id, receipt code |
| `result_snapshots` | Aggregate candidate totals | Any voter identity or ballot row |
| `notifications` | Receipt-safe authority messages | Candidate/contest choices |
| `audit_events` | Operational event type/target/metadata | Candidate selection data |

The `submit_ballot` transaction sees both the authenticated user and the selected choices briefly in order to enforce eligibility and atomically write data. It stores them in separate tables without a database foreign key between an anonymous vote and a voter assignment. This improves application-level separation, but it does not replace an independently reviewed cryptographic secret-ballot protocol if one is required by the jurisdiction.

Ballot choices are deliberately **not persisted on-device** for offline replay. If connectivity is uncertain after submission, the voter reopens the ballot and uses `get_my_ballot_status` to retrieve a receipt-safe server answer.

## Enforcement sequence

`public.submit_ballot(p_election_id, p_choices)` is the only enabled client submission path. It checks, in one database transaction:

1. `auth.uid()` is present.
2. The election is live and inside the server-clock window.
3. AAL2/MFA is present when the election requires it.
4. The profile is authority-verified.
5. A matching `ballot_assignments` row is eligible and not already submitted.
6. Every contest explicitly configured as required has exactly one choice; optional public-election contests may be intentionally left blank as an undervote.
7. Every supplied candidate belongs to the supplied election and contest.
8. Anonymous vote rows are inserted only for supplied selections.
9. The assignment changes to `submitted`, a receipt is generated, and a receipt-safe audit/notification event is recorded.

A database transaction rolls all of that back if any step fails.

## RLS and privileges

- RLS is enabled on all public tables.
- Voters can read only their profile and notifications.
- Raw assignments, `anonymous_votes`, legacy `votes`, receipts, roles, and audit data have no general client read/write access.
- Public election/candidate/result reads are governed by publication/result policies.
- `get_my_elections`, `get_my_ballot_status`, and preference RPCs return only the caller’s safe metadata.
- Authority operations are protected by `private.has_role` / `private.has_any_role` checks using `auth.uid()`.
- Security-definer functions fix `search_path = ''` and schema-qualify relations.
- The legacy `cast_vote` function is revoked from authenticated users; all new ballots use `submit_ballot`.

## SQL inspection checks

```sql
-- RLS must be enabled on all sensitive tables.
select relname, relrowsecurity
from pg_class
join pg_namespace on pg_namespace.oid = pg_class.relnamespace
where nspname = 'public'
  and relname in (
    'profiles', 'user_roles', 'ballot_assignments', 'anonymous_votes',
    'result_snapshots', 'notifications', 'audit_events'
  );

-- App roles must not have direct raw-ballot privileges.
select grantee, table_name, privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and table_name in ('anonymous_votes', 'ballot_assignments', 'votes', 'vote_receipts')
order by table_name, grantee, privilege_type;

-- A future anonymous vote table must have no identity linkage columns.
select column_name
from information_schema.columns
where table_schema = 'public' and table_name = 'anonymous_votes'
order by ordinal_position;

-- Verify public RPC grants deliberately.
select routine_name, grantee, privilege_type
from information_schema.routine_privileges
where routine_schema = 'public'
  and routine_name in (
    'submit_ballot', 'get_my_elections', 'get_my_ballot_status',
    'admin_set_voter_verification', 'admin_assign_voter_to_election'
  )
order by routine_name, grantee;
```

## Test matrix

Automate these against a local/staging Supabase project:

| Actor | Expected outcome |
| --- | --- |
| Anonymous visitor | Cannot submit, see assignments, profiles, raw ballots, or notifications. |
| Unverified authenticated user | Cannot submit, even if assigned. |
| Verified but unassigned user | Cannot submit or discover another user’s assigned ballot. |
| Verified assigned AAL1 user | Rejected when `requires_mfa = true`. |
| Verified assigned AAL2 user | Can submit exactly one reviewed ballot, including lawful optional-contest undervotes. |
| Same voter after submit | Receives only submitted status/receipt; a second submission is rejected. |
| Candidate from wrong contest/election | Rejected. |
| Verifier | Can change verification/assignment but cannot self-grant administrator role. |
| Auditor | Can read audit events but cannot alter elections or ballots. |
| Result consumer | Sees released aggregates only; no assignment/voter/candidate linkage. |

## Operational controls outside code

- Bootstrap authority roles only from a protected environment.
- Keep service-role secrets in Supabase Edge Functions or an approved server, never the React Native client or Expo public environment.
- Require independent review before enabling official voting.
- Define retention/deletion policy for profiles, assignments, audit events, notifications, and backups.
- Monitor failed auth/MFA/RPC attempts, authority changes, and suspicious assignment patterns.
- Rehearse lost-response, deadline, outage, rollback, and support escalation scenarios.
