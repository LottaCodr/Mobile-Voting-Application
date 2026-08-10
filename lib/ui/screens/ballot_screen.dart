import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../data/voting_repository.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';

class BallotScreen extends ConsumerStatefulWidget {
  const BallotScreen({super.key, this.initialElectionId});

  final String? initialElectionId;

  @override
  ConsumerState<BallotScreen> createState() => _BallotScreenState();
}

class _BallotScreenState extends ConsumerState<BallotScreen> {
  String? _selectedElectionId;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedElectionId = widget.initialElectionId;
  }

  @override
  void didUpdateWidget(covariant BallotScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialElectionId != null &&
        widget.initialElectionId != oldWidget.initialElectionId) {
      setState(() {
        _selectedElectionId = widget.initialElectionId;
        _query = '';
      });
    }
  }

  Future<void> _refresh(String electionId) async {
    ref
      ..invalidate(electionsProvider)
      ..invalidate(contestsProvider(electionId))
      ..invalidate(candidatesProvider(electionId))
      ..invalidate(ballotStatusProvider(electionId));
    await Future.wait<void>(<Future<void>>[
      ref.read(electionsProvider.future).then<void>((_) {}),
      ref.read(contestsProvider(electionId).future).then<void>((_) {}),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final elections = ref.watch(electionsProvider);
    return Scaffold(
      body: PageFrame(
        child: elections.when(
          loading: () => const LoadingState(label: 'Loading your assigned ballots'),
          error: (_, __) => InlineError(
            message: 'We could not load your ballot list. Check your connection and try again.',
            onRetry: () => ref.invalidate(electionsProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.assignment_ind_outlined,
                title: 'No ballot is assigned',
                description:
                    'An authority-issued ballot will appear here after your profile is verified and assigned.',
              );
            }
            final election = _findElection(items);
            if (election == null) {
              return const EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'This ballot is unavailable',
                description: 'Choose another election from your dashboard.',
              );
            }
            return _BallotBody(
              election: election,
              elections: items,
              query: _query,
              onElectionChanged: (id) => setState(() {
                _selectedElectionId = id;
                _query = '';
              }),
              onQueryChanged: (value) => setState(() => _query = value),
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
      if (election.status == ElectionStatus.live && !election.hasSubmitted) return election;
    }
    return elections.first;
  }
}

class _BallotBody extends ConsumerWidget {
  const _BallotBody({
    required this.election,
    required this.elections,
    required this.query,
    required this.onElectionChanged,
    required this.onQueryChanged,
    required this.onRefresh,
  });

  final Election election;
  final List<Election> elections;
  final String query;
  final ValueChanged<String> onElectionChanged;
  final ValueChanged<String> onQueryChanged;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contests = ref.watch(contestsProvider(election.id));
    final candidates = ref.watch(candidatesProvider(election.id));
    final submission = ref.watch(ballotStatusProvider(election.id));
    final session = ref.watch(sessionProvider);
    final draft = ref.watch(ballotDraftProvider);
    final choices = draft.electionId == election.id ? draft.choices : const <String, String>{};

    if (contests.isLoading || candidates.isLoading || submission.isLoading) {
      return const LoadingState(label: 'Loading ballot contests and choices');
    }
    if (contests.hasError || candidates.hasError || submission.hasError) {
      return InlineError(
        message: 'Candidate or ballot-status information is unavailable right now.',
        onRetry: () => onRefresh(),
      );
    }

    final contestList = contests.value ?? const <BallotContest>[];
    final candidateList = candidates.value ?? const <Candidate>[];
    final status =
        submission.value ??
        BallotSubmissionStatus(
          electionId: election.id,
          state: election.submissionState,
          requiresMfa: election.requiresMfa,
        );
    final requiredContests = contestList.where((contest) => contest.required).toList();
    final allRequiredSelected = requiredContests.every(
      (contest) => choices.containsKey(contest.id),
    );
    final needsMfa = status.requiresMfa && !(session.mfaStatus?.isElevated ?? false);
    final canReview =
        election.isOpen &&
        status.state == SubmissionState.eligible &&
        session.profile?.isVerified == true &&
        !needsMfa &&
        allRequiredSelected;

    return Column(
      children: <Widget>[
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: <Widget>[
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
                  'Review every contest. Your selections stay on this screen until you explicitly confirm submission.',
                  style: TextStyle(color: AppColors.inkMuted, height: 1.45),
                ),
                const SizedBox(height: 18),
                _ElectionPicker(
                  elections: elections,
                  selectedElection: election,
                  onChanged: onElectionChanged,
                ),
                const SizedBox(height: 14),
                _BallotStatusCard(
                  election: election,
                  status: status,
                  needsMfa: needsMfa,
                  verified: session.profile?.isVerified == true,
                ),
                if (status.hasSubmitted) ...<Widget>[
                  const SizedBox(height: 26),
                  _SubmittedBallotCard(status: status),
                  const SizedBox(height: 24),
                ] else ...<Widget>[
                  const SizedBox(height: 24),
                  _ProgressHeader(
                    requiredCount: requiredContests.length,
                    completedCount: choices.keys
                        .where(requiredContests.map((c) => c.id).contains)
                        .length,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    onChanged: onQueryChanged,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: 'Search a candidate or party',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (contestList.isEmpty)
                    const EmptyState(
                      icon: Icons.ballot_outlined,
                      title: 'No contests are published',
                      description: 'Contact the election authority if you expected a ballot.',
                    )
                  else
                    ...contestList.map(
                      (contest) => Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: _ContestSection(
                          contest: contest,
                          candidates: _filteredForContest(candidateList, contest.id, query),
                          selectedCandidateId: choices[contest.id],
                          enabled: election.isOpen && status.state == SubmissionState.eligible,
                          electionId: election.id,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
        if (!status.hasSubmitted)
          _BallotBottomAction(
            canReview: canReview,
            hasAnySelection: choices.isNotEmpty,
            needsMfa: needsMfa,
            verified: session.profile?.isVerified == true,
            electionOpen: election.isOpen,
            onReview: () => unawaited(
              _reviewAndSubmit(
                context: context,
                ref: ref,
                election: election,
                contests: contestList,
                candidates: candidateList,
                choices: choices,
              ),
            ),
          ),
      ],
    );
  }

  List<Candidate> _filteredForContest(List<Candidate> candidates, String contestId, String query) {
    final needle = query.trim().toLowerCase();
    return candidates.where((candidate) {
      if (candidate.contestId != contestId) return false;
      return needle.isEmpty ||
          candidate.fullName.toLowerCase().contains(needle) ||
          candidate.partyName.toLowerCase().contains(needle) ||
          candidate.partyAbbreviation.toLowerCase().contains(needle);
    }).toList();
  }

  Future<void> _reviewAndSubmit({
    required BuildContext context,
    required WidgetRef ref,
    required Election election,
    required List<BallotContest> contests,
    required List<Candidate> candidates,
    required Map<String, String> choices,
  }) async {
    final selected = <BallotContest, Candidate>{};
    for (final contest in contests) {
      final candidateId = choices[contest.id];
      if (candidateId == null) continue;
      final candidate = candidates.where((item) => item.id == candidateId).firstOrNull;
      if (candidate != null) selected[contest] = candidate;
    }
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => _BallotConfirmationSheet(election: election, selections: selected),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final receipt = await ref
          .read(votingRepositoryProvider)
          .submitBallot(
            electionId: election.id,
            choices: selected.entries
                .map((entry) => BallotChoice(contestId: entry.key.id, candidateId: entry.value.id))
                .toList(),
          );
      ref
        ..read(ballotDraftProvider.notifier).clear(election.id)
        ..invalidate(ballotStatusProvider(election.id))
        ..invalidate(electionsProvider)
        ..invalidate(resultsProvider(election.id))
        ..invalidate(liveResultsProvider(election.id));
      if (!context.mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        builder: (context) => _VoteReceiptSheet(election: election, receipt: receipt),
      );
    } on RepositoryFailure catch (error) {
      if (context.mounted) _showMessage(context, error.message);
    } catch (_) {
      if (context.mounted) {
        _showMessage(
          context,
          'Your ballot could not be submitted. Check your safe ballot status before trying again.',
        );
      }
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
      initialValue: selectedElection.id,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Assigned election',
        prefixIcon: Icon(Icons.account_balance_outlined),
      ),
      items: <DropdownMenuItem<String>>[
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

class _BallotStatusCard extends StatelessWidget {
  const _BallotStatusCard({
    required this.election,
    required this.status,
    required this.needsMfa,
    required this.verified,
  });

  final Election election;
  final BallotSubmissionStatus status;
  final bool needsMfa;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final isSubmitted = status.hasSubmitted;
    final isOpen = election.isOpen;
    final color = isSubmitted
        ? AppColors.teal
        : needsMfa || !verified
        ? AppColors.gold
        : isOpen
        ? AppColors.teal
        : AppColors.gold;
    final background = isSubmitted || (isOpen && verified && !needsMfa)
        ? AppColors.tealPale
        : AppColors.goldPale;
    final text = isSubmitted
        ? 'Ballot submitted. Your receipt is available below and does not show your selections.'
        : !verified
        ? 'Your profile must be verified before this ballot can be submitted.'
        : needsMfa
        ? 'This election requires a verified second factor before submission.'
        : isOpen
        ? 'Voting is open until ${formatDateTime(election.endsAt)}.'
        : election.status == ElectionStatus.upcoming
        ? 'Voting opens ${formatDateTime(election.startsAt)}.'
        : 'Voting closed ${formatDateTime(election.endsAt)}.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            isSubmitted
                ? Icons.verified_rounded
                : needsMfa
                ? Icons.security_rounded
                : Icons.lock_clock_outlined,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.navy,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.requiredCount, required this.completedCount});

  final int requiredCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    final progress = requiredCount == 0 ? 0.0 : completedCount / requiredCount;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.checklist_rounded, color: AppColors.blueDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$completedCount of $requiredCount required contest${requiredCount == 1 ? '' : 's'} selected',
                    style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 9,
                backgroundColor: AppColors.canvas,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContestSection extends ConsumerWidget {
  const _ContestSection({
    required this.contest,
    required this.candidates,
    required this.selectedCandidateId,
    required this.enabled,
    required this.electionId,
  });

  final BallotContest contest;
  final List<Candidate> candidates;
  final String? selectedCandidateId;
  final bool enabled;
  final String electionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    contest.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contest.instructions,
                    style: const TextStyle(color: AppColors.inkMuted, height: 1.4),
                  ),
                ],
              ),
            ),
            if (contest.required)
              const Padding(
                padding: EdgeInsets.only(left: 10),
                child: StatusPill(status: ElectionStatus.live),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (candidates.isEmpty)
          const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'No options found',
            description: 'Clear the search or contact the election authority.',
          )
        else
          ...candidates.map(
            (candidate) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CandidateChoiceCard(
                candidate: candidate,
                selected: candidate.id == selectedCandidateId,
                enabled: enabled,
                onSelected: () => ref
                    .read(ballotDraftProvider.notifier)
                    .select(
                      electionId: electionId,
                      contestId: contest.id,
                      candidateId: candidate.id,
                    ),
              ),
            ),
          ),
      ],
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
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    InitialAvatar(
                      initials: candidate.initials,
                      color: color,
                      semanticLabel: '${candidate.fullName} initials',
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
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
                    Icon(
                      selected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: color,
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _showCandidateDetails(context),
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

  void _showCandidateDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
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
              children: <Widget>[
                InitialAvatar(
                  initials: candidate.initials,
                  color: colorFromHex(candidate.accentColor),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
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
          ],
        ),
      ),
    );
  }
}

