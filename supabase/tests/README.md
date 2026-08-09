# Supabase test matrix

The CI workflow starts a local Supabase project and runs `supabase db reset` as a migration/seed smoke test. Add pgTAP coverage here before each authority deployment.

Minimum test identities:

- anonymous visitor;
- authenticated but unverified voter;
- verified but unassigned voter;
- verified/assigned AAL1 voter;
- verified/assigned AAL2 voter;
- verifier;
- election manager;
- auditor;
- administrator.

Minimum assertions:

1. Direct reads/writes of `anonymous_votes`, legacy `votes`, receipts, and assignments fail for client roles.
2. An unverified or unassigned voter cannot call `submit_ballot`.
3. An AAL1 session cannot submit an MFA-required election.
4. A complete AAL2 ballot inserts one anonymous row per selected contest and updates only assignment state/receipt.
5. Duplicate submission and duplicate contest choices fail.
6. `get_my_ballot_status` returns no candidate or contest selection.
7. `election_results` and `result_snapshots` expose only released aggregate rows.
8. A verifier cannot grant administrator role; an auditor cannot update an election.
9. Notification records sent after a ballot submission contain no candidate/contest choice.

The repository was additionally smoke-tested during development with an isolated Postgres-compatible PGlite harness covering migration/seed execution, assignment scoping, AAL1/AAL2 handling, multi-contest submission, duplicate rejection, anonymous vote columns, receipt-safe status, snapshots, notifications, and authority RPCs. That harness is not part of the production trust boundary; repeat these checks with Supabase local/pgTAP before release.
