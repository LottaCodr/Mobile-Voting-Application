# CivicVote — mobile electoral voting experience

A research-led, privacy-conscious React Native / Expo voter portal with a Supabase backend foundation. The application opens in a clearly labelled fictional **PRODUCT PREVIEW** when public Supabase configuration is absent.

> CivicVote is not certified for binding public elections. A production deployment requires jurisdiction approval, independent security/privacy/accessibility review, operational controls, realistic usability testing, and election-system certification.

## What is implemented

### Expert voter experience

- Calm election-readiness dashboard with deadline, assignment, verification, security, and draft status
- Pre-ballot orientation that explains scope, time, privacy, review, and submission
- Linear one-contest-at-a-time ballot with explicit progress and no gesture-only controls
- Neutral, equal candidate/option presentation with progressively disclosed details
- Intentional undervotes (“leave this contest blank”) with a visible review warning
- Full-ballot review, direct contest editing, acknowledgement, and separate final-cast confirmation
- Choice-free submission receipt and safe receipt sharing
- Completed-election aggregate results only; no open-election candidate totals
- Receipt-safe updates, accessible support, and explicit preview/certification boundaries

### Accessibility and responsive UI

- Standard, large, and extra-large application text
- Stronger-contrast borders and reduced-motion preferences persisted locally
- Semantic tabs, headings, progress bars, radio controls, checkbox state, busy state, and live feedback
- Large primary touch targets and visible keyboard/screen-reader-friendly actions
- Compact bottom navigation on phones and a navigation rail on wide screens
- Focused ballot mode that removes unrelated navigation
- Montserrat type system and responsive scrolling layouts

### Security foundation

- Optional Supabase client using only public project values and secure session persistence
- Server-owned `submit_ballot()` transaction for authenticated identity, verified profile, assigned eligibility, election window, MFA policy, configured contest rules, candidate membership, and duplicate prevention
- RLS with no client read/write access to raw ballots or assignments
- Separate assignment/receipt metadata and voter-free `anonymous_votes`
- No ballot choice in notifications, audit events, or receipts
- No on-device ballot-choice persistence or optimistic official results

## Research

The interface is based on a comparative review of:

- Center for Civic Design / Anywhere Ballot
- EAC VVSG 2.0 and 2026 Test Assertions v1.4
- NIST remote-voting, ballot-review, accessibility, and E2E-verifiability research
- ElectionGuard
- Helios
- Estonian i-voting / IVXV
- Simply Voting and ElectionBuddy
- Voatz and independent security analyses

Read the full synthesis, product decisions, rejected patterns, source list, and validation plan in [docs/MOBILE_ELECTORAL_VOTING_RESEARCH.md](docs/MOBILE_ELECTORAL_VOTING_RESEARCH.md).

## Stack

| Package | Version |
| --- | --- |
| Expo SDK | 57 |
| React Native | 0.86 |
| React | 19.2 |
| Expo Router | 57 |
| TypeScript | 6.0 |
| Supabase JS | 2.x |

Node.js **22.13 or newer** is required by Expo SDK 57 / React Native 0.86.

## Run

```bash
npm ci
npm start
# or: npm run android | npm run ios | npm run web
# first run after a CLI/SDK change: npm run start:clear
```

Use the project-local start script rather than a globally installed Expo CLI. Full device steps are in [docs/RUNNING_ON_ANDROID.md](docs/RUNNING_ON_ANDROID.md).

## Connect Supabase

```bash
cp .env.example .env
# Set only EXPO_PUBLIC_SUPABASE_URL and EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY
npm start -- --clear
```

Never place a Supabase `service_role` key in `.env`, source code, an Expo build, or a mobile client. The database RPC remains authoritative for ballot submission.

The redesigned preview uses fictional fixtures for the voter feed. With Supabase configured, the cast action calls the real `submit_ballot` RPC using fixture UUIDs from `supabase/seed.sql`. Production should next replace the fixture feed with `get_my_elections()`, contest/candidate queries, and `get_my_ballot_status()` while preserving the same UI state machine.

## Checks

```bash
npm run typecheck
npm run lint
npm run doctor
npx expo export --platform all
```

## Documentation

- [Mobile electoral voting research](docs/MOBILE_ELECTORAL_VOTING_RESEARCH.md)
- [UX review](docs/UX_REVIEW.md)
- [Security model](docs/SECURITY_MODEL.md)
- [Feature implementation](docs/FEATURE_IMPLEMENTATION.md)
- [State management](docs/STATE_MANAGEMENT.md)
- [Operations runbook](docs/OPERATIONS_RUNBOOK.md)
- [Supabase migrations](supabase/migrations)
