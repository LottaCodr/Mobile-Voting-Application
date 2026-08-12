# Mobile electoral voting research and product blueprint

**Research date:** 12 August 2026  
**Scope:** voter-facing mobile experience, ballot usability, accessibility, privacy, verifiability, and the security boundary around remote ballot submission.

## Executive conclusion

There is no single mobile voting product whose entire approach should be copied. The strongest product direction combines:

1. **The Center for Civic Design / Anywhere Ballot interaction model** for plain language, a linear reading order, immediate feedback, easy correction, and voter-controlled accessibility.
2. **VVSG 2.0 and EAC test assertions** for unbiased option presentation, independent review/casting, alternate interaction modes, representative usability testing, and plain-language records.
3. **ElectionGuard and Helios concepts** for a choice-free confirmation code, independent verification, public audit artifacts, and an explicit distinction between a receipt and proof of a selection.
4. **Estonia's operational lessons** for strong national identity, a separate verification channel, distributed opening keys, public procedures, and revoting as a coercion mitigation — while recognising that Estonia's digital identity and legal infrastructure cannot be reproduced by a mobile UI.
5. **Mature hosted-election products** such as Simply Voting and ElectionBuddy for assignment-based access, transactional duplicate prevention, scheduled windows, reminders, clear status recovery, configurable ballot types, and administrator audit workflows.
6. **Research and criticism of mobile return systems** for the negative lesson: a polished app, biometrics, blockchain, or encryption-at-rest does not solve malware on a voter's device, coercion, denial of service, insider risk, dispute resolution, or software independence.

The resulting CivicVote interface is deliberately calm and explicit rather than optimised for speed or conversion. It treats casting as a consequential action, keeps candidate presentation neutral, makes recovery visible, and never claims that this product preview is certified.

## Systems and standards reviewed

| System / source | Strong pattern | Limitation or warning | CivicVote decision |
| --- | --- | --- | --- |
| **Center for Civic Design — Anywhere Ballot** | Seven research-backed principles: linear flow, plain language, readable presentation, action prompts, immediate feedback, easy correction, and accessibility preferences. | Rich information placed directly in the voting path distracted some low-literacy voters. | One contest per step; concise instructions; optional details in a secondary sheet; persistent progress; direct edit links on review. |
| **EAC VVSG 2.0 + Test Assertions v1.4** | Independent verification and casting, equal presentation of choices, support for visual/audio/tactile modes, realistic testing, and plain-language human-readable records. | Conformance requires complete system testing and certification; UI alignment alone is not certification. | Equal-size candidate cards in official order, no portrait/party-logo advantage, text alternatives, large targets, explicit review and final cast. |
| **NIST remote-voting research** | Security, privacy, accessibility, and usability must be considered together; collect only necessary PII; design accessible authentication; test with assistive technology in realistic environments. | Personally owned devices can contain malware; remote environments cannot guarantee privacy or freedom from coercion. | No unnecessary identity collection in the ballot flow; no CAPTCHA; no claim that client-device risk is solved; visible support and product-boundary notices. |
| **ElectionGuard** | Confirmation code, cast-or-challenge workflow, encrypted election record, third-party verification, threshold guardians. | ElectionGuard is an SDK and process, not a badge a UI can claim. Effective E2E verification also requires published artifacts, independent verifiers, voter participation, and dispute handling. | Receipt language is conservative and choice-free. The UI says what a receipt confirms and does not imply E2E verification is present in the current Supabase model. |
| **Helios** | Open audit, ballot fingerprint, encrypted bulletin board, multiple trustees, independently reproducible tally. | Designed for low-coercion elections such as clubs and universities; remote high-stakes elections retain coercion and endpoint risks. | Separate participation status from selections; include a receipt-safe recovery pattern; do not present Helios-style assurance without the required cryptographic implementation. |
| **Estonian i-voting / IVXV** | National e-ID, digitally signed submission, encryption, a separate-device verification app, distributed opening key, public counting, and the ability to replace an electronic vote. | The system depends on national identity infrastructure, law, operational ceremonies, audits, and a separate channel. Estonia had not simply authorised generic smartphone voting; mobile distribution and independent verification introduce additional concerns. | Do not mimic national-election assurance with a phone biometric toggle. Record revoting and separate-device verification as future governance/architecture decisions, not superficial UI features. |
| **Simply Voting** | Transactional one-voter/one-ballot enforcement, assignment checks, anonymous results, immutable activity logging, TLS, encrypted storage, penetration testing, and independent audit access. | Vendor security controls do not eliminate remote-client or coercion risk. Receipt configurations must avoid revealing selections. | Server RPC owns eligibility, timing, validity, and duplicate enforcement; receipt contains no selections; aggregate results are publication-gated. |
| **ElectionBuddy** | Single-use access, reminders, test elections, configurable ballots, anonymous-vote modes, multi-channel notices, and approachable voter flows. | Configuration determines privacy and assurance; an easy workflow is not automatically suitable for public elections. | Clear election status, assigned ballots, reminders, preview labelling, and a short pre-ballot orientation. |
| **Voatz and security analyses** | Mobile-first identity flow, accessibility support, biometric/device integration, and receipt/paper-trail aspirations. | Public analyses identified serious endpoint, metadata, privacy, network, and administrative concerns; blockchain did not make the voter-to-chain path independently trustworthy. | Do not use “blockchain” as a trust message, do not collect location, do not expose a vote choice in a receipt, and do not claim device biometrics secure the ballot. |

