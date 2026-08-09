import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key, this.initialElectionId});

  final String? initialElectionId;

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  String? _selectedElectionId;

  @override
  void initState() {
    super.initState();
    _selectedElectionId = widget.initialElectionId;
  }

  @override
  void didUpdateWidget(covariant ResultsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialElectionId != null &&
        widget.initialElectionId != oldWidget.initialElectionId) {
      setState(() => _selectedElectionId = widget.initialElectionId);
    }
  }

  Future<void> _refresh(String electionId) async {
    ref
      ..invalidate(electionsProvider)
      ..invalidate(resultsProvider(electionId))
      ..invalidate(liveResultsProvider(electionId));
    await ref.read(resultsProvider(electionId).future);
  }

  @override
  Widget build(BuildContext context) {
    final elections = ref.watch(electionsProvider);
    return Scaffold(
      body: PageFrame(
        child: elections.when(
          loading: () => const LoadingState(label: 'Loading published results'),
          error: (_, __) => InlineError(
            message: 'We could not load the assigned election results list.',
            onRetry: () => ref.invalidate(electionsProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.bar_chart_outlined,
                title: 'No assigned election results',
                description: 'Published results for your assigned elections will appear here.',
              );
            }
            final election = _findElection(items);
            if (election == null) {
              return const EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'This result is unavailable',
                description: 'Choose another assigned election from your dashboard.',
              );
            }
            return _ResultsBody(
              election: election,
              elections: items,
              onElectionChanged: (id) => setState(() => _selectedElectionId = id),
              onRefresh: () => _refresh(election.id),
            );
          },
        ),
      ),
    );
  }

  Election? _findElection(List<Election> elections) {
    final requested = _selectedElectionId ?? widget.initialElectionId;
    if (requested != null) {
      for (final election in elections) {
        if (election.id == requested) return election;
      }
    }
    for (final election in elections) {
      if (election.resultsVisible && election.status == ElectionStatus.live) return election;
    }
    for (final election in elections) {
      if (election.resultsVisible) return election;
    }
    return elections.first;
  }
}

class _ResultsBody extends ConsumerWidget {
  const _ResultsBody({
    required this.election,
    required this.elections,
    required this.onElectionChanged,
    required this.onRefresh,
  });

  final Election election;
  final List<Election> elections;
  final ValueChanged<String> onElectionChanged;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!election.resultsVisible) {
      return ListView(
        children: <Widget>[
          const SizedBox(height: 8),
          const SectionHeading(
            title: 'Results',
            subtitle: 'The authority controls when aggregate counts are released.',
          ),
          const SizedBox(height: 18),
          _ResultElectionPicker(
            elections: elections,
            election: election,
            onChanged: onElectionChanged,
          ),
          const SizedBox(height: 28),
          const EmptyState(
            icon: Icons.lock_clock_outlined,
            title: 'Results are not published yet',
            description:
                'Check back after the authority releases aggregate results for this election.',
          ),
        ],
      );
    }

    final streamed = ref.watch(liveResultsProvider(election.id));
    final fallback = ref.watch(resultsProvider(election.id));
    final results = streamed.valueOrNull ?? fallback.valueOrNull;
    if (results == null && (streamed.isLoading || fallback.isLoading)) {
      return const LoadingState(label: 'Loading aggregate election results');
    }
    if (results == null) {
      return InlineError(
        message: 'Published results are unavailable right now. Please try again.',
        onRetry: () => onRefresh(),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Expanded(
                child: SectionHeading(
                  title: 'Results',
                  subtitle: 'Aggregate counts only. Individual ballot choices remain private.',
                ),
              ),
              IconButton(
                tooltip: 'Refresh results',
                onPressed: () => onRefresh(),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ResultElectionPicker(
            elections: elections,
            election: election,
            onChanged: onElectionChanged,
          ),
          const SizedBox(height: 16),
          _ResultsSummary(election: election, results: results),
          const SizedBox(height: 26),
          if (results.isEmpty)
            const EmptyState(
              icon: Icons.bar_chart_outlined,
              title: 'No results reported',
              description: 'Aggregate result rows will appear when the authority publishes them.',
            )
          else
            ..._groupResults(results).entries.expand(
              (entry) => <Widget>[
                SectionHeading(
                  title: entry.key,
                  subtitle: election.status == ElectionStatus.live
                      ? 'Current aggregate count'
                      : 'Final published count',
                ),
                const SizedBox(height: 12),
                ...entry.value.map(
                  (result) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ResultCard(
                      result: result,
                      isLive: election.status == ElectionStatus.live,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Map<String, List<ElectionResult>> _groupResults(List<ElectionResult> results) {
    final groups = <String, List<ElectionResult>>{};
    for (final result in results) {
      groups.putIfAbsent(result.contestTitle, () => <ElectionResult>[]).add(result);
    }
    return groups;
  }
}

class _ResultElectionPicker extends StatelessWidget {
  const _ResultElectionPicker({
    required this.elections,
    required this.election,
    required this.onChanged,
  });

  final List<Election> elections;
  final Election election;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: election.id,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Assigned election',
        prefixIcon: Icon(Icons.account_balance_outlined),
      ),
      items: <DropdownMenuItem<String>>[
        for (final item in elections)
          DropdownMenuItem<String>(
            value: item.id,
            child: Text(item.title, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _ResultsSummary extends StatelessWidget {
  const _ResultsSummary({required this.election, required this.results});

  final Election election;
  final List<ElectionResult> results;

  @override
  Widget build(BuildContext context) {
    final totalVotes = results.fold<int>(0, (sum, result) => sum + result.votes);
    final contestCount = results.map((result) => result.contestId).toSet().length;
    final live = election.status == ElectionStatus.live;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                live ? Icons.sensors_rounded : Icons.check_circle_rounded,
                color: const Color(0xFF8DE0D3),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                live ? 'LIVE AGGREGATE COUNT' : 'PUBLISHED RESULT',
                style: const TextStyle(
                  color: Color(0xFFB9CAE0),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            election.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              _SummaryNumber(value: formatCompactNumber(totalVotes), label: 'Aggregate choices'),
              const SizedBox(width: 28),
              _SummaryNumber(value: '$contestCount', label: 'Contests'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            live
                ? 'Counts can change while voting remains open. Refresh and live updates use aggregate data only.'
                : 'This election has closed. The authority has published these aggregate results.',
            style: const TextStyle(color: Color(0xFFB9CAE0), fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _SummaryNumber extends StatelessWidget {
  const _SummaryNumber({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFB9CAE0),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.isLive});

  final ElectionResult result;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(result.accentColor);
    final percent = result.percentage.clamp(0.0, 1.0).toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                InitialAvatar(initials: _initials(result.fullName), color: color, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        result.fullName,
                        style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${result.partyName} · ${result.partyAbbreviation}',
                        style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '#${result.rank}',
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Semantics(
              label:
                  '${(percent * 100).toStringAsFixed(1)} percent, ${formatCompactNumber(result.votes)} aggregate choices',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 10,
                  backgroundColor: AppColors.canvas,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(height: 9),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  '${(percent * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800),
                ),
                Text(
                  '${formatCompactNumber(result.votes)} ${isLive ? 'choices so far' : 'choices'}',
                  style: const TextStyle(color: AppColors.inkMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
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
}
