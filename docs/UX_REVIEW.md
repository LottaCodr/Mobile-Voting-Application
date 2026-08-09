# UX and implementation review

## Audit of the starting project

The original checkout had useful visual assets but was not safe or coherent enough to ship:

1. **Firebase was wired throughout the app**, even though authentication, Firestore records, generated Firebase options, and platform service files were incomplete/misaligned.
2. **Authentication was non-functional and unsafe.** The sign-in service passed the literal strings `email` and `password`, the sign-up form reused one controller for both password fields, and the app attempted to write a password into Firestore.
3. **Votes were only mutable client state.** Candidate counters were incremented in memory, so a refresh lost a vote and a client could alter results. There was no server-side one-vote guarantee.
4. **Navigation and feedback were fragmented.** Old splash/onboarding pages bypassed auth, errors silently returned, several controls had no action, and a stale counter widget test remained.
5. **The UI used hard-coded data, nested scroll views, inconsistent hierarchy, narrow fixed-height areas, and image-dependent controls.** Those choices made candidate review and large-text use unreliable.

## Research inputs

This rebuild follows the current primary documentation rather than treating a client app as a source of election truth:

- [Supabase Flutter quickstart](https://supabase.com/docs/guides/getting-started/quickstarts/flutter): initialize the Flutter client with a project URL and **publishable key**.
- [Supabase Flutter package documentation](https://pub.dev/packages/supabase_flutter): current `Supabase.initialize`, password auth, and auth-state APIs.
- [Supabase user-management guidance](https://supabase.com/docs/guides/auth/managing-user-data): model application profiles separately from `auth.users`, protect them with RLS, and create them through a trigger.
- [Supabase Row Level Security guidance](https://supabase.com/docs/guides/database/postgres/row-level-security): enable RLS, grant only required privileges, use `auth.uid()`, and keep policies explicit.
- [Supabase database-function guidance](https://supabase.com/docs/guides/database/functions): default to invoker security; when a definer function is necessary, set a fixed `search_path` and fully qualify relations.
- [Flutter accessibility guidance](https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility): support text scaling, semantic labels, 48×48 px Android touch targets, clear errors, and at least 4.5:1 contrast for small text.

## Applied UX decisions

### 1. Make election state obvious

- A single primary card tells the voter whether an election is open, upcoming, or completed and gives a relevant next action.
- Every election card repeats status in text and iconography; color is never the only signal.
- Results distinguish a live aggregate count from a final published result.

### 2. Make the ballot deliberate, not fast

- Candidate platform information is available before selection, including a bottom sheet for full text.
- Only one candidate can be selected and the active selection has a thick border, radio state, text label, and semantic selected state.
- The submit path is intentionally two-step: select → review → acknowledge → submit.
- The final receipt confirms *submission only*, not the candidate, which supports ballot privacy.

### 3. Design for recovery and trust

- Every data section has a loading, empty, and retry state.
- Account and voting errors are understandable messages rather than raw stack traces.
- The backend connection fails closed when configured but unavailable. A local demo is available only when no endpoint has been configured.
- The profile shows verification status before the voter reaches the irreversible action.

### 4. Accessibility and responsive behavior

- Material controls are given 48 px minimum actions; icons have tooltips and controls have text labels.
- Semantics are added to status, candidate choice, progress, profile avatar, and demo state.
- Cards, flexible columns, scroll views, and a max-width content frame avoid the fixed-height/nested-scroll failures in the prior UI.
- The app uses a bottom navigation bar on compact screens and an extended NavigationRail at desktop widths.
- The color system uses dark navy content on white/pale surfaces and never depends only on a color indicator.

## Implemented follow-on capabilities

The redesign now also includes a full multi-contest ballot journey, explicit authority-assigned eligibility, a safe submitted-ballot status, receipt-safe in-app updates, MFA setup/verification, a role-aware authority workspace, result publication controls, and provider-backed retry/loading/error states. The ballot progress indicator makes missing contests visible before confirmation, while the final review sheet lists every contest without storing a selection locally after submission.

## What still needs product-owner input

A production authority must determine the legal ballot language, identity proofing process, candidate imagery and accessibility text, electoral calendar, data retention period, support escalation route, and whether live results are allowed. Those choices cannot be safely inferred from a UI mockup.
