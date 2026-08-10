# State management architecture

CivicVote uses **Riverpod 3** with immutable state and repository injection. This replaces the earlier global `GetX`/`ChangeNotifier` pattern.

## Why Riverpod

The app has independently changing auth, security, ballot, result, notification, and administrative states. Riverpod is used because it provides:

- compile-safe dependency injection;
- asynchronous loading/error/data states without mutable UI controllers;
- provider invalidation after server mutations;
- `StreamProvider` support for Supabase Realtime feeds;
- predictable, immutable state transitions;
- provider overrides for widget/unit tests;
- no `BuildContext` dependency in domain/data logic.

## Provider map

| Provider | Responsibility |
| --- | --- |
| `appServicesProvider` | Single composition root for Supabase vs explicit demo mode. |
| `sessionProvider` | Auth listener, user/profile/roles/MFA status, sign in/out, demo entry, profile refresh. |
| `electionsProvider` | Authority-assigned election feed only. |
| `contestsProvider(electionId)` | Ordered contests for one election. |
| `candidatesProvider(electionId)` | Candidate/option data for an election. |
| `ballotStatusProvider(electionId)` | Privacy-safe assignment/submission/receipt status. |
| `ballotDraftProvider` | Immutable in-progress choices; one choice per contest and reset on election switch. |
| `resultsProvider` / `liveResultsProvider` | Manual result query plus safe aggregate Realtime snapshots. |
| `notificationsProvider` | User-private in-app notification stream. |
| `notificationPreferencesProvider` | Preference reads and invalidation after updates. |
| `adminMetricsProvider`, `managedElectionsProvider`, `pendingVotersProvider`, `auditEventsProvider` | Role-gated authority workspace state. |

## Mutation pattern

All mutations follow the same flow:

1. A widget calls a public notifier/repository method.
2. The server performs the authoritative operation through RLS/RPC.
3. The app invalidates only affected providers.
4. UI widgets rebuild from `AsyncValue` states with loading, error, and retry affordances.

Example after a ballot submission:

```dart
await ref.read(votingRepositoryProvider).submitBallot(...);
ref
  ..read(ballotDraftProvider.notifier).clear(electionId)
  ..invalidate(ballotStatusProvider(electionId))
  ..invalidate(electionsProvider)
  ..invalidate(resultsProvider(electionId));
```

The client never optimistically increments official vote counts or assumes a request succeeded. It refreshes the server-backed submission status and receipt after the mutation.

## Testability

`MyApp` accepts an optional `AppServices` instance, while Riverpod supports provider overrides. This makes it possible to test the demo/repository behavior and individual state providers without a live Supabase project.
