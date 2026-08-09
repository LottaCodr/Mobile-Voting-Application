import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../data/voting_repository.dart';
import '../../domain/models.dart';
import '../widgets/common.dart';

class BallotScreen extends StatefulWidget {
  const BallotScreen({super.key, this.initialElectionId});

  final String? initialElectionId;

  @override
  State<BallotScreen> createState() => _BallotScreenState();
}

class _BallotScreenState extends State<BallotScreen> {
  late Future<List<Election>> _elections;
  final Map<String, Future<List<Candidate>>> _candidateFutures =
      <String, Future<List<Candidate>>>{};
  String? _selectedElectionId;
  String? _selectedCandidateId;
  String _query = '';

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
  void didUpdateWidget(covariant BallotScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialElectionId != null &&
        widget.initialElectionId != oldWidget.initialElectionId) {
      setState(() {
        _selectedElectionId = widget.initialElectionId;
        _selectedCandidateId = null;
        _query = '';
      });
    }
  }

  Future<List<Candidate>> _candidatesFor(String electionId) {
    return _candidateFutures.putIfAbsent(
      electionId,
      () => AppScope.of(context).services.voting.loadCandidates(electionId),
    );
  }

  Future<void> _reload() async {
    setState(() {
      _elections = AppScope.of(context).services.voting.loadElections();
      _candidateFutures.clear();
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
              return const LoadingState(label: 'Loading ballot choices');
            }
            if (snapshot.hasError) {
              return InlineError(
                message: 'We could not load the ballot list. Check your connection and try again.',
                onRetry: _reload,
              );
            }
            final elections = snapshot.data ?? const <Election>[];
            if (elections.isEmpty) {
              return const EmptyState(
                icon: Icons.how_to_vote_outlined,
                title: 'No ballots are available',
                description:
                    'Published ballots will appear here when you are eligible to review them.',
              );
            }
            final selectedElection = _findElection(elections);
            if (selectedElection == null) {
              return const EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'This ballot is unavailable',
                description: 'Choose another election from your dashboard.',
              );
            }
            return _BallotBody(
              election: selectedElection,
              elections: elections,
              candidatesFuture: _candidatesFor(selectedElection.id),
              selectedCandidateId: _selectedCandidateId,
              query: _query,
              onElectionChanged: (id) => setState(() {
                _selectedElectionId = id;
                _selectedCandidateId = null;
                _query = '';
              }),
              onCandidateChanged: (id) => setState(() => _selectedCandidateId = id),
              onQueryChanged: (value) => setState(() => _query = value),
              onReload: _reload,
              onReview: _reviewVote,
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
      if (election.status == ElectionStatus.live) return election;
    }
    return elections.first;
  }

  Future<void> _reviewVote(Election election, Candidate candidate) async {
    final controller = AppScope.of(context);
    final profile = controller.profile;
    if (!controller.isDemo && profile?.isVerified != true) {
      _showMessage('Your voter verification must be completed before a ballot can be submitted.');
      return;
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _VoteConfirmationSheet(
        election: election,
        candidate: candidate,
        isDemo: controller.isDemo,
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final receipt = await controller.services.voting.castVote(
        electionId: election.id,
        candidateId: candidate.id,
      );
      if (!mounted) return;
      setState(() => _selectedCandidateId = null);
      await showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        builder: (context) =>
            _VoteReceiptSheet(election: election, receipt: receipt, isDemo: controller.isDemo),
      );
    } on RepositoryFailure catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Your selection could not be submitted. Please try again.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _BallotBody extends StatelessWidget {
  const _BallotBody({
    required this.election,
    required this.elections,
    required this.candidatesFuture,
    required this.selectedCandidateId,
    required this.query,
    required this.onElectionChanged,
    required this.onCandidateChanged,
    required this.onQueryChanged,
    required this.onReload,
    required this.onReview,
  });

  final Election election;
  final List<Election> elections;
  final Future<List<Candidate>> candidatesFuture;
  final String? selectedCandidateId;
  final String query;
  final ValueChanged<String> onElectionChanged;
  final ValueChanged<String> onCandidateChanged;
  final ValueChanged<String> onQueryChanged;
  final Future<void> Function() onReload;
  final Future<void> Function(Election election, Candidate candidate) onReview;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Candidate>>(
      future: candidatesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingState(label: 'Loading candidates');
        }
        if (snapshot.hasError) {
          return InlineError(
            message: 'Candidate information is unavailable right now.',
            onRetry: () => onReload(),
          );
        }
        final candidates = snapshot.data ?? const <Candidate>[];
        final filtered = candidates.where((candidate) {
          final needle = query.trim().toLowerCase();
          return needle.isEmpty ||
              candidate.fullName.toLowerCase().contains(needle) ||
              candidate.partyName.toLowerCase().contains(needle) ||
              candidate.partyAbbreviation.toLowerCase().contains(needle);
        }).toList();
        final selected = candidates
            .where((candidate) => candidate.id == selectedCandidateId)
            .firstOrNull;
        final canSubmit = election.status == ElectionStatus.live && selected != null;

        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: onReload,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Your ballot',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Take your time. Your choice is not submitted until you confirm it.',
                      style: TextStyle(color: AppColors.inkMuted, height: 1.45),
                    ),
                    const SizedBox(height: 18),
                    _ElectionPicker(
                      elections: elections,
                      selectedElection: election,
                      onChanged: onElectionChanged,
                    ),
                    const SizedBox(height: 14),
                    _BallotNotice(election: election),
                    const SizedBox(height: 24),
                    SectionHeading(
                      title: 'Choose one candidate',
                      subtitle: election.status == ElectionStatus.live
                          ? 'Tap a candidate to select them. You can change your mind before confirmation.'
                          : election.status == ElectionStatus.upcoming
                          ? 'This ballot is not open yet. You can still review the candidates.'
                          : 'This ballot has closed. Candidate information remains available for reference.',
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      onChanged: onQueryChanged,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'Search candidate or party',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (filtered.isEmpty)
                      const EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No candidates found',
                        description: 'Try a different name or party.',
                      )
                    else
                      ...filtered.map(
                        (candidate) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CandidateChoiceCard(
                            candidate: candidate,
                            selected: candidate.id == selectedCandidateId,
                            enabled: election.status == ElectionStatus.live,
                            onSelected: () => onCandidateChanged(candidate.id),
                          ),
                        ),
                      ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
            _BallotBottomAction(
              selected: selected,
              canSubmit: canSubmit,
              onReview: () {
                if (selected != null) onReview(election, selected);
              },
            ),
          ],
        );
      },
    );
  }
}

