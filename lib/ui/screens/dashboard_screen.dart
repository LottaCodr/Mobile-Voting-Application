import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../domain/models.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onOpenBallot, required this.onOpenResults});

  final ValueChanged<String> onOpenBallot;
  final ValueChanged<String> onOpenResults;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<Election>> _elections;
  ElectionStatus? _filter;

  bool _loadedInitialData = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedInitialData) return;
    _loadedInitialData = true;
    _elections = AppScope.of(context).services.voting.loadElections();
  }

  Future<void> _reload() async {
    setState(() => _elections = AppScope.of(context).services.voting.loadElections());
    await _elections;
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final firstName = (controller.profile?.displayName ?? controller.user?.displayName ?? 'Voter')
        .split(RegExp(r'\s+'))
        .first;

    return Scaffold(
      body: PageFrame(
        child: FutureBuilder<List<Election>>(
          future: _elections,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LoadingState(label: 'Loading your election hub');
            }
            if (snapshot.hasError) {
              return InlineError(
                message: 'We could not load your elections. Check your connection and try again.',
                onRetry: _reload,
              );
            }
            final elections = snapshot.data ?? const <Election>[];
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good to see you, $firstName',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your election hub',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
                            ),
                          ],
                        ),
                      ),
                      _ProfileStatusBadge(profile: controller.profile),
                    ],
                  ),
                  const SizedBox(height: 22),
                  if (controller.isDemo) ...[const DemoBanner(), const SizedBox(height: 18)],
                  _PrimaryElectionCard(
                    election: _bestElection(elections),
                    onOpenBallot: widget.onOpenBallot,
                    onOpenResults: widget.onOpenResults,
                  ),
                  const SizedBox(height: 28),
                  const SectionHeading(
                    title: 'Voting with confidence',
                    subtitle: 'A simple, transparent path from ballot review to confirmation.',
                  ),
                  const SizedBox(height: 14),
                  const _ConfidenceSteps(),
                  const SizedBox(height: 28),
                  SectionHeading(
                    title: 'Your elections',
                    subtitle: elections.isEmpty
                        ? null
                        : '${elections.length} election${elections.length == 1 ? '' : 's'} available',
                    trailing: IconButton(
                      tooltip: 'Refresh elections',
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _FilterRow(
                    selected: _filter,
                    onSelected: (status) => setState(() => _filter = status),
                  ),
                  const SizedBox(height: 14),
                  if (elections.isEmpty)
                    const EmptyState(
                      icon: Icons.event_busy_outlined,
                      title: 'No elections are available yet',
                      description: 'When an eligible election is published, it will appear here.',
                    )
                  else
                    ..._filtered(elections).map(
                      (election) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ElectionListCard(
                          election: election,
                          actionLabel: election.status == ElectionStatus.completed
                              ? 'View results'
                              : election.status == ElectionStatus.live
                              ? 'Review ballot'
                              : 'View details',
                          onTap: () {
                            if (election.status == ElectionStatus.completed) {
                              widget.onOpenResults(election.id);
                            } else {
                              widget.onOpenBallot(election.id);
                            }
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Election? _bestElection(List<Election> elections) {
    for (final election in elections) {
      if (election.status == ElectionStatus.live) return election;
    }
    for (final election in elections) {
      if (election.status == ElectionStatus.upcoming) return election;
    }
    return elections.isEmpty ? null : elections.first;
  }

  List<Election> _filtered(List<Election> elections) {
    if (_filter == null) return elections;
    return elections.where((election) => election.status == _filter).toList();
  }
}

class _ProfileStatusBadge extends StatelessWidget {
  const _ProfileStatusBadge({required this.profile});

  final VoterProfile? profile;

  @override
  Widget build(BuildContext context) {
    final isVerified = profile?.isVerified ?? false;
    final color = isVerified ? AppColors.teal : AppColors.gold;
    final background = isVerified ? AppColors.tealPale : AppColors.goldPale;
    final label = isVerified ? 'Verified' : 'Check profile';
    return Semantics(
      label: profile?.verificationStatus.label ?? 'Profile status loading',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVerified ? Icons.verified_rounded : Icons.pending_outlined,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryElectionCard extends StatelessWidget {
  const _PrimaryElectionCard({
    required this.election,
    required this.onOpenBallot,
    required this.onOpenResults,
  });

  final Election? election;
  final ValueChanged<String> onOpenBallot;
  final ValueChanged<String> onOpenResults;

  @override
  Widget build(BuildContext context) {
    if (election == null) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.bluePale,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Text('Your next eligible election will appear here.'),
      );
    }

    final isLive = election!.status == ElectionStatus.live;
    final isCompleted = election!.status == ElectionStatus.completed;
    final action = isCompleted
        ? 'View published results'
        : isLive
        ? 'Review ballot'
        : 'See election details';
    final subtitle = isCompleted
        ? 'Results published'
        : isLive
        ? '${countdownLabel(election!.endsAt)} · voting is open'
        : 'Opens ${formatDateTime(election!.startsAt)}';

    return Semantics(
      container: true,
      label: '${election!.title}. $subtitle.',
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.blueDark, AppColors.blue],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Color(0x331D5FD0), blurRadius: 22, offset: Offset(0, 10)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.insights_rounded
                        : isLive
                        ? Icons.how_to_vote_rounded
                        : Icons.event_available_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  isCompleted
                      ? 'RESULTS AVAILABLE'
                      : isLive
                      ? 'OPEN NOW'
                      : 'COMING UP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              election!.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                height: 1.18,
              ),
            ),
            const SizedBox(height: 9),
            Text(subtitle, style: const TextStyle(color: Color(0xFFE2ECFF), height: 1.45)),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.blueDark,
                minimumSize: const Size(0, 48),
              ),
              onPressed: () {
                if (isCompleted) {
                  onOpenResults(election!.id);
                } else {
                  onOpenBallot(election!.id);
                }
              },
              icon: Icon(isCompleted ? Icons.bar_chart_rounded : Icons.arrow_forward_rounded),
              label: Text(action),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfidenceSteps extends StatelessWidget {
  const _ConfidenceSteps();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            _Step(
              number: '1',
              title: 'Review the ballot',
              subtitle: 'Read candidate platforms at your own pace.',
            ),
            Divider(height: 25),
            _Step(
              number: '2',
              title: 'Make one selection',
              subtitle: 'Your choice remains editable until confirmation.',
            ),
            Divider(height: 25),
            _Step(
              number: '3',
              title: 'Save your receipt',
              subtitle: 'A short confirmation code proves submission, not your choice.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.subtitle});

  final String number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.bluePale, shape: BoxShape.circle),
          child: Text(
            number,
            style: const TextStyle(color: AppColors.blueDark, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(color: AppColors.inkMuted, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.onSelected});

  final ElectionStatus? selected;
  final ValueChanged<ElectionStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = <(String, ElectionStatus?)>[
      ('All', null),
      ('Open now', ElectionStatus.live),
      ('Upcoming', ElectionStatus.upcoming),
      ('Completed', ElectionStatus.completed),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(item.$1),
                selected: selected == item.$2,
                onSelected: (_) => onSelected(item.$2),
                showCheckmark: false,
                selectedColor: AppColors.bluePale,
                side: const BorderSide(color: AppColors.border),
                labelStyle: TextStyle(
                  color: selected == item.$2 ? AppColors.blueDark : AppColors.inkMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
