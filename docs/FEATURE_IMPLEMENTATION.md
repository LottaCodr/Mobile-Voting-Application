# Feature implementation matrix

This matrix distinguishes the working React Native product preview and Supabase foundation from the election-authority work still required for official use.

## Implemented in this repository

| Capability | Implementation |
| --- | --- |
| Research-led voter journey | Readiness dashboard → pre-ballot orientation → one contest per step → full review → separate cast confirmation → choice-free receipt. |
| Responsive React Native UI | Expo SDK 57, TypeScript, Expo Router, mobile bottom navigation, wide-screen navigation rail, focused ballot layout, and safe-area handling. |
| Accessible interaction | Semantic roles/states, labelled icon controls, large touch targets, screen-reader progress, visible selected states, text scale preference, stronger contrast preference, reduced motion, and no gesture-only ballot controls. |
| Neutral ballot presentation | Candidates/options have equal card dimensions, typography, initials, radio state, details control, and authority-defined ordering; no portrait or party-logo salience. |
| Multi-contest ballot | Ordered contests, one choice per contest, explicit intentional undervote, in-memory draft progress, direct edit from review, and one full-ballot confirmation. |
| Privacy-conscious draft | Draft selections are never persisted to AsyncStorage and are cleared after confirmed submission. Preferences, not choices, are persisted. |
| Supabase submission | `submit_ballot()` remains the only client submission route. The UI waits for its response and does not optimistically claim success. |
| Eligibility enforcement | The RPC checks identity, election window, profile verification, ballot assignment, MFA policy, candidate membership, required-contest rules where configured, and duplicate submission in one transaction. |
| Intentional undervote | Public-election fixtures set contests optional and the ballot lets a voter explicitly leave a contest blank. Authorities can opt a contest into mandatory response only when governing rules permit it. |
| Receipt-safe recovery | Receipt UI and `get_my_ballot_status()` contain assignment/submission state, timestamp, and receipt only — never a candidate or contest selection. |
| Choice separation | `anonymous_votes` has election/contest/candidate/time but no voter, assignment, or receipt linkage. Assignment metadata stores submission status and receipt. |
| Publication-gated results | Open-election totals remain hidden. The preview shows only completed, authority-published aggregate results. |
| Receipt-safe updates | Election, verification, security, and result notices never reveal candidate selections. |
| User safeguards | Product-preview labelling, help path, privacy explanations, error state, lost-response-safe wording, and explicit certification boundary. |
| Quality checks | Strict TypeScript, Expo ESLint, Expo Doctor, and Expo multi-platform export commands. |

## Backend capabilities present but not yet wired to the preview UI

The Supabase schema includes authority roles, voter verification queues, assignment administration, election/contest/candidate creation, result publication controls, notification preferences, audit events, and a deadline-reminder Edge Function. The redesigned voter UI intentionally does not expose an administrator workspace inside the same focused experience.

A production implementation should add a separate role-gated authority application or route group rather than mixing privileged controls into the voter ballot.

## Required authority configuration

1. **Administrator bootstrap** — add the first trusted account from a protected environment.
2. **Identity review** — define the authoritative voter-roll and evidence process; never permit client self-verification.
3. **Ballot assignment** — assign only legally eligible voters to the correct ballot style.
4. **Contest policy** — keep public contests optional where undervotes are lawful; explicitly require a response only for election types whose governing rules allow it.
5. **MFA and recovery** — determine authenticator support, fallback, lost-device, and assisted recovery processes.
6. **Publication policy** — decide when results may be released and whether interim turnout (not candidate totals) is lawful.
7. **Email delivery** — configure Edge Function secrets, a verified sender, scheduling, rate limits, and failure handling.
8. **Deep links and releases** — register production schemes, signing keys, store identities, update policy, and approved distribution.
9. **Real translated ballots** — supply authority-approved text and audio for every required language; do not machine-translate official ballot content in the client.

## Important non-code requirements

No repository can unilaterally deliver:

- election-law compliance and certification;
- malware-safe voter-owned devices or coercion-free remote environments;
- independent penetration, privacy, accessibility, and cryptographic review;
- software independence or a voter-verifiable paper audit trail;
- a jurisdiction-approved E2E-verifiable protocol and verifier ecosystem;
- verified voter-roll governance and identity assurance;
- accessible support, recovery, complaint, and dispute-resolution processes;
- independent audit, monitoring, backup/restore, recount, and incident response.

See [MOBILE_ELECTORAL_VOTING_RESEARCH.md](MOBILE_ELECTORAL_VOTING_RESEARCH.md) and [SECURITY_MODEL.md](SECURITY_MODEL.md).
