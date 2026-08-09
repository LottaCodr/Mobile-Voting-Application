import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/app_theme.dart';
import '../../domain/models.dart';
import '../../state/app_controller.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final user = controller.user;
    final profile = controller.profile;
    final displayName = profile?.displayName ?? user?.displayName ?? 'Voter';
    final initials = _initials(displayName);
    final verification = profile?.verificationStatus ?? VerificationStatus.pending;

    return Scaffold(
      body: PageFrame(
        child: ListView(
          children: [
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
              'Manage the information that helps protect your access to eligible ballots.',
              style: TextStyle(color: AppColors.inkMuted, height: 1.45),
            ),
            const SizedBox(height: 22),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    InitialAvatar(
                      initials: initials,
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
            const SizedBox(height: 28),
            const SectionHeading(
              title: 'Account safeguards',
              subtitle: 'Your ballot is never shown in this profile or your device history.',
            ),
            const SizedBox(height: 14),
            Card(
              child: Column(
                children: [
                  _ProfileAction(
                    icon: Icons.shield_outlined,
                    title: 'How ballot privacy works',
                    subtitle: 'Learn what is and is not saved after submission.',
                    onTap: () => _showPrivacySheet(context),
                  ),
                  const Divider(indent: 70),
                  _ProfileAction(
                    icon: Icons.refresh_rounded,
                    title: 'Refresh verification status',
                    subtitle: 'Check whether your eligibility profile has updated.',
                    onTap: controller.refreshProfile,
                  ),
                  const Divider(indent: 70),
                  _ProfileAction(
                    icon: Icons.help_outline_rounded,
                    title: 'Need help?',
                    subtitle:
                        'Contact your election authority for eligibility or identity questions.',
                    onTap: () => _showHelpSheet(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            if (controller.isDemo) const DemoBanner(),
            if (controller.isDemo) const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => _confirmSignOut(context, controller),
              icon: const Icon(Icons.logout_rounded),
              label: Text(controller.isDemo ? 'Leave demo' : 'Sign out'),
            ),
            const SizedBox(height: 18),
            const Text(
              'CivicVote does not use your profile to display a record of your candidate selections.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkMuted, fontSize: 12, height: 1.45),
            ),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final words = name.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  Future<void> _confirmSignOut(BuildContext context, AppController controller) async {
    final signOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(controller.isDemo ? 'Leave demo?' : 'Sign out?'),
        content: Text(
          controller.isDemo
              ? 'Your local demo state will be cleared.'
              : 'You will need to sign in again to access your voter portal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (signOut != true) return;
    try {
      await controller.signOut();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('We could not sign you out. Please try again.')),
        );
      }
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
            'The app receives an anonymous confirmation receipt after a successful submission. It does not query or show a voter-to-candidate history. Aggregate results are published separately.',
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
            'For identity, eligibility, accessibility accommodation, or election-rule questions, contact the election authority responsible for your jurisdiction. Do not send credentials through support channels.',
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
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  jurisdiction == null
                      ? 'Your jurisdiction will appear after your profile is reviewed.'
                      : jurisdiction!,
                  style: const TextStyle(color: AppColors.navy, height: 1.35),
                ),
                if (voterReference != null) ...[
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
            children: [
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
                  children: [
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
        children: [
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
