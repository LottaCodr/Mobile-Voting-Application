import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../domain/models.dart';
import '../widgets/common.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, this.initialElectionId});

  final String? initialElectionId;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late Future<List<Election>> _elections;
  final Map<String, Future<List<ElectionResult>>> _resultFutures =
      <String, Future<List<ElectionResult>>>{};
  String? _selectedElectionId;

  bool _loadedInitialData = false;

  @override
  void initState() {
    super.initState();
    _selectedElectionId = widget.initialElectionId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedInitialData) return;
    _loadedInitialData = true;
    _elections = AppScope.of(context).services.voting.loadElections();
  }

  @override
  void didUpdateWidget(covariant ResultsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialElectionId != null &&
        widget.initialElectionId != oldWidget.initialElectionId) {
      setState(() => _selectedElectionId = widget.initialElectionId);
    }
  }

  Future<List<ElectionResult>> _resultsFor(String electionId) {
    return _resultFutures.putIfAbsent(
      electionId,
      () => AppScope.of(context).services.voting.loadResults(electionId),
    );
  }

  Future<void> _reload() async {
    setState(() {
      _elections = AppScope.of(context).services.voting.loadElections();
      _resultFutures.clear();
    });
    await _elections;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageFrame(
        child: FutureBuilder<List<Election>>(
          future: _elections,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LoadingState(label: 'Loading published results');
            }
            if (snapshot.hasError) {
              return InlineError(
                message: 'We could not load the election results list. Please try again.',
                onRetry: _reload,
              );
            }
            final elections = snapshot.data ?? const <Election>[];
            if (elections.isEmpty) {
              return const EmptyState(
                icon: Icons.bar_chart_outlined,
                title: 'No results available',
                description:
                    'Published results will appear here once an election is ready to share them.',
              );
            }
            final election = _findElection(elections);
            if (election == null) {
              return const EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'This result is unavailable',
                description: 'Choose an election from your dashboard.',
              );
            }
            return _ResultsBody(
              election: election,
              elections: elections,
              resultsFuture: _resultsFor(election.id),
              onElectionChanged: (id) => setState(() => _selectedElectionId = id),
              onReload: _reload,
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

class _ResultsBody extends StatelessWidget {
  const _ResultsBody({
    required this.election,
    required this.elections,
    required this.resultsFuture,
    required this.onElectionChanged,
    required this.onReload,
  });

  final Election election;
  final List<Election> elections;
  final Future<List<ElectionResult>> resultsFuture;
  final ValueChanged<String> onElectionChanged;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    if (!election.resultsVisible) {
      return ListView(
        children: [
          const SizedBox(height: 8),
          const SectionHeading(
            title: 'Results',
            subtitle: 'Choose an election to see published, aggregate results.',
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
                'This election is still pending or has not been opened for public results. Check back after the official release.',
          ),
        ],
      );
    }

    return FutureBuilder<List<ElectionResult>>(
      future: resultsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingState(label: 'Loading aggregate election results');
        }
        if (snapshot.hasError) {
          return InlineError(
            message: 'Published results are unavailable right now. Please try again.',
            onRetry: () => onReload(),
          );
        }
        final results = snapshot.data ?? const <ElectionResult>[];
        final totalVotes = results.isEmpty ? 0 : results.first.totalVotes;
        final leading = results.isEmpty ? null : results.first;
        return RefreshIndicator(
          onRefresh: onReload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(
                    child: SectionHeading(
                      title: 'Results',
                      subtitle: 'Aggregate counts only. Individual ballot choices remain private.',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh results',
                    onPressed: onReload,
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
              _ResultsSummary(election: election, totalVotes: totalVotes, leader: leading),
              const SizedBox(height: 26),
              SectionHeading(
                title: election.status == ElectionStatus.live ? 'Current count' : 'Final count',
                subtitle: results.isEmpty
                    ? 'No aggregate votes have been published.'
                    : '${formatCompactNumber(totalVotes)} votes reported',
              ),
              const SizedBox(height: 14),
              if (results.isEmpty)
                const EmptyState(
                  icon: Icons.bar_chart_outlined,
                  title: 'No results reported',
                  description: 'Aggregate result rows will appear when they are published.',
                )
              else
                ...results.map(
                  (result) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ResultCard(
                      result: result,
                      isLive: election.status == ElectionStatus.live,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
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
        labelText: 'Election',
        prefixIcon: Icon(Icons.account_balance_outlined),
      ),
      items: [
        for (final item in elections)
          DropdownMenuItem(
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
  const _ResultsSummary({required this.election, required this.totalVotes, required this.leader});

  final Election election;
  final int totalVotes;
  final ElectionResult? leader;

  @override
  Widget build(BuildContext context) {
    final live = election.status == ElectionStatus.live;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
            children: [
              _SummaryNumber(value: formatCompactNumber(totalVotes), label: 'Votes reported'),
              const SizedBox(width: 28),
              Expanded(
                child: Text(
                  leader == null
                      ? 'Waiting for the first published count.'
                      : '${leader!.fullName} is currently ranked first at ${(leader!.percentage * 100).toStringAsFixed(1)}%.',
                  style: const TextStyle(color: Color(0xFFDDE9F8), height: 1.45),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            live ? 'Counts can change while voting remains open.' : 'This election has closed.',
            style: const TextStyle(color: Color(0xFFB9CAE0), fontSize: 12),
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
      children: [
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
          children: [
            Row(
              children: [
                InitialAvatar(
                  initials: _initials(result.fullName),
                  color: color,
                  size: 44,
                  semanticLabel: '${result.fullName} initials',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                  '${(percent * 100).toStringAsFixed(1)} percent, ${formatCompactNumber(result.votes)} votes',
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
              children: [
                Text(
                  '${(percent * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800),
                ),
                Text(
                  '${formatCompactNumber(result.votes)} ${isLive ? 'votes so far' : 'votes'}',
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
