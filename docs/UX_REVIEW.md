# UX and implementation review

## Current product direction

CivicVote is now a focused, research-led voter portal rather than a collection of generic election cards. The full research synthesis, comparison of leading systems, rejected patterns, and pre-pilot validation plan is in [MOBILE_ELECTORAL_VOTING_RESEARCH.md](MOBILE_ELECTORAL_VOTING_RESEARCH.md).

## Audit of the previous React Native preview

The previous preview established a useful safe demo boundary, but the voter journey was too compressed:

1. All contests appeared in one long page, increasing cognitive load and making progress hard to understand.
2. Candidate details used a minimal text sheet but the primary path lacked a pre-ballot orientation and direct edit/recovery model.
3. Submission was enabled only after every contest had a candidate, preventing an intentional undervote.
4. The review sheet did not make casting sufficiently distinct from editing, and it used a generic alert after submission.
5. Results for an open election were visible, which is inappropriate where an authority suppresses interim totals.
6. Accessibility was primarily static: there were semantic roles, but no user-controlled text sizing, higher contrast, or reduced motion.
7. Navigation did not adapt well beyond compact phones and the visual system did not communicate election seriousness consistently.
8. Documentation still described a removed Flutter/Riverpod implementation.

## Implemented UX decisions

### Election readiness before ballot entry

The home screen now explains the open election, deadline, contest count, private-ballot status, draft state, voter verification, assignment, and server safeguard status. A fictional product-preview notice remains visible.

### Linear, voter-controlled ballot

- A pre-ballot screen explains scope, expected time, review, privacy, and the difference between leaving and casting.
- One contest is shown at a time with visible progress and explicit Back, Next, Close, and “leave blank” controls.
- Candidate and referendum options have equal visual treatment and official ballot order.
- Candidate statements use progressive disclosure in a consistent details sheet.
- Draft selections remain in memory only and are not submitted when the voter leaves.

### Error prevention and recovery

- Intentional blank contests are supported and visibly confirmed.
- The review page shows every contest in one consistent list and links directly back to each contest.
- Blank contests get a clear warning without blocking a valid undervote.
- Casting requires review acknowledgement and a separate final confirmation dialog.
- When Supabase is configured, the UI waits for authoritative server confirmation and shows an error instead of optimistically succeeding.

### Privacy-safe completion

The success page does not display choices. It shows only election, status, timestamp, and receipt code; explains the limits of that receipt; allows safe sharing; and clears in-progress choices after confirmation.

### Results and communications

- Open-election candidate totals are not shown.
- The example results view is a completed, certified fictional election with aggregate counts and text equivalents for visual bars.
- In-app updates can confirm readiness, submission, and publication without repeating ballot selections.

### Accessibility and responsive behaviour

- User-controlled standard, large, and extra-large application type.
- Optional stronger borders and reduced motion.
- Semantic tab, radio, checkbox, progress, heading, button, selected, busy, and live-region states.
- Controls are 48 px or larger where they are primary interactions.
- No swipe-only or gesture-only ballot operation.
- Equal candidate presentation avoids image-quality and party-logo bias.
- Phones use bottom navigation; wide layouts use a persistent navigation rail; ballot flow removes unrelated navigation.
- Long content scrolls safely at larger text sizes.

## What remains outside UI implementation

A production election authority must still determine and validate:

- legally approved ballot language, order, write-in handling, contest rules, and translations;
- the identity proofing and voter-roll source;
- whether electronic ballot return is lawful;
- authentication assurance, account recovery, and coercion response;
- cryptographic protocol and voter-verifiable evidence;
- independent audit, dispute resolution, monitoring, backup, recount, and incident communication;
- accessibility accommodations and usability testing with representative voters;
- retention, deletion, privacy impact assessment, and data residency;
- jurisdiction-specific certification.

The UI must not be represented as an official voting system until those controls are implemented and independently reviewed.
