import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key, required this.onOpenBallot, required this.onOpenResults});

  final ValueChanged<String> onOpenBallot;
  final ValueChanged<String> onOpenResults;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  ElectionStatus? _filter;

  Future<void> _refresh() async {
    ref.invalidate(electionsProvider);
    await ref.read(electionsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final elections = ref.watch(electionsProvider);
    final firstName = (session.profile?.displayName ?? session.user?.displayName ?? 'Voter')
        .split(RegExp(r'\s+'))
        .first;

    return Scaffold(
      body: PageFrame(
        child: elections.when(
          loading: () => const LoadingState(label: 'Loading your assigned elections'),
          error: (_, __) => InlineError(
            message:
                'We could not load your assigned elections. Check your connection and try again.',
            onRetry: () => _refresh(),
          ),
          data: (items) => RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: <Widget>[
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
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
                            'Your assigned election hub',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    _ProfileStatusBadge(profile: session.profile),
                  ],
                ),
                const SizedBox(height: 22),
                if (session.isDemo) ...<Widget>[const DemoBanner(), const SizedBox(height: 18)],
                if (!session.isDemo && session.profile?.isVerified != true)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 18),
                    child: _VerificationCallout(),
                  ),
                _PrimaryElectionCard(
                  election: _bestElection(items),
                  onOpenBallot: widget.onOpenBallot,
                  onOpenResults: widget.onOpenResults,
                ),
                const SizedBox(height: 28),
                const SectionHeading(
                  title: 'A safer ballot journey',
                  subtitle:
                      'Assignment, verification, review, confirmation, and a privacy-safe receipt.',
                ),
                const SizedBox(height: 14),
                const _ConfidenceSteps(),
                const SizedBox(height: 28),
                SectionHeading(
                  title: 'Your assigned elections',
                  subtitle: items.isEmpty
                      ? 'No authority-assigned ballots are available yet.'
                      : '${items.length} election${items.length == 1 ? '' : 's'} available',
                  trailing: IconButton(
                    tooltip: 'Refresh elections',
                    onPressed: () => _refresh(),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                _FilterRow(
                  selected: _filter,
                  onSelected: (status) => setState(() => _filter = status),
                ),
                const SizedBox(height: 14),
                if (items.isEmpty)
                  const EmptyState(
                    icon: Icons.assignment_ind_outlined,
                    title: 'No ballot is assigned yet',
                    description:
                        'After the election authority verifies your eligibility and assigns a ballot, it will appear here.',
                  )
                else
                  ..._filtered(items).map(
                    (election) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ElectionListCard(
                        election: election,
                        actionLabel: election.hasSubmitted
                            ? 'View receipt status'
                            : election.status == ElectionStatus.completed
                            ? 'View results'
                            : election.status == ElectionStatus.live
                            ? 'Review ballot'
                            : 'View ballot details',
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
          ),
        ),
      ),
    );
  }

  Election? _bestElection(List<Election> elections) {
    for (final election in elections) {
      if (election.status == ElectionStatus.live && !election.hasSubmitted) return election;
    }
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

class _VerificationCallout extends StatelessWidget {
  const _VerificationCallout();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.goldPale, borderRadius: BorderRadius.circular(16)),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.pending_actions_outlined, color: AppColors.gold),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your account can review public information, but a verified profile and authority-issued ballot assignment are required before submission.',
              style: TextStyle(color: AppColors.navy, height: 1.45, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
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
    return Semantics(
      label: profile?.verificationStatus.label ?? 'Profile status loading',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              isVerified ? Icons.verified_rounded : Icons.pending_outlined,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 5),
            Text(
              isVerified ? 'Verified' : 'Pending',
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
        child: const Text('Your next authority-assigned ballot will appear here.'),
      );
    }
    final isLive = election!.status == ElectionStatus.live;
    final completed = election!.status == ElectionStatus.completed;
    final submitted = election!.hasSubmitted;
    final label = submitted
        ? 'Ballot submitted'
        : completed
        ? 'Results available'
        : isLive
        ? 'Open now'
        : 'Coming up';
    final subtitle = submitted
        ? 'A privacy-safe receipt is available in your ballot status.'
        : completed
        ? 'Results published'
        : isLive
        ? '${countdownLabel(election!.endsAt)} · ${election!.contestCount} contest${election!.contestCount == 1 ? '' : 's'}'
        : 'Opens ${formatDateTime(election!.startsAt)}';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.blueDark, AppColors.blue],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x331D5FD0), blurRadius: 22, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  submitted || completed ? Icons.receipt_long_rounded : Icons.how_to_vote_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label.toUpperCase(),
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
              if (completed) {
                onOpenResults(election!.id);
              } else {
                onOpenBallot(election!.id);
              }
            },
            icon: Icon(
              submitted || completed ? Icons.arrow_forward_rounded : Icons.fact_check_outlined,
            ),
            label: Text(
              submitted
                  ? 'View ballot status'
                  : completed
                  ? 'View published results'
                  : 'Review ballot',
            ),
          ),
        ],
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
        child: const Column(
          children: <Widget>[
            _Step(
              number: '1',
              title: 'Confirm eligibility',
              subtitle: 'The authority assigns your ballot after verification.',
            ),
            Divider(height: 25),
            _Step(
              number: '2',
              title: 'Review every contest',
              subtitle: 'One clear choice per required contest, with no silent submission.',
            ),
            Divider(height: 25),
            _Step(
              number: '3',
              title: 'Save the receipt',
              subtitle: 'It proves submission without identifying any selected option.',
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
      children: <Widget>[
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
            children: <Widget>[
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
    const items = <(String, ElectionStatus?)>[
      ('All', null),
      ('Open now', ElectionStatus.live),
      ('Upcoming', ElectionStatus.upcoming),
      ('Completed', ElectionStatus.completed),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
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
