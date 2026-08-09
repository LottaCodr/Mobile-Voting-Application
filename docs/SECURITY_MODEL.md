# Security model and operational notes

## Scope

This document describes the implemented Supabase boundary. It does **not** claim that the repository is sufficient for a binding governmental election. A certified election requires far more than a mobile client and database schema: independent security assessment, threat modeling, cryptographic/audit requirements appropriate to the jurisdiction, identity assurance, operational controls, incident response, accessibility accommodations, and legal approval.

## Trust boundaries

| Component | Trusted for | Must not be trusted for |
| --- | --- | --- |
| Flutter client | Displaying public ballot data, collecting an explicit candidate choice, calling auth/RPC APIs | Counting votes, enforcing eligibility, preventing repeat votes, storing service secrets, or proving ballot secrecy by itself |
| Supabase Auth | Password lifecycle and authenticated user id | Election eligibility decision without a separate verification workflow |
| `profiles` | Voter verification state owned by the authority | Storing passwords or a ballot history |
| `cast_vote` PostgreSQL RPC | Atomic vote eligibility/window/candidate/duplicate checks | Administrator identity verification or full election certification |
| `votes` | Private one-vote enforcement and count source | Any client-readable personal voting history |
| `election_results` view | Published aggregate counts only | Voter identities, vote ids, timestamps, or candidate/voter linkage |

## Implemented controls

1. **No Firebase / no local vote counter.** The old mutable UI counter and Firestore writes are gone.
2. **No service-role key in Flutter.** The runtime accepts only `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` via Dart defines.
3. **RLS everywhere.** All public-schema tables in the migration explicitly enable RLS.
4. **Least privileges.** Clients can select public elections/candidates and their own profile only. They receive no `SELECT`, `INSERT`, `UPDATE`, or `DELETE` grant on `votes` or `vote_receipts`.
5. **Verification cannot be self-issued.** The app cannot update `verification_status`; an authority-controlled workflow must do so.
6. **Atomic submission.** `cast_vote` authenticates `auth.uid()`, checks verified profile, locks/validates the election window, validates candidate membership, and writes under a database uniqueness constraint in one transaction.
7. **Fixed search path.** The necessary `SECURITY DEFINER` RPC uses `set search_path = ''` and schema-qualified objects. It is revoked from `PUBLIC` and granted only to `authenticated`.
8. **Aggregate-only results.** The public view has no vote/voter identifier or timestamp and returns results only when `results_visible` is true.
9. **Fail closed.** If Dart defines name a backend but Supabase cannot start, the app shows a service failure rather than using a device-local voting fallback.

## Verifying the migration

Run these checks in an isolated local/project environment after applying the migration. Adapt role setup to your Supabase version.

```sql
-- Confirm RLS is enabled on all private/public API tables.
select relname, relrowsecurity
from pg_class
join pg_namespace on pg_namespace.oid = pg_class.relnamespace
where nspname = 'public'
  and relname in ('profiles', 'elections', 'candidates', 'votes', 'vote_receipts');

-- Confirm clients do not hold direct vote-table privileges.
select grantee, privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and table_name in ('votes', 'vote_receipts')
order by table_name, grantee, privilege_type;

-- Confirm the only callable vote-writing public routine is restricted.
select routine_schema, routine_name, grantee, privilege_type
from information_schema.routine_privileges
where routine_schema = 'public'
  and routine_name = 'cast_vote';

-- Inspect the result-view contract. It must contain no voter_id, vote id,
-- cast time, or raw ballot row.
select column_name
from information_schema.columns
where table_schema = 'public' and table_name = 'election_results'
order by ordinal_position;
```

For automated assurance, add pgTAP tests that impersonate `anon`, an unverified authenticated user, a verified user, and a second verified user. At minimum test that:

- anonymous users cannot invoke a vote;
- unverified users cannot invoke a vote;
- a verified user cannot cast twice in the same election;
- a candidate from another election is rejected;
- a closed/upcoming election is rejected;
- direct insert/select against `votes` fails for client roles;
- result rows do not expose ballot identifiers.

## Operational controls still required

- **Verification workflow:** set `profiles.verification_status = 'verified'` only in a protected authority process (for example an audited server-side workflow using a service role held outside the client). Do not let users upload or self-approve an ID without robust review.
- **Admin/RBAC:** add separate private/admin schemas and tightly reviewed role claims before building election-management UI. Never grant dashboard or service privileges to the app.
- **Audit and monitoring:** capture privileged changes, publication schedule changes, failed RPC patterns, and abnormal auth activity in an authority-controlled audit system.
- **Vote secrecy review:** a uniqueness record necessarily associates a user with an election in this simple architecture. Legal and cryptographic ballot-secrecy requirements may demand a stronger, independently reviewed protocol that splits eligibility from ballot storage.
- **Rate limits / abuse controls:** configure Supabase Auth limits, password policy, CAPTCHA or equivalent where appropriate, and network/WAF controls.
- **Backups and incident response:** encrypt backups, define access/retention policies, rehearse restore and incident procedures, and prevent operations staff from casually reading private data.
- **Certification:** obtain independent review and jurisdictional approval before representing any action as an official ballot.