class _ElectionPicker extends StatelessWidget {
  const _ElectionPicker({
    required this.elections,
    required this.selectedElection,
    required this.onChanged,
  });

  final List<Election> elections;
  final Election selectedElection;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedElection.id,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Election',
        prefixIcon: Icon(Icons.account_balance_outlined),
      ),
      items: [
        for (final election in elections)
          DropdownMenuItem<String>(
            value: election.id,
            child: Text(election.title, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _BallotNotice extends StatelessWidget {
  const _BallotNotice({required this.election});

  final Election election;

  @override
  Widget build(BuildContext context) {
    final isLive = election.status == ElectionStatus.live;
    final color = isLive ? AppColors.teal : AppColors.gold;
    final background = isLive ? AppColors.tealPale : AppColors.goldPale;
    final text = isLive
        ? 'Voting is open until ${formatDateTime(election.endsAt)}. ${countdownLabel(election.endsAt)}.'
        : election.status == ElectionStatus.upcoming
        ? 'Voting opens ${formatDateTime(election.startsAt)}.'
        : 'Voting closed ${formatDateTime(election.endsAt)}.';
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(16)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(isLive ? Icons.lock_clock_outlined : Icons.info_outline_rounded, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: AppColors.navy, height: 1.4, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateChoiceCard extends StatelessWidget {
  const _CandidateChoiceCard({
    required this.candidate,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final Candidate candidate;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(candidate.accentColor);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? AppColors.blue : AppColors.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        selected: selected,
        button: enabled,
        label:
            '${candidate.fullName}, ${candidate.partyName}. ${selected ? 'Selected.' : 'Not selected.'}',
        child: InkWell(
          onTap: enabled ? onSelected : null,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InitialAvatar(
                      initials: candidate.initials,
                      color: color,
                      semanticLabel: '${candidate.fullName} initials',
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            candidate.fullName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${candidate.partyName} · ${candidate.partyAbbreviation}',
                            style: const TextStyle(color: AppColors.inkMuted, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    Radio<String>(
                      value: candidate.id,
                      groupValue: selected ? candidate.id : null,
                      onChanged: enabled ? (_) => onSelected() : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  candidate.manifesto,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.inkMuted, height: 1.45),
                ),
                const SizedBox(height: 5),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _showCandidateDetails(context, candidate),
                    icon: const Icon(Icons.article_outlined, size: 18),
                    label: const Text('Read platform'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCandidateDetails(BuildContext context, Candidate candidate) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                InitialAvatar(
                  initials: candidate.initials,
                  color: colorFromHex(candidate.accentColor),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.fullName,
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${candidate.partyName} · ${candidate.partyAbbreviation}',
                        style: const TextStyle(color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Platform',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              candidate.manifesto,
              style: const TextStyle(color: AppColors.inkMuted, height: 1.55),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

class _BallotBottomAction extends StatelessWidget {
  const _BallotBottomAction({
    required this.selected,
    required this.canSubmit,
    required this.onReview,
  });

  final Candidate? selected;
  final bool canSubmit;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.canvas,
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: FilledButton.icon(
            onPressed: canSubmit ? onReview : null,
            icon: const Icon(Icons.fact_check_outlined),
            label: Text(
              selected == null
                  ? 'Select a candidate to continue'
                  : canSubmit
                  ? 'Review your selection'
                  : 'Ballot is not open for voting',
            ),
          ),
        ),
      ),
    );
  }
}

class _VoteConfirmationSheet extends StatefulWidget {
  const _VoteConfirmationSheet({
    required this.election,
    required this.candidate,
    required this.isDemo,
  });

  final Election election;
  final Candidate candidate;
  final bool isDemo;

  @override
  State<_VoteConfirmationSheet> createState() => _VoteConfirmationSheetState();
}

class _VoteConfirmationSheetState extends State<_VoteConfirmationSheet> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    final candidate = widget.candidate;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Review your selection',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Confirm the candidate and election below. ${widget.isDemo ? 'This is a fictional demo action.' : 'A submitted ballot cannot be changed.'}',
              style: const TextStyle(color: AppColors.inkMuted, height: 1.5),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.election.title,
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        InitialAvatar(
                          initials: candidate.initials,
                          color: colorFromHex(candidate.accentColor),
                          size: 44,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                candidate.fullName,
                                style: const TextStyle(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${candidate.partyName} · ${candidate.partyAbbreviation}',
                                style: const TextStyle(color: AppColors.inkMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _acknowledged,
              onChanged: (value) => setState(() => _acknowledged = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: Text(
                widget.isDemo
                    ? 'I understand this only records a local demo vote.'
                    : 'I have checked my selection and understand it cannot be changed after submission.',
                style: const TextStyle(
                  color: AppColors.navy,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _acknowledged ? () => Navigator.of(context).pop(true) : null,
              icon: const Icon(Icons.lock_rounded),
              label: Text(widget.isDemo ? 'Record demo selection' : 'Submit secure ballot'),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Go back and edit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoteReceiptSheet extends StatelessWidget {
  const _VoteReceiptSheet({required this.election, required this.receipt, required this.isDemo});

  final Election election;
  final VoteReceipt receipt;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: AppColors.tealPale, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: AppColors.teal, size: 34),
          ),
          const SizedBox(height: 18),
          Text(
            isDemo ? 'Demo selection recorded' : 'Ballot submitted',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            isDemo
                ? 'You can use this screen to evaluate the confirmation experience.'
                : 'Your ballot was accepted. This receipt confirms submission, not who you selected.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.inkMuted, height: 1.45),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'SUBMISSION RECEIPT',
                  style: TextStyle(
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 7),
                SelectableText(
                  receipt.code,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatDateTime(receipt.castAt),
                  style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            election.title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
          ),
          const SizedBox(height: 22),
          FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    for (final value in this) {
      return value;
    }
    return null;
  }
}
