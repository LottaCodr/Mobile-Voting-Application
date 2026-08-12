# State management architecture

CivicVote currently uses a small, explicit React state model for the voter-facing preview. Server authority remains in Supabase RPCs and Row Level Security.

## Client state boundaries

| State | Storage | Reason |
| --- | --- | --- |
| Selected navigation tab | React memory | Pure presentation state. |
| Ballot stage and current contest | React memory | Keeps the casting flow focused without creating a durable ballot trail. |
| In-progress ballot choices | React memory only | Never persisted to AsyncStorage; cleared after confirmed submission. |
| Review acknowledgement and final confirmation | React memory | Deliberate-action safeguards, not election records. |
| Receipt and submitted status | React memory in the preview | Production status must be refreshed from `get_my_ballot_status()` after restart or an uncertain response. |
| Read notification state | React memory in the preview | Production notification status belongs in the private server feed. |
| Text size, stronger contrast, reduced motion | AsyncStorage | Non-sensitive usability preferences that should survive restart. |
| Eligibility, submission state, results, profile verification | Supabase | Server-authoritative records protected by RLS/RPC. |

## Ballot state machine

```text
closed
  → intro
  → contest 1 … contest N
  → review
  → final confirmation
  → submitting
  → success
```

Recovery paths:

- Contest Back returns to the preceding contest or orientation.
- Save and close exits without submitting and keeps an in-memory draft for the current session.
- Review “Change” jumps directly to a contest.
- A contest can be explicitly marked with no selection (intentional undervote).
- A failed RPC returns to review with a visible error and never invents a receipt.
- A confirmed submission clears choices before displaying the choice-free receipt.

## Mutation pattern

1. The voter edits only local draft state.
2. The full reviewed choice array is supplied once to `submit_ballot()`.
3. Supabase validates identity, assignment, timing, MFA policy, candidate membership, configured required contests, and duplicate submission in one transaction.
4. The client waits for the authoritative result.
5. Success clears the draft and renders only receipt-safe metadata.
6. Failure keeps the review available and displays an understandable error.

The client never increments official result counts and never treats an optimistic local transition as a cast ballot.

## Production evolution

As server-backed screens are wired into the redesigned UI, use a query/cache layer or reducer-based domain store with these constraints:

- keep the ballot draft in memory and out of generic persistence middleware;
- isolate auth/profile, assigned elections, status, notifications, and published results;
- invalidate/refetch submission status after a mutation or uncertain network response;
- never cache raw anonymous votes on the client;
- keep privileged authority state in a separate role-gated application surface;
- test the ballot state machine independently of Supabase using injected repositories.
