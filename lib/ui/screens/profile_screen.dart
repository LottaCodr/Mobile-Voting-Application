import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../data/auth_gateway.dart';
import '../../data/voting_repository.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'mfa_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.onOpenAdmin});

  final VoidCallback? onOpenAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final preferences = ref.watch(notificationPreferencesProvider);
    final user = session.user;
    final profile = session.profile;
    final displayName = profile?.displayName ?? user?.displayName ?? 'Voter';
    final verification = profile?.verificationStatus ?? VerificationStatus.pending;

    return Scaffold(
      body: PageFrame(
        child: ListView(
          children: <Widget>[
            const SizedBox(height: 8),
            Text(
              'Profile & security',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Manage the safeguards that protect access to your assigned ballots.',
              style: TextStyle(color: AppColors.inkMuted, height: 1.45),
            ),
            const SizedBox(height: 22),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: <Widget>[
                    InitialAvatar(
                      initials: _initials(displayName),
                      color: AppColors.blue,
                      size: 72,
                      semanticLabel: '$displayName profile',
                    ),
                    const SizedBox(height: 14),
                    Text(
                      displayName,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      user?.email ?? 'Signed-in voter',
                      style: const TextStyle(color: AppColors.inkMuted),
                    ),
                    const SizedBox(height: 18),
                    _VerificationPanel(
                      status: verification,
                      voterReference: profile?.voterReference,
                      jurisdiction: profile?.jurisdiction,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            _MfaCard(
              status: session.mfaStatus,
              isDemo: session.isDemo,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => const MfaScreen())),
            ),
            const SizedBox(height: 28),
            const SectionHeading(
              title: 'Updates and accessibility',
              subtitle:
                  'Choose how CivicVote communicates, while keeping ballot selections private.',
            ),
            const SizedBox(height: 14),
            preferences.when(
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (_, __) => InlineError(
                message: 'Notification preferences are unavailable right now.',
                onRetry: () => ref.invalidate(notificationPreferencesProvider),
              ),
              data: (value) => Card(
                child: Column(
                  children: <Widget>[
                    _PreferenceSwitch(
                      icon: Icons.event_available_outlined,
                      title: 'Election reminders',
                      subtitle: 'Opening and deadline reminders for assigned ballots.',
                      value: value.electionReminders,
                      onChanged: (enabled) => _savePreferences(
                        context,
                        ref,
                        value.copyWith(electionReminders: enabled),
                      ),
                    ),
                    const Divider(indent: 70),
                    _PreferenceSwitch(
                      icon: Icons.verified_user_outlined,
                      title: 'Verification updates',
                      subtitle: 'Status changes from the election authority.',
                      value: value.verificationUpdates,
                      onChanged: (enabled) => _savePreferences(
                        context,
                        ref,
                        value.copyWith(verificationUpdates: enabled),
                      ),
                    ),
                    const Divider(indent: 70),
                    _PreferenceSwitch(
                      icon: Icons.bar_chart_outlined,
                      title: 'Results updates',
                      subtitle: 'Authority-published aggregate result notices.',
                      value: value.resultsUpdates,
                      onChanged: (enabled) =>
                          _savePreferences(context, ref, value.copyWith(resultsUpdates: enabled)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            const SectionHeading(
              title: 'Account safeguards',
              subtitle: 'Your profile never displays a record of candidate selections.',
            ),
            const SizedBox(height: 14),
            Card(
              child: Column(
                children: <Widget>[
                  _ProfileAction(
                    icon: Icons.shield_outlined,
                    title: 'How ballot privacy works',
                    subtitle: 'See what a receipt proves and what it never reveals.',
                    onTap: () => _showPrivacySheet(context),
                  ),
                  const Divider(indent: 70),
                  _ProfileAction(
                    icon: Icons.refresh_rounded,
                    title: 'Refresh security status',
                    subtitle: 'Check verification, role, and multi-factor status again.',
                    onTap: () => unawaited(ref.read(sessionProvider.notifier).refreshProfile()),
                  ),
                  if (onOpenAdmin != null) ...<Widget>[
                    const Divider(indent: 70),
                    _ProfileAction(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Authority workspace',
                      subtitle:
                          'Verification queue, assignments, publication, and audit-aware tools.',
                      onTap: onOpenAdmin!,
                    ),
                  ],
                  const Divider(indent: 70),
                  _ProfileAction(
                    icon: Icons.help_outline_rounded,
                    title: 'Need help?',
                    subtitle:
                        'Contact the election authority for identity or eligibility questions.',
                    onTap: () => _showHelpSheet(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            if (session.isDemo) const DemoBanner(),
            if (session.isDemo) const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => unawaited(_confirmSignOut(context, ref)),
              icon: const Icon(Icons.logout_rounded),
              label: Text(session.isDemo ? 'Leave demo' : 'Sign out'),
            ),
            const SizedBox(height: 18),
            const Text(
              'CivicVote does not store or show a voter-to-candidate history in this profile.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkMuted, fontSize: 12, height: 1.45),
            ),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }

  Future<void> _savePreferences(
    BuildContext context,
    WidgetRef ref,
    NotificationPreferences preferences,
  ) async {
    try {
      await ref.read(votingRepositoryProvider).saveNotificationPreferences(preferences);
      ref.invalidate(notificationPreferencesProvider);
    } on RepositoryFailure catch (error) {
      if (context.mounted) _message(context, error.message);
    }
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final session = ref.read(sessionProvider);
    final signOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(session.isDemo ? 'Leave demo?' : 'Sign out?'),
        content: Text(
          session.isDemo
              ? 'Your local demo state will be cleared.'
              : 'You will need to sign in again to access your voter portal.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (signOut != true) return;
    try {
      await ref.read(sessionProvider.notifier).signOut();
    } on AuthFailure catch (error) {
      if (context.mounted) _message(context, error.message);
    }
  }

  void _showPrivacySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) => const _InfoSheet(
        icon: Icons.shield_outlined,
        title: 'Ballot privacy',
        body:
            'CivicVote stores authority assignment and submission status separately from future anonymous ballot rows. Your receipt proves submission but never contains a candidate or contest choice.',
      ),
    );
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) => const _InfoSheet(
        icon: Icons.support_agent_rounded,
        title: 'Need help?',
        body:
            'For identity, assignment, accessibility accommodation, or election-rule questions, contact the authority responsible for your jurisdiction. Do not send passwords, authenticator codes, or full identity documents through support chat.',
      ),
    );
  }

  String _initials(String name) {
    final words = name.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

class _MfaCard extends StatelessWidget {
  const _MfaCard({required this.status, required this.isDemo, required this.onTap});

  final MfaStatus? status;
  final bool isDemo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final elevated = status?.isElevated ?? false;
    final color = elevated ? AppColors.teal : AppColors.gold;
    final background = elevated ? AppColors.tealPale : AppColors.goldPale;
    return Card(
      child: InkWell(
        onTap: isDemo ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  elevated ? Icons.verified_user_rounded : Icons.security_rounded,
                  color: color,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      elevated ? 'Multi-factor verification active' : 'Strengthen sign-in security',
                      style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isDemo
                          ? 'Demo mode simulates an elevated verification state.'
                          : elevated
                          ? 'Your current session has a verified second factor.'
                          : 'Some authority-assigned elections can require an authenticator code before submission.',
                      style: const TextStyle(color: AppColors.inkMuted, height: 1.4),
                    ),
                  ],
                ),
              ),
              if (!isDemo) Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerificationPanel extends StatelessWidget {
  const _VerificationPanel({
    required this.status,
    required this.voterReference,
    required this.jurisdiction,
  });

  final VerificationStatus status;
  final String? voterReference;
  final String? jurisdiction;

  @override
  Widget build(BuildContext context) {
    final verified = status == VerificationStatus.verified;
    final color = verified
        ? AppColors.teal
        : status == VerificationStatus.rejected
        ? AppColors.red
        : AppColors.gold;
    final background = verified
        ? AppColors.tealPale
        : status == VerificationStatus.rejected
        ? AppColors.redPale
        : AppColors.goldPale;
    final icon = verified
        ? Icons.verified_rounded
        : status == VerificationStatus.rejected
        ? Icons.error_outline_rounded
        : Icons.pending_outlined;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  status.label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  jurisdiction == null
                      ? 'Your jurisdiction will appear after an authority reviews your profile.'
                      : jurisdiction!,
                  style: const TextStyle(color: AppColors.navy, height: 1.35),
                ),
                if (voterReference != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    'Reference: $voterReference',
                    style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceSwitch extends StatelessWidget {
  const _PreferenceSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      secondary: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.bluePale,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.blueDark, size: 21),
      ),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.inkMuted, fontSize: 13, height: 1.35),
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.bluePale,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.blueDark, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.inkMuted, fontSize: 13, height: 1.35),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoSheet extends StatelessWidget {
  const _InfoSheet({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.bluePale,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.blueDark),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(body, style: const TextStyle(color: AppColors.inkMuted, height: 1.55)),
          const SizedBox(height: 22),
          FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }
}
