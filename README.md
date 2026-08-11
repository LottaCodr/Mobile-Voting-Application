# CivicVote — React Native

A privacy-first React Native / Expo voter portal with a Supabase backend foundation. The app opens in a clearly labelled fictional **PRODUCT PREVIEW** when no public Supabase configuration is present. It is not certified for binding public elections.

## Current stack

| Package | Version |
| --- | --- |
| Expo SDK | 57 |
| React Native | 0.86 |
| React | 19.2 |
| Expo Router | 57 |
| TypeScript | 6.0 |
| ESLint | 9 (`eslint-config-expo` 57) |
| Supabase JS | 2.x |

Node.js **22.13 or newer** is required by Expo SDK 57 / React Native 0.86.

## What this app is

A TypeScript React Native application (previously Flutter):

- **Expo + React Native** UI, with mobile-first safe-area layout and accessible tab controls
- Full fictional demo flow: dashboard, multi-contest ballot, candidate search/platform details, review acknowledgement, receipt-safe submission view, results, updates, and profile preferences
- Optional Supabase JS client using secure persisted session storage; no service-role key is ever used in the client
- The existing Supabase migrations, Edge Function, and security documentation remain the backend source of truth

## Run

```bash
npm install
npm start
# or: npm run android | npm run ios | npm run web
```

Use Expo Go for device testing or an Android/iOS simulator. The web target is useful for UI review, but a native target should be included in accessibility and release testing.

## Connect Supabase

```bash
cp .env.example .env
# Set only EXPO_PUBLIC_SUPABASE_URL and EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY
npm start -- --clear
```

Never place a Supabase `service_role` key in `.env`, source code, or an Expo build. The client adapter calls the existing `submit_ballot` RPC, which must remain responsible for identity, assignment, MFA, election-window, candidate, and duplicate-submission checks.

## Checks

```bash
npm run typecheck   # tsc --noEmit
npm run lint        # eslint
npm run doctor      # expo-doctor: dependency/config validation
npx expo export --platform all   # verify web, iOS and Android bundles build
```

## Backend and operational documentation

- [Security model](docs/SECURITY_MODEL.md)
- [Operations runbook](docs/OPERATIONS_RUNBOOK.md)
- [Feature implementation](docs/FEATURE_IMPLEMENTATION.md)
- [Supabase migrations](supabase/migrations)

> **Safety notice:** Do not use this project for a binding election without independent security review, legal/privacy assessment, accessibility accommodation, operational readiness, and jurisdictional certification.
