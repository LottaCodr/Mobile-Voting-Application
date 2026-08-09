# CivicVote

A privacy-first Flutter voter portal and Supabase backend foundation. It includes a clearly labelled fictional demo, multi-contest ballot UX, authority-assigned eligibility, MFA-aware submission, aggregate-only results, a role-aware authority workspace, notifications, audit controls, and Riverpod state management.

> **Important:** This is an implementation foundation, not a certified public-election system. Do not use it for a binding election until the authority has completed independent security review, legal/privacy assessment, operational readiness, accessibility accommodation, and jurisdictional certification.

## Included capabilities

| Area | Included behavior |
| --- | --- |
| State | Riverpod 3 providers/notifiers for auth, profile, MFA, ballot draft, async data, live result snapshots, notifications, administrative data. |
| Identity | Supabase Auth, email confirmation-aware sign-in, password recovery, authority-owned verification, and optional TOTP MFA. |
| Eligibility | Election-specific `ballot_assignments`; verification alone never grants a ballot. |
| Ballot | Multi-contest ballot, per-contest selection, search, platform sheets, progress feedback, full review, acknowledgement, and one atomic submission. |
| Privacy | Future `anonymous_votes` contain no voter or assignment id. Submission status/receipt is separate and never reveals a choice. |
| Results | Authority-controlled release, aggregate snapshots, contest-level ranking, manual refresh, and Supabase Realtime when enabled. |
| Authority workspace | Role-aware verification queue, ballot assignment, election/contest/candidate management, MFA/result/publication controls, and receipt-safe audit activity. |
| Notifications | User preferences, private in-app updates, and a server-side deadline-email Edge Function. |
| UX | Responsive mobile/desktop navigation, semantic controls, accessible layouts, retry/loading/empty states, and fictional demo mode. |

See [`docs/FEATURE_IMPLEMENTATION.md`](docs/FEATURE_IMPLEMENTATION.md) for the full matrix and the authority-owned configuration items.

## Requirements

- Flutter **3.29+** / Dart **3.7+**
- A Supabase project for authenticated mode
- [Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started) for local database work
- Docker for `supabase start`

## Run the fictional UI demo

```bash
flutter pub get
flutter run
```

With no Supabase Dart defines, the app opens in clearly labelled **PRODUCT PREVIEW** mode. Demo data is fictional and no action is an official vote.

## Connect a Supabase project

```bash
supabase start
supabase db reset

# For a linked hosted project
supabase link --project-ref <project-ref>
supabase db push
```

Run Flutter using public client configuration only:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_... \
  --dart-define=PASSWORD_RESET_REDIRECT=io.civicvote.app://reset-callback/
```

Never put a service-role key in Flutter. A configured backend fails closed rather than degrading to a local ballot.

## Database architecture

Migrations:

- [`20260809000000_secure_voting_schema.sql`](supabase/migrations/20260809000000_secure_voting_schema.sql) — profiles, baseline election data, RLS, initial migration path.
- [`20260809010000_production_ballots_admin_and_notifications.sql`](supabase/migrations/20260809010000_production_ballots_admin_and_notifications.sql) — authority roles, multi-contest ballots, assignments, anonymous ballot rows, MFA policy, result snapshots, notifications, audit events, and secure RPCs.

The production vote path is `submit_ballot(p_election_id, p_choices)`. It atomically verifies authenticated identity, AAL2 where required, profile status, election window, assignment, required contests, candidate membership, and one submission per assignment. It returns only a receipt code and timestamp.

Read [`docs/SECURITY_MODEL.md`](docs/SECURITY_MODEL.md) before applying this to an authority project.

## Authority setup

1. Create a trusted staff account through Supabase Auth.
2. Bootstrap it as `administrator` through a protected SQL environment.
3. Establish a reviewed verification workflow.
4. Verify voters and assign them to individual elections.
5. Create and review all election/contest/candidate data.
6. Decide MFA, publication, result-release, notification, retention, and support policy.

The exact commands and operating checklist are in [`docs/OPERATIONS_RUNBOOK.md`](docs/OPERATIONS_RUNBOOK.md).

## Notification worker

The Edge Function at [`supabase/functions/dispatch-election-reminders`](supabase/functions/dispatch-election-reminders/index.ts) queues deadline reminders and sends receipt-safe email through Resend. It requires server-side secrets and a protected scheduler; see the runbook. It never reads or sends a ballot choice.

## Quality checks

```bash
flutter pub get
flutter analyze
flutter test
supabase db reset
```

A GitHub Actions quality-workflow template is at [`docs/github-actions-quality.yml.example`](docs/github-actions-quality.yml.example). Add it to `.github/workflows/quality.yml` after the repository GitHub App has workflow-write permission. The old Firebase lockfile was intentionally removed; run `flutter pub get` to create the current lockfile.

## Documentation

- [`docs/FEATURE_IMPLEMENTATION.md`](docs/FEATURE_IMPLEMENTATION.md) — capability matrix and non-code limits
- [`docs/STATE_MANAGEMENT.md`](docs/STATE_MANAGEMENT.md) — Riverpod architecture
- [`docs/SECURITY_MODEL.md`](docs/SECURITY_MODEL.md) — data separation, RLS, RPC, and verification matrix
- [`docs/OPERATIONS_RUNBOOK.md`](docs/OPERATIONS_RUNBOOK.md) — authority/Edge Function/release operation steps
- [`docs/UX_REVIEW.md`](docs/UX_REVIEW.md) — audit, accessibility, and UX decisions
- [`docs/FIREBASE_TO_SUPABASE_MIGRATION.md`](docs/FIREBASE_TO_SUPABASE_MIGRATION.md) — legacy cutover plan
