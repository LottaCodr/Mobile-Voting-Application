import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../domain/models.dart';

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 28),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 36.0 : 48.0;
    return Semantics(
      label: 'CivicVote',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(compact ? 11 : 15),
              boxShadow: const [
                BoxShadow(color: Color(0x291D5FD0), blurRadius: 16, offset: Offset(0, 6)),
              ],
            ),
            child: Icon(Icons.how_to_vote_rounded, color: Colors.white, size: compact ? 21 : 28),
          ),
          SizedBox(width: compact ? 9 : 12),
          Text(
            'CivicVote',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: compact ? 20 : 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted, height: 1.45),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final ElectionStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = switch (status) {
      ElectionStatus.live => (AppColors.tealPale, AppColors.teal, Icons.circle),
      ElectionStatus.upcoming => (AppColors.bluePale, AppColors.blueDark, Icons.schedule_rounded),
      ElectionStatus.completed => (
        const Color(0xFFF0F2F5),
        AppColors.inkMuted,
        Icons.check_circle_rounded,
      ),
      ElectionStatus.unknown => (AppColors.goldPale, AppColors.gold, Icons.info_outline_rounded),
    };
    return Semantics(
      label: 'Election status: ${status.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: foreground, size: status == ElectionStatus.live ? 9 : 15),
            const SizedBox(width: 6),
            Text(
              status.label,
              style: TextStyle(color: foreground, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Demo mode. Nothing you do here is an official vote.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.goldPale,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF4D68A)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.science_outlined, color: AppColors.gold),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Demo mode — the candidates and ballots are fictional. No official vote is being cast.',
                style: TextStyle(color: AppColors.navy, height: 1.4, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InitialAvatar extends StatelessWidget {
  const InitialAvatar({
    super.key,
    required this.initials,
    required this.color,
    this.size = 50,
    this.semanticLabel,
  });

  final String initials;
  final Color color;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        initials,
        style: TextStyle(
          color: readableOn(color),
          fontWeight: FontWeight.w800,
          fontSize: size * 0.34,
        ),
      ),
    );
    return semanticLabel == null
        ? avatar
        : Semantics(label: semanticLabel, image: true, child: avatar);
  }
}

class ElectionListCard extends StatelessWidget {
  const ElectionListCard({
    super.key,
    required this.election,
    required this.onTap,
    this.actionLabel = 'View ballot',
  });

  final Election election;
  final VoidCallback onTap;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final dateText = election.status == ElectionStatus.completed
        ? 'Closed ${formatDate(election.endsAt)}'
        : election.status == ElectionStatus.live
        ? 'Closes ${formatDateTime(election.endsAt)}'
        : 'Opens ${formatDateTime(election.startsAt)}';

    return Card(
      child: Semantics(
        button: true,
        label: '${election.title}, ${election.status.label}. $actionLabel',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        election.jurisdiction,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.inkMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    StatusPill(status: election.status),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  election.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  dateText,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted, height: 1.4),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      election.status == ElectionStatus.live
                          ? Icons.how_to_vote_outlined
                          : Icons.arrow_forward_rounded,
                      color: AppColors.blueDark,
                      size: 19,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      actionLabel,
                      style: const TextStyle(
                        color: AppColors.blueDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InlineError extends StatelessWidget {
  const InlineError({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.redPale,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF3B7B2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: AppColors.red),
              SizedBox(width: 8),
              Text('Something needs attention', style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: AppColors.navy, height: 1.4)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(color: AppColors.bluePale, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.blueDark, size: 32),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkMuted, height: 1.45),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.label = 'Loading election information…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: label,
        liveRegion: true,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 3)),
            SizedBox(height: 14),
            Text('Loading…', style: TextStyle(color: AppColors.inkMuted)),
          ],
        ),
      ),
    );
  }
}
