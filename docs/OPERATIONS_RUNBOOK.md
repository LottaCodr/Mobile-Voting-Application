# Production operations runbook

## 1. Environments

Create separate Supabase projects for development, staging, and production. Never point a debug/mobile build at production by default.

```bash
supabase db reset                       # local schema + fictional seed
supabase link --project-ref <staging>
supabase db push
```

Run Flutter with only public client configuration:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_... \
  --dart-define=PASSWORD_RESET_REDIRECT=io.civicvote.app://reset-callback/
```

Never put `SUPABASE_SERVICE_ROLE_KEY`, Resend credentials, database passwords, voter identity evidence, or authority signing credentials in Flutter, Git, or CI logs.

## 2. Bootstrap the first administrator

After a trusted staff member has created an account through Supabase Auth, run this only through a protected SQL/editor session:

```sql
insert into public.user_roles (user_id, role)
values ('<trusted-auth-user-uuid>', 'administrator');
```

The administrator can then grant roles through a controlled operational process. Keep role grants separately approved and audited.

Available authority roles:

- `administrator` — role bootstrap and full authority workspace;
- `verifier` — identity/eligibility review and ballot assignment;
- `election_manager` — election, contest, candidate, status, MFA, and result-release management;
- `auditor` — audit-event visibility only.

## 3. Verification and assignment workflow

1. Create or import a Supabase Auth account through an approved identity process.
2. Review identity/eligibility outside the mobile client.
3. Set profile status through the authority workspace or `admin_set_voter_verification`.
4. Assign the voter to each legally eligible election through `admin_assign_voter_to_election`.
5. Confirm `get_my_elections()` returns the right ballots for a test voter.
6. Never infer eligibility from a user-entered jurisdiction, phone number, or client field alone.

## 4. Ballot lifecycle

1. Create a draft election; it receives a default contest.
2. Add/validate all contests, candidates, ballot positions, copy, translations, and accessibility text.
3. Set `is_public = true` only after authority review.
4. Set `status = live` at the approved opening time.
5. Set `requires_mfa = true` if policy requires a second factor for submission.
6. At closing, set `status = completed`.
7. Set `results_visible = true` only after the approved publication process.

The authority workspace logs these operations, but a separate governance/audit process must approve them.

## 5. Notification Edge Function

Deploy the receipt-safe email/reminder worker:

```bash
supabase functions deploy dispatch-election-reminders --no-verify-jwt
supabase secrets set \
  CRON_SECRET='<long-random-value>' \
  RESEND_API_KEY='re_...' \
  NOTIFICATION_FROM_EMAIL='CivicVote <notices@example.org>'
```

Schedule it from the Supabase Dashboard or an authority-controlled scheduler at an appropriate interval. The scheduler must send:

```http
Authorization: Bearer <CRON_SECRET>
```

The function queues opening/deadline reminders for eligible, unsubmitted assignments and sends only safe text. It never accesses a candidate choice. Validate sender domain, unsubscribe/legal requirements, rate limits, and delivery monitoring before enabling email.

## 6. Realtime, monitoring, and incident response

The migration adds `result_snapshots` and `notifications` to `supabase_realtime` where the publication exists. Confirm replication in the Dashboard. If Realtime is unavailable, the Flutter UI continues to offer manual refresh.

Before launch, establish:

- database backup/restore exercises;
- Supabase auth, function, RPC, and database alerting;
- authority audit-log export/retention;
- auth rate limits, CAPTCHA/bot controls, SMTP limits, and WAF rules where appropriate;
- incident severity, escalation, communication, and election pause procedures;
- test accounts for a full dress rehearsal including poor connectivity and a lost-response submission recovery.

## 7. Verification checklist

Run in a non-production project before every release. After GitHub grants workflow-write access to the automation app, copy `docs/github-actions-quality.yml.example` to `.github/workflows/quality.yml` to automate the same checks:

```bash
flutter pub get
flutter analyze
flutter test
supabase db reset
```

Also test manually:

- an unverified user cannot submit;
- a verified but unassigned user cannot submit;
- an assigned user can submit each required contest once;
- an MFA-required election rejects AAL1 and accepts AAL2;
- a lost client response can be reconciled with `get_my_ballot_status`;
- results/notifications never reveal a candidate selection;
- a verifier cannot grant themselves administrator privileges;
- a voter cannot see another voter’s notifications, assignment, or receipt.
