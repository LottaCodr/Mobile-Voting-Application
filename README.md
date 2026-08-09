# CivicVote

A refreshed Flutter voter portal with an accessible ballot flow and a **Supabase-first backend**. The project ships with a clearly labelled fictional demo so the interface can be evaluated before a Supabase project is connected.

> **Important:** This repository is a product and integration foundation, not a certified public-election system. Do not use it for a binding election until an independent security review, threat model, privacy impact assessment, accessibility audit, legal review, and the relevant jurisdiction's certification process are complete.

## What changed

- Replaced Firebase Auth, Firestore, Firebase configuration files, and the unused Express mock server with `supabase_flutter`.
- Removed the unsafe client-side vote counter and password copying. Passwords now stay in Supabase Auth; the app never stores them in a profile table.
- Added a complete Supabase migration with RLS, a profile trigger, aggregate-only results, and a transactional `cast_vote` RPC.
- Rebuilt the interface around a clear journey: **dashboard → review ballot → explicit confirmation → privacy-preserving receipt**.
- Added responsive NavigationRail/NavigationBar layouts, loading/empty/error states, large touch targets, semantic labels, visible verification status, readable contrast, and text-scale-friendly layouts.

## Product experience

| Area | Included behavior |
| --- | --- |
| Home | Current election, status, deadlines, clear next action, and filterable election schedule. |
| Ballot | Searchable candidates, full platforms, one visible selection, review sheet, acknowledgement, and post-submit receipt. |
| Results | Aggregate-only candidate totals, rank, percentage, refresh control, and an explicit results-pending state. |
| Profile | Verification status, masked voter reference, privacy explanation, support guidance, and safe sign-out. |
| Demo | Fictional data and a persistent warning. A demo selection is never presented as an official vote. |

## Requirements

- Flutter **3.22+** / Dart **3.3+**
- A Supabase project for authenticated production mode
- [Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started) for local database development (recommended)

## Run the UI demo

No secrets are needed to explore the redesign:

```bash
flutter pub get
flutter run
```

Without Supabase build definitions, CivicVote intentionally starts at a **PRODUCT PREVIEW** screen. Choose **Explore demo ballot** to use fictional data.

## Connect Supabase

1. Create a Supabase project and enable Email authentication.
2. Install the CLI and apply the schema:

   ```bash
   supabase start                 # local development, optional
   supabase db reset              # applies migrations and supabase/seed.sql locally

   # Or for a linked hosted project:
   supabase link --project-ref <your-project-ref>
   supabase db push
   ```

3. Copy the **Project URL** and the **publishable key** from the project's Connect panel. A publishable key is intended for clients; **never use `service_role` in Flutter**.
4. Run with build-time values:

   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://your-project.supabase.co \
     --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_replace_me
   ```

With a configured endpoint, a bootstrap failure is deliberately fail-closed: the app will not silently fall back to a device-local ballot.

### Password reset deep link (optional)

For mobile password reset, configure an app URL scheme and add the exact redirect URL to **Supabase Auth → URL Configuration**, then pass it at build time:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_replace_me \
  --dart-define=PASSWORD_RESET_REDIRECT=io.civicvote.app://reset-callback/
```

The URL scheme must match the Android/iOS configuration of your own released app. See `supabase/.env.example`; it contains placeholders only.

## Backend security model

The implementation is in [`supabase/migrations/20260809000000_secure_voting_schema.sql`](supabase/migrations/20260809000000_secure_voting_schema.sql).

- `profiles` references `auth.users`; the signup trigger creates a **pending** profile.
- A voter can read only their own profile. There is no client policy to self-mark as verified.
- Elections and candidates are read-only to clients and must be marked public.
- `votes` and `vote_receipts` have **no client `SELECT` or `INSERT` policy**.
- `cast_vote(p_election_id, p_candidate_id)` runs in one database transaction, checks `auth.uid()`, verified status, live time window, candidate membership, and the unique `(election_id, voter_id)` constraint.
- The client receives only a receipt code and timestamp. It cannot query a voter-to-candidate history.
- `election_results` deliberately exposes aggregate counts only and only when `results_visible = true`.

Detailed assumptions, RLS verification queries, and operational limitations are in [`docs/SECURITY_MODEL.md`](docs/SECURITY_MODEL.md). For a safe staged data/account cutover from the previous Firebase build, use [`docs/FIREBASE_TO_SUPABASE_MIGRATION.md`](docs/FIREBASE_TO_SUPABASE_MIGRATION.md).

## Quality checks

```bash
flutter pub get
flutter analyze
flutter test
```

The repository's original Firebase lockfile has intentionally been removed. `flutter pub get` creates a new lockfile for the Supabase dependency graph in your environment.

## Research and design notes

[`docs/UX_REVIEW.md`](docs/UX_REVIEW.md) records the project audit, the applied UX/accessibility decisions, and the current official Flutter/Supabase references used for this rebuild.

## Suggested production checklist

- [ ] Replace the template Android/iOS/macOS bundle identifiers with IDs owned by the deploying authority.
- [ ] Configure auth confirmation, password policy, rate limits, and approved redirect URLs.
- [ ] Define an administrator-only identity verification workflow; only that workflow should set `profiles.verification_status = 'verified'`.
- [ ] Add database/RLS tests and load tests for the expected election size.
- [ ] Arrange independent penetration testing and database audit logging/monitoring.
- [ ] Establish retention, incident response, accessibility accommodation, auditability, and election-certification procedures with the authority responsible for the election.
- [ ] Replace fictional seed/demo records with independently verified ballot data.
