# Feature implementation matrix

This document records the implemented product capabilities and the operational capabilities that still require an election authority to configure or approve. It is intentionally explicit about the boundary between code and election governance.

## Implemented in this repository

| Capability | Implementation |
| --- | --- |
| Reactive state management | Riverpod 3 `NotifierProvider`, `FutureProvider`, `StreamProvider`, provider invalidation, immutable domain models, and testable repository injection. |
| Secure sign-in | Supabase email/password sign-up, confirmation-aware sign-in, password recovery, auth-state handling with stream error handling, and no password storage in profile tables. |
| Assigned ballots | `ballot_assignments` binds an eligible voter to a particular election. `get_my_elections()` returns only that voter’s authority-assigned ballot feed. |
| Multi-contest ballots | `contests`, contest-specific candidates, a Riverpod ballot draft, progress feedback, one choice per required contest, and a single full-ballot confirmation flow. |
| Eligibility enforcement | `submit_ballot()` checks authenticated identity, verified profile, eligible assignment, election time/status, all required contests, candidate membership, and duplicate submission in one transaction. |
| MFA-aware voting | Election-level `requires_mfa`, server-side AAL2 check, TOTP authenticator setup/verification interface, QR code setup, and session assurance status. |
| Receipt-safe recovery | `get_my_ballot_status()` returns assignment/submission state, timestamp, and receipt code only. It never returns a choice. This handles uncertain network outcomes safely. |
| Privacy-improved storage | New `anonymous_votes` has no voter id, assignment id, or receipt linkage. Assignment metadata stores only submitted/not-submitted and the receipt. |
| Results | Aggregate-only snapshots, contest-level ranking, publication gate, StreamProvider-based live result updates when Supabase Realtime is enabled, and manual refresh fallback. |
| Administration | Role-aware authority workspace: pending verification queue, voter-to-election assignment, election creation/status/publication/MFA/result controls, contest creation, candidate creation, and recent audit activity. |
| Audit | `audit_events` records authority actions and ballot submission events without candidate/contest selections. Auditor/admin-only retrieval is exposed through a safe RPC. |
| Notifications | User preferences, private in-app notification feed, receipt-safe verification/submission notices, and a server-side Supabase Edge Function for deadline emails. |
| Accessibility | Semantic labels, 48 px controls, high-contrast status content, text-scale-safe scrolling layouts, keyboard-friendly Material controls, visible loading/error/empty states, and accessible candidate/receipt feedback. |
| Delivery quality | Flutter widget/unit tests, a Supabase reset smoke-test plan, secret-scan configuration, and a ready-to-enable GitHub Actions workflow template. |

## Required authority configuration

These features are implemented as configuration points but cannot be safely guessed by the app:

1. **First administrator bootstrap** – add the first trusted account to `public.user_roles` using a protected SQL session or an authority-owned server process.
2. **Identity review process** – use the authority workspace or an audited server workflow to set `verification_status`; do not self-verify from the client.
3. **Ballot assignment policy** – assign only voters legally eligible for each election. Verification alone does not create an assignment.
4. **MFA policy** – turn on `requires_mfa` for elections where a second factor is required. Ensure the authority supports authenticators and recovery procedures.
5. **Publication policy** – decide whether each election is public, when results are visible, whether live aggregates are lawful, and when an election may change status.
6. **Email delivery** – configure the Edge Function secrets and a verified Resend sender, then schedule the function. See [`OPERATIONS_RUNBOOK.md`](OPERATIONS_RUNBOOK.md).
7. **Mobile deep links** – register production iOS/Android URL schemes and Supabase redirect URLs before enabling password recovery.
8. **Release signing** – replace `com.example` application identifiers, configure Android/iOS signing, and distribute through the authority’s approved channels.

## Important non-code requirements

No software repository can implement these unilaterally:

- election-law compliance and certification;
- independent penetration/security review;
- privacy impact assessment and retention policy;
- verified voter-roll source and identity assurance policy;
- accessible support, recovery, and dispute-resolution processes;
- independent audit, monitoring, backup/restore, and incident response;
- a jurisdiction-approved cryptographic ballot-secrecy protocol if the simple server-side separation model is insufficient.

Do not represent the demo data or this implementation as an official election until those requirements are completed.