## Research-to-interface decisions implemented

### 1. Calm election dashboard

The home screen prioritises one open election, its deadline, the number of contests, and readiness checks. Status is always expressed with text and iconography, never colour alone. Upcoming elections are visually secondary.

**Why:** election interfaces need to reduce uncertainty before asking for a consequential action. The voter should know that their identity is verified, the correct ballot is assigned, and no action has yet cast a vote.

### 2. Pre-ballot orientation

Before entering the ballot, the voter sees the scope, expected duration, deadline, privacy model, and the distinction between a draft and a submission.

**Why:** this creates a stable mental model without overloading each contest. It also provides a safe place for a “How voting works” explanation.

### 3. One contest at a time

The ballot uses a clear linear sequence with explicit Back, Next, Close, and progress controls. No hidden swipe gesture is required. A voter can save and leave without accidentally submitting.

**Why:** it supports a narrow field of view, low literacy, cognitive accessibility, screen readers, and smaller phones.

### 4. Neutral candidate and option presentation

Every candidate or referendum option uses the same dimensions, typography, initials treatment, radio control, and details affordance. No candidate photo, party logo, result, endorsement, or algorithmic ordering appears in the selection list.

**Why:** VVSG requires no discernible presentation bias. Unequal portrait quality and party artwork can create unintended salience.

### 5. Progressive disclosure for candidate information

Candidate statements and referendum effects are available in a bottom sheet using an identical template. The core ballot remains short.

**Why:** this balances informed voting with the Anywhere Ballot finding that rich information embedded in the primary path can distract and increase error.

### 6. Intentional undervote

A voter may explicitly leave a contest blank and continue. Review highlights the blank contest without blocking submission. The Supabase default is changed so public-election contests permit undervotes; an authority may explicitly require a response only when its governing rules allow that.

**Why:** public voting systems must not silently force a choice. An undervote is different from an accidental omission, so the UI makes the intent visible and recoverable.

### 7. Strong review, direct correction, and final confirmation

The review screen presents every contest in a consistent format, marks “No selection” plainly, and lets the voter jump directly to a contest and back. A review acknowledgement and a separate final confirmation distinguish editing from irreversible casting.

**Why:** studies show that merely displaying a review screen is not enough. Salient undervote notices and low-friction correction improve error detection.

### 8. Receipt-safe success and recovery

After server confirmation, CivicVote clears the in-progress choices and shows only election name, submission status, timestamp, and a receipt code. A dedicated explanation says the receipt confirms submission but cannot prove a choice.

**Why:** a receipt containing selections can enable coercion or vote selling. Status recovery is still essential when a network response is uncertain.

### 9. Publication-gated aggregate results

The open election does not expose live candidate totals. The results screen shows a completed, certified fictional election, an update time, totals, turnout, and aggregate bars with text equivalents.

**Why:** live candidate results can affect voter behaviour and may be prohibited. Result release is an election-authority decision.

### 10. Accessible preferences and support

The app includes standard/large/extra-large type, higher-contrast boundaries, reduced motion, semantic roles, screen-reader labels, 48+ pixel primary targets, no gesture-only controls, and a support path that explicitly cannot see ballot choices.

**Why:** accessibility must be intrinsic, not a separate ballot. Preferences affect the same interface every voter uses.

### 11. Responsive mobile and desktop navigation

Phones use a familiar five-item bottom bar. Wide screens use a persistent navigation rail while the focused ballot flow removes global navigation.

**Why:** the voter portal can be used on mobile web, tablets, or desktop without compromising the focused casting journey.

## Security and privacy conclusions

### Controls implemented in this repository

- Supabase Auth session support using a publishable client key only.
- Authority-assigned ballot retrieval and database-enforced eligibility.
- A single `submit_ballot` transaction for election window, profile verification, assignment, MFA policy, candidate membership, duplicate submission, anonymous choice writes, receipt generation, and audit event creation.
- RLS and revoked direct access to raw votes/assignments.
- Separate assignment/receipt status and anonymous choice tables.
- No ballot choice in notifications, audit events, or receipts.
- No on-device persistence of ballot selections for offline replay.
- Optional contest responses / intentional undervotes for the public-election fixture.

### Controls that are intentionally not claimed

The current Supabase separation model is **not** end-to-end verifiable cryptography, software independence, a voter-verifiable paper audit trail, coercion resistance, malware resistance, or public-election certification. It also does not implement ElectionGuard, Helios, mixnets, threshold decryption, a public bulletin board, independent verification applications, or a formal dispute-resolution protocol.

