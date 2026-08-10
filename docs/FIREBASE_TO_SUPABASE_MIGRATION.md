# Firebase → Supabase migration runbook

The codebase no longer includes Firebase dependencies, configuration files, or the unused Express mock API. This document is a **data migration plan**, not an instruction to copy an unreviewed election dataset into production.

## Do not migrate these fields

The prior application attempted to write a `password` field into Firestore voter records. Do **not** export, transform, or import it. Supabase Auth owns password hashes and its client never receives one.

Also do not blindly carry forward a historical record that links a named voter to a candidate. That may violate ballot-secrecy requirements. Obtain legal and security review before migrating any historical ballot data.

## Target mapping

| Legacy area | Supabase target | Migration rule |
| --- | --- | --- |
| Firebase Auth account | `auth.users` | Create/invite the user through a protected admin process; issue a password-reset or account-activation flow. Password hashes do not move between providers. |
| Firestore `voters` name/email | `public.profiles.display_name` + `auth.users.email` | Normalize names; use the `auth.users.id` as `profiles.id`. |
| Firestore voter ID / phone | Authority-controlled verification system | Do not treat a client-entered value as verified. Keep sensitive identity evidence in a protected process outside the public API. |
| Candidate / election metadata | `public.elections`, `public.contests`, `public.candidates` | Validate dates, jurisdiction, contest/candidate relation, ballot position, MFA policy, assignment policy, and publication flags before import. |
| Voter eligibility | `public.profiles` + `public.ballot_assignments` | Verification and election assignment are separate authority actions. Never infer an assignment from a client field. |
| Historical count | Separate audited archive or aggregate publication | Never import voter-linked rows into legacy `public.votes` or future `public.anonymous_votes` without a reviewed secret-ballot design. Use an independently approved archive/aggregate publication path. |

## Suggested staged procedure

1. **Freeze legacy writes** and take an immutable, access-controlled backup. Preserve a chain of custody for any official data.
2. **Rotate the Firebase API credentials** that were committed to the original project and remove the old app registration once the replacement is verified.
3. **Provision Supabase** and apply this repository's migration in a non-production project first:

   ```bash
   supabase db reset
   ```

4. **Export only approved metadata** (elections and candidates). Validate UUID mapping, ballot positions, duplicate names, time zones, and all public copy in a review environment.
5. **Establish identity verification outside the client.** Create/activate Supabase Auth users in a protected admin process, then let that process set `profiles.verification_status = 'verified'` only after eligibility review.
6. **Run RLS/RPC tests** from [`SECURITY_MODEL.md`](SECURITY_MODEL.md), including duplicate-vote and cross-election candidate checks.
7. **Run a parallel, non-binding pilot** with fictional or explicitly approved data. Check accessibility with screen readers, large type, keyboard navigation, intermittent connectivity, and support workflows.
8. **Cut over only after approval.** Disable legacy Firebase writes, preserve required audit material under the authority's retention policy, and monitor Supabase auth/RPC activity.

## What the Flutter app needs after cutover

The app needs only these public build-time values:

```bash
--dart-define=SUPABASE_URL=https://your-project.supabase.co
--dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

A `SUPABASE_SERVICE_ROLE_KEY` belongs only in a protected authority-controlled environment (for example a carefully audited admin service). It must never be put in a mobile app, browser build, repository, or CI log.
