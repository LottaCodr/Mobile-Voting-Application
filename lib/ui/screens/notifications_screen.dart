import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    return Scaffold(
      body: PageFrame(
        child: notifications.when(
          loading: () => const LoadingState(label: 'Loading updates'),
          error: (_, __) => InlineError(
            message: 'Updates are unavailable right now. Pull to refresh or try again.',
            onRetry: () => ref.invalidate(notificationsProvider),
          ),
          data: (items) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: <Widget>[
                const SizedBox(height: 8),
                const SectionHeading(
                  title: 'Updates',
                  subtitle: 'Election reminders, verification updates, and receipt-safe notices.',
                ),
                const SizedBox(height: 18),
                if (items.isEmpty)
                  const EmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: 'You are all caught up',
                    description:
                        'New authority updates will appear here. Notifications never reveal ballot selections.',
                  )
                else
                  ...items.map(
                    (notification) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _NotificationCard(notification: notification),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRead = notification.isRead;
    final color = _colorFor(notification.type);
    return Card(
      color: isRead ? null : AppColors.bluePale,
      child: InkWell(
        onTap: isRead
            ? null
            : () async {
                try {
                  await ref.read(votingRepositoryProvider).markNotificationRead(notification.id);
                  ref.invalidate(notificationsProvider);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('The update could not be marked as read.')),
                    );
                  }
                }
              },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(_iconFor(notification.type), color: color),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              color: AppColors.navy,
                              fontWeight: isRead ? FontWeight.w700 : FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!isRead)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.circle, size: 9, color: AppColors.blue),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification.body,
                      style: const TextStyle(color: AppColors.inkMuted, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatDateTime(notification.createdAt),
                      style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _colorFor(String type) => switch (type) {
    'verification_update' => AppColors.teal,
    'ballot_submitted' => AppColors.teal,
    'election_open' || 'election_reminder' => AppColors.blueDark,
    'results_published' => const Color(0xFF7C3AED),
    _ => AppColors.inkMuted,
  };

  IconData _iconFor(String type) => switch (type) {
    'verification_update' => Icons.verified_user_outlined,
    'ballot_submitted' => Icons.receipt_long_outlined,
    'election_open' || 'election_reminder' => Icons.event_available_outlined,
    'results_published' => Icons.bar_chart_rounded,
    _ => Icons.info_outline_rounded,
  };
}