Those are architecture and governance programmes, not interface decorations.

## Product patterns explicitly rejected

- **A vote-choice receipt or downloadable “vote slip.”** It can undermine receipt-freeness.
- **Live candidate totals while voting is open.** They can bias participation and may be unlawful.
- **A generic blockchain trust claim.** A ledger does not secure the voter endpoint, identity path, app distribution, or administrator.
- **Forced candidate selection in a public contest.** Voters must be able to cast an undervote where election law permits.
- **Candidate photos or unequal party art in the selection control.** These can introduce visual bias.
- **Swipe-only navigation, hidden gestures, or tiny radio targets.** They exclude many voters.
- **Automatic submission after the last contest.** Casting must be a separate, explicit, irreversible action.
- **Optimistically showing success.** The UI waits for authoritative server confirmation when Supabase is configured.
- **Storing draft selections for later offline replay.** Privacy and duplicate-submission ambiguity outweigh convenience in this foundation.
- **Marketing “military-grade,” “unhackable,” or “100% secure.”** Such claims are not supportable.

## Validation plan before any official pilot

1. Conduct moderated end-to-end usability tests with a realistic 12+ contest ballot.
2. Include blind screen-reader users, low-vision users, voters with limited dexterity, voters with cognitive/attention disabilities, older voters, first-time voters, and primary speakers of every supported language.
3. Measure task completion, voting errors, successful correction, review-screen error detection, time on task, abandonment, confidence, and support requests.
4. Test text enlargement and system font scaling without clipping at narrow phone widths.
5. Test loss of connectivity before submission, during submission, and after the server commits but before the client receives the response.
6. Verify screen-reader order and announcements on current iOS VoiceOver and Android TalkBack.
7. Run independent application, database, infrastructure, cryptographic, privacy, and supply-chain reviews.
8. Define receipt complaint handling, election incident thresholds, outages, recount/audit evidence, retention, and public communications.
9. Obtain jurisdiction-specific legal review and voting-system certification.

## Primary and comparative sources

### Standards and public research

- U.S. Election Assistance Commission, **VVSG 2.0**: <https://www.eac.gov/sites/default/files/TestingCertification/Voluntary_Voting_System_Guidelines_Version_2_0.pdf>
- EAC, **VVSG 2.0 Test Assertions v1.4** (January 2026): <https://www.eac.gov/sites/default/files/2026-01/VVSG_2.0_Test_Assertions_v1.4.pdf>
- Center for Civic Design, **Anywhere Ballot: Making voting accessible**: <https://civicdesign.org/reports/anywhere-ballot-making-voting-accessible/>
- Center for Civic Design, **Designing an accessible ranked-choice ballot**: <https://civicdesign.org/reports/designing-an-accessible-rcv-ballot/>
- NIST, **Accessibility and Usability Considerations for Remote Voting Systems**: <https://www.nist.gov/system/files/documents/itl/vote/UA-Considerations-for-Remote-Voting-Systems-02142011-final.pdf>
- NIST, **Security Considerations for Remote Electronic UOCAVA Voting**: <https://tsapps.nist.gov/publication/get_pdf.cfm?pub_id=907707>
- NIST, **U.S. Election Expert Perspectives on End-to-End Verifiable Voting Systems**: <https://www.nist.gov/publications/us-election-expert-perspectives-end-end-verifiable-voting-systems>
- NIST / Center for Civic Design, **A Review of the Literature on Voter Verification and Ballot Review**: <https://civicdesign.org/wp-content/uploads/2026/03/NIST.GCR_.24-052-2.pdf>

### Systems

- ElectionGuard, **Creating a Verifiable Election**: <https://electionguard.vote/concepts/Verifiability/>
- ElectionGuard, **Official Specifications**: <https://electionguard.vote/spec/>
- Helios, **v4 Verification Specification**: <https://documentation.heliosvoting.org/verification-specs/helios-v4>
- Estonian State Electoral Office, **Introduction to i-voting**: <https://www.valimised.ee/en/internet-voting/more-about-i-voting/introduction-i-voting>
- Estonian State Electoral Office, **Reliability FAQ**: <https://www.valimised.ee/en/internet-voting/frequently-asked-questions/questions-about-reliability-i-voting>
- Simply Voting, **Security and Reliability**: <https://www.simplyvoting.com/security-reliability/>
- ElectionBuddy: <https://electionbuddy.com/>
- Verified Voting, **Voatz Mobile App overview and security concerns**: <https://verifiedvoting.org/election-system/voatz-mobile-app/>

## Interpretation note

“Best” is contextual. ElectionGuard is strongest as an open E2E-verifiability toolkit, Helios as a transparent low-coercion online election model, Estonia as a national operational system built on state digital identity, Anywhere Ballot as a voter-interface research foundation, and hosted products as operational workflow references. None alone resolves every requirement for binding mobile public elections.