class _BallotBottomAction extends StatelessWidget {
  const _BallotBottomAction({
    required this.canReview,
    required this.hasAnySelection,
    required this.needsMfa,
    required this.verified,
    required this.electionOpen,
    required this.onReview,
  });

  final bool canReview;
  final bool hasAnySelection;
  final bool needsMfa;
  final bool verified;
  final bool electionOpen;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final label = !electionOpen
        ? 'Ballot is not open for voting'
        : !verified
        ? 'Verification required before voting'
        : needsMfa
        ? 'Complete multi-factor verification'
        : !hasAnySelection
        ? 'Select every required contest'
        : 'Review your ballot';
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: FilledButton.icon(
            onPressed: canReview ? onReview : null,
            icon: const Icon(Icons.fact_check_outlined),
            label: Text(label),
          ),
        ),
      ),
    );
  }
}

class _SubmittedBallotCard extends StatelessWidget {
  const _SubmittedBallotCard({required this.status});

  final BallotSubmissionStatus status;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(color: AppColors.tealPale, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: AppColors.teal, size: 31),
            ),
            const SizedBox(height: 14),
            Text(
              'Ballot submitted',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'This status intentionally does not reveal any selected candidate or option.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkMuted, height: 1.45),
            ),
            if (status.receiptCode != null) ...<Widget>[
              const SizedBox(height: 16),
              SelectableText(
                status.receiptCode!,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
            if (status.submittedAt != null) ...<Widget>[
              const SizedBox(height: 5),
              Text(
                formatDateTime(status.submittedAt!),
                style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BallotConfirmationSheet extends StatefulWidget {
  const _BallotConfirmationSheet({required this.election, required this.selections});

  final Election election;
  final Map<BallotContest, Candidate> selections;

  @override
  State<_BallotConfirmationSheet> createState() => _BallotConfirmationSheetState();
}

class _BallotConfirmationSheetState extends State<_BallotConfirmationSheet> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
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
              'Review your full ballot',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check every contest below. A submitted ballot cannot be changed.',
              style: TextStyle(color: AppColors.inkMuted, height: 1.5),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: <Widget>[
                    for (final entry in widget.selections.entries) ...<Widget>[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          entry.key.title,
                          style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: <Widget>[
                          InitialAvatar(
                            initials: entry.value.initials,
                            color: colorFromHex(entry.value.accentColor),
                            size: 38,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${entry.value.fullName} · ${entry.value.partyAbbreviation}',
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (entry.key != widget.selections.keys.last) const Divider(height: 24),
                    ],
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
              title: const Text(
                'I have checked every selection and understand this ballot cannot be changed after submission.',
                style: TextStyle(color: AppColors.navy, height: 1.4, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _acknowledged ? () => Navigator.of(context).pop(true) : null,
              icon: const Icon(Icons.lock_rounded),
              label: const Text('Submit secure ballot'),
            ),
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
  const _VoteReceiptSheet({required this.election, required this.receipt});

  final Election election;
  final VoteReceipt receipt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: AppColors.tealPale, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: AppColors.teal, size: 34),
          ),
          const SizedBox(height: 18),
          Text(
            'Ballot submitted',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your receipt proves submission only. It does not identify any selected candidate or option.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkMuted, height: 1.45),
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
              children: <Widget>[
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
