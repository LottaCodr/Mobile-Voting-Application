import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../data/voting_repository.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  String? _assignmentElectionId;

  void _refreshAll() {
    ref
      ..invalidate(adminMetricsProvider)
      ..invalidate(pendingVotersProvider)
      ..invalidate(auditEventsProvider)
      ..invalidate(managedElectionsProvider)
      ..invalidate(electionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    if (!session.canAdminister) {
      return Scaffold(
        appBar: AppBar(title: const Text('Authority workspace')),
        body: const EmptyState(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Authority access required',
          description:
              'This workspace is available only to roles granted by an authorised administrator.',
        ),
      );
    }

    final metrics = ref.watch(adminMetricsProvider);
    final elections = ref.watch(managedElectionsProvider);
    final voters = session.canVerify ? ref.watch(pendingVotersProvider) : null;
    final auditEvents =
        session.roles.any((role) => role == AppRole.administrator || role == AppRole.auditor)
        ? ref.watch(auditEventsProvider)
        : null;
    final selectedElection =
        elections.value
            ?.where((election) => election.id == _assignmentElectionId)
            .firstOrNull ??
        elections.value?.firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Authority workspace'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh authority workspace',
            onPressed: _refreshAll,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: PageFrame(
        child: RefreshIndicator(
          onRefresh: () async => _refreshAll(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: <Widget>[
              const SizedBox(height: 8),
              const SectionHeading(
                title: 'Election operations',
                subtitle:
                    'Authority roles only. Every sensitive action is checked server-side and written to the audit trail.',
              ),
              const SizedBox(height: 16),
              metrics.when(
                loading: () => const LoadingState(label: 'Loading authority metrics'),
                error: (_, __) => InlineError(
                  message: 'Administrative metrics are unavailable right now.',
                  onRetry: () => ref.invalidate(adminMetricsProvider),
                ),
                data: (value) => _MetricsGrid(metrics: value),
              ),
              const SizedBox(height: 28),
              if (session.canManageElections) ...<Widget>[
                SectionHeading(
                  title: 'Elections and contests',
                  subtitle: 'Create, publish, require MFA, and control result release.',
                  trailing: FilledButton.icon(
                    onPressed: () => unawaited(_openCreateElection(context)),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Election'),
                  ),
                ),
                const SizedBox(height: 14),
                elections.when(
                  loading: () => const LoadingState(label: 'Loading managed elections'),
                  error: (_, __) => InlineError(
                    message: 'Managed elections are unavailable right now.',
                    onRetry: () => ref.invalidate(managedElectionsProvider),
                  ),
                  data: (items) => items.isEmpty
                      ? const EmptyState(
                          icon: Icons.event_busy_outlined,
                          title: 'No managed elections',
                          description:
                              'Create an election before assigning voters or publishing a ballot.',
                        )
                      : Column(
                          children: <Widget>[
                            for (final election in items)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ManagedElectionCard(
                                  election: election,
                                  onUpdate: _updateElection,
                                  onAddContest: () =>
                                      unawaited(_openCreateContest(context, election)),
                                  onAddCandidate: () =>
                                      unawaited(_openCreateCandidate(context, election)),
                                ),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 28),
              ],
              if (session.canVerify) ...<Widget>[
                const SectionHeading(
                  title: 'Verification and assignment queue',
                  subtitle:
                      'Verification does not automatically grant a ballot; assign a voter to a specific election after review.',
                ),
                const SizedBox(height: 14),
                if (elections.value?.isNotEmpty == true)
                  DropdownButtonFormField<String>(
                    initialValue: selectedElection?.id,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Election for approved voter assignments',
                      prefixIcon: Icon(Icons.assignment_ind_outlined),
                    ),
                    items: <DropdownMenuItem<String>>[
                      for (final election in elections.value ?? const <Election>[])
                        DropdownMenuItem<String>(value: election.id, child: Text(election.title)),
                    ],
                    onChanged: (value) => setState(() => _assignmentElectionId = value),
                  ),
                const SizedBox(height: 12),
                voters!.when(
                  loading: () => const LoadingState(label: 'Loading verification queue'),
                  error: (_, __) => InlineError(
                    message: 'The verification queue is unavailable right now.',
                    onRetry: () => ref.invalidate(pendingVotersProvider),
                  ),
                  data: (items) => items.isEmpty
                      ? const EmptyState(
                          icon: Icons.task_alt_rounded,
                          title: 'Verification queue is clear',
                          description:
                              'Pending voter profiles will appear here for authority review.',
                        )
                      : Column(
                          children: <Widget>[
                            for (final voter in items)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _PendingVoterCard(
                                  voter: voter,
                                  assignmentElection: selectedElection,
                                  onDecision: (status) => _setVerification(
                                    voter: voter,
                                    status: status,
                                    election: selectedElection,
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 28),
              ],
              if (auditEvents != null) ...<Widget>[
                const SectionHeading(
                  title: 'Recent audit activity',
                  subtitle: 'A receipt-safe operational trail for authority actions.',
                ),
                const SizedBox(height: 12),
                auditEvents.when(
                  loading: () => const LoadingState(label: 'Loading audit activity'),
                  error: (_, __) => InlineError(
                    message: 'Recent audit activity is unavailable right now.',
                    onRetry: () => ref.invalidate(auditEventsProvider),
                  ),
                  data: (events) => events.isEmpty
                      ? const EmptyState(
                          icon: Icons.history_outlined,
                          title: 'No audit events yet',
                          description:
                              'Authorised authority actions will appear here without ballot choices.',
                        )
                      : Card(
                          child: Column(
                            children: <Widget>[
                              for (final event in events.take(8))
                                ListTile(
                                  leading: const Icon(
                                    Icons.history_rounded,
                                    color: AppColors.blueDark,
                                  ),
                                  title: Text(_auditLabel(event.eventType)),
                                  subtitle: Text(
                                    '${event.targetType} · ${formatDateTime(event.occurredAt)}',
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 28),
              ],
              const _OperationalNotice(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setVerification({
    required AdminVoter voter,
    required VerificationStatus status,
    required Election? election,
  }) async {
    try {
      await ref
          .read(votingRepositoryProvider)
          .setVoterVerification(
            voterId: voter.id,
            status: status,
            jurisdiction: voter.jurisdiction,
          );
      if (status == VerificationStatus.verified && election != null) {
        await ref
            .read(votingRepositoryProvider)
            .assignVoterToElection(voterId: voter.id, electionId: election.id);
      }
      _refreshAll();
      if (mounted) {
        _message(
          status == VerificationStatus.verified
              ? 'Voter verified and assigned.'
              : 'Verification decision recorded.',
        );
      }
    } on RepositoryFailure catch (error) {
      if (mounted) _message(error.message);
    }
  }

  Future<void> _updateElection(Map<String, dynamic> payload) async {
    try {
      await ref.read(votingRepositoryProvider).updateElection(payload);
      _refreshAll();
      if (mounted) _message('Election settings updated.');
    } on RepositoryFailure catch (error) {
      if (mounted) _message(error.message);
    }
  }

  Future<void> _openCreateElection(BuildContext context) async {
    final payload = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _CreateElectionSheet(),
    );
    if (payload == null) return;
    try {
      await ref.read(votingRepositoryProvider).createElection(payload);
      _refreshAll();
      if (mounted) _message('Election created with a default contest.');
    } on RepositoryFailure catch (error) {
      if (mounted) _message(error.message);
    }
  }

  Future<void> _openCreateContest(BuildContext context, Election election) async {
    final payload = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _CreateContestSheet(election: election),
    );
    if (payload == null) return;
    try {
      await ref.read(votingRepositoryProvider).createContest(payload);
      ref.invalidate(contestsProvider(election.id));
      if (mounted) _message('Contest created. Add ballot options next.');
    } on RepositoryFailure catch (error) {
      if (mounted) _message(error.message);
    }
  }

  Future<void> _openCreateCandidate(BuildContext context, Election election) async {
    final contests = await ref.read(contestsProvider(election.id).future);
    if (!context.mounted) return;
    final payload = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _CreateCandidateSheet(election: election, contests: contests),
    );
    if (payload == null) return;
    try {
      await ref.read(votingRepositoryProvider).createCandidate(payload);
      ref
        ..invalidate(candidatesProvider(election.id))
        ..invalidate(resultsProvider(election.id));
      if (mounted) _message('Candidate added to the contest.');
    } on RepositoryFailure catch (error) {
      if (mounted) _message(error.message);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.metrics});

  final AdminMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String, IconData, Color)>[
      (
        'Pending review',
        '${metrics.pendingVerifications}',
        Icons.pending_actions_outlined,
        AppColors.gold,
      ),
      ('Live elections', '${metrics.liveElections}', Icons.sensors_rounded, AppColors.teal),
      (
        'Assignments',
        '${metrics.eligibleAssignments}',
        Icons.assignment_ind_outlined,
        AppColors.blueDark,
      ),
      (
        'Submitted',
        '${metrics.submittedBallots}',
        Icons.receipt_long_outlined,
        const Color(0xFF7C3AED),
      ),
    ];
    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width >= 620 ? 4 : 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.25,
      children: <Widget>[
        for (final item in items)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(item.$3, color: item.$4),
                  const Spacer(),
                  Text(
                    item.$2,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    item.$1,
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ManagedElectionCard extends StatelessWidget {
  const _ManagedElectionCard({
    required this.election,
    required this.onUpdate,
    required this.onAddContest,
    required this.onAddCandidate,
  });

  final Election election;
  final ValueChanged<Map<String, dynamic>> onUpdate;
  final VoidCallback onAddContest;
  final VoidCallback onAddCandidate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        election.title,
                        style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${election.jurisdiction} · ${formatDate(election.startsAt)}',
                        style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                StatusPill(status: election.status),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilterChip(
                  label: const Text('Public ballot'),
                  selected: election.isPublic,
                  onSelected: (value) =>
                      onUpdate(<String, dynamic>{'id': election.id, 'is_public': value}),
                ),
                FilterChip(
                  label: const Text('Require MFA'),
                  selected: election.requiresMfa,
                  onSelected: (value) =>
                      onUpdate(<String, dynamic>{'id': election.id, 'requires_mfa': value}),
                ),
                FilterChip(
                  label: const Text('Release results'),
                  selected: election.resultsVisible,
                  onSelected: (value) =>
                      onUpdate(<String, dynamic>{'id': election.id, 'results_visible': value}),
                ),
                PopupMenuButton<ElectionStatus>(
                  tooltip: 'Change election status',
                  onSelected: (value) =>
                      onUpdate(<String, dynamic>{'id': election.id, 'status': value.name}),
                  itemBuilder: (_) => const <PopupMenuEntry<ElectionStatus>>[
                    PopupMenuItem(value: ElectionStatus.upcoming, child: Text('Mark upcoming')),
                    PopupMenuItem(value: ElectionStatus.live, child: Text('Open voting')),
                    PopupMenuItem(value: ElectionStatus.completed, child: Text('Close election')),
                  ],
                  child: const Chip(label: Text('Status')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                TextButton.icon(
                  onPressed: onAddContest,
                  icon: const Icon(Icons.add_chart_outlined),
                  label: const Text('Contest'),
                ),
                TextButton.icon(
                  onPressed: onAddCandidate,
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Candidate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingVoterCard extends StatelessWidget {
  const _PendingVoterCard({
    required this.voter,
    required this.assignmentElection,
    required this.onDecision,
  });

  final AdminVoter voter;
  final Election? assignmentElection;
  final ValueChanged<VerificationStatus> onDecision;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            InitialAvatar(initials: _initials(voter.displayName), color: AppColors.gold, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    voter.displayName,
                    style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    voter.jurisdiction ?? 'Jurisdiction not set',
                    style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Requested ${formatDate(voter.createdAt)}',
                    style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            PopupMenuButton<VerificationStatus>(
              tooltip: 'Review voter',
              onSelected: onDecision,
              itemBuilder: (_) => <PopupMenuEntry<VerificationStatus>>[
                PopupMenuItem(
                  value: VerificationStatus.verified,
                  child: Text(assignmentElection == null ? 'Verify' : 'Verify and assign ballot'),
                ),
                const PopupMenuItem(
                  value: VerificationStatus.rejected,
                  child: Text('Request correction'),
                ),
              ],
              icon: const Icon(Icons.more_vert_rounded),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final words = name.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    return words.length == 1
        ? words.first[0].toUpperCase()
        : '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}

class _OperationalNotice extends StatelessWidget {
  const _OperationalNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.goldPale, borderRadius: BorderRadius.circular(18)),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.policy_outlined, color: AppColors.gold),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Operational actions are auditable, but this interface does not replace legal approval, independent review, incident procedures, or election certification.',
              style: TextStyle(color: AppColors.navy, height: 1.45, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateElectionSheet extends StatefulWidget {
  const _CreateElectionSheet();

  @override
  State<_CreateElectionSheet> createState() => _CreateElectionSheetState();
}

class _CreateElectionSheetState extends State<_CreateElectionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _jurisdiction = TextEditingController();
  final _description = TextEditingController();
  DateTime _start = DateTime.now().add(const Duration(days: 1));
  DateTime _end = DateTime.now().add(const Duration(days: 2));
  bool _requiresMfa = true;

  @override
  void dispose() {
    _title.dispose();
    _jurisdiction.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool start}) async {
    final current = start ? _start : _end;
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: current,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;
    final value = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (start) {
        _start = value;
        if (!_end.isAfter(_start)) _end = _start.add(const Duration(hours: 1));
      } else {
        _end = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.viewInsetsOf(context).bottom + 28),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Create election',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Election title'),
                validator: (value) => (value ?? '').trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _jurisdiction,
                decoration: const InputDecoration(labelText: 'Jurisdiction'),
                validator: (value) => (value ?? '').trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Public description'),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Opens'),
                subtitle: Text(formatDateTime(_start)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () => unawaited(_pick(start: true)),
              ),
              ListTile(
                title: const Text('Closes'),
                subtitle: Text(formatDateTime(_end)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () => unawaited(_pick(start: false)),
              ),
              SwitchListTile.adaptive(
                value: _requiresMfa,
                onChanged: (value) => setState(() => _requiresMfa = value),
                title: const Text('Require MFA before submission'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  if (!(_formKey.currentState?.validate() ?? false) || !_end.isAfter(_start)) {
                    return;
                  }
                  Navigator.of(context).pop(<String, dynamic>{
                    'title': _title.text.trim(),
                    'jurisdiction': _jurisdiction.text.trim(),
                    'description': _description.text.trim(),
                    'starts_at': _start.toUtc().toIso8601String(),
                    'ends_at': _end.toUtc().toIso8601String(),
                    'requires_mfa': _requiresMfa,
                    'status': 'upcoming',
                    'is_public': false,
                  });
                },
                child: const Text('Create draft election'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateContestSheet extends StatefulWidget {
  const _CreateContestSheet({required this.election});

  final Election election;

  @override
  State<_CreateContestSheet> createState() => _CreateContestSheetState();
}

class _CreateContestSheetState extends State<_CreateContestSheet> {
  final _title = TextEditingController();
  final _instructions = TextEditingController(text: 'Choose one option.');
  ContestType _type = ContestType.singleChoice;

  @override
  void dispose() {
    _title.dispose();
    _instructions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.viewInsetsOf(context).bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Add contest',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Contest title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _instructions,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Instructions'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ContestType>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Contest type'),
            items: const <DropdownMenuItem<ContestType>>[
              DropdownMenuItem(value: ContestType.singleChoice, child: Text('Single choice')),
              DropdownMenuItem(value: ContestType.referendum, child: Text('Yes / no referendum')),
            ],
            onChanged: (value) => setState(() => _type = value ?? ContestType.singleChoice),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              if (_title.text.trim().isEmpty) return;
              Navigator.of(context).pop(<String, dynamic>{
                'election_id': widget.election.id,
                'title': _title.text.trim(),
                'instructions': _instructions.text.trim(),
                'contest_type': _type.databaseValue,
                'position': 0,
                'is_required': true,
              });
            },
            child: const Text('Add contest'),
          ),
        ],
      ),
    );
  }
}

class _CreateCandidateSheet extends StatefulWidget {
  const _CreateCandidateSheet({required this.election, required this.contests});

  final Election election;
  final List<BallotContest> contests;

  @override
  State<_CreateCandidateSheet> createState() => _CreateCandidateSheetState();
}

class _CreateCandidateSheetState extends State<_CreateCandidateSheet> {
  final _name = TextEditingController();
  final _party = TextEditingController();
  final _abbreviation = TextEditingController();
  final _manifesto = TextEditingController();
  String? _contestId;

  @override
  void dispose() {
    _name.dispose();
    _party.dispose();
    _abbreviation.dispose();
    _manifesto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.viewInsetsOf(context).bottom + 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Add candidate or option',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _contestId,
              decoration: const InputDecoration(labelText: 'Contest'),
              items: <DropdownMenuItem<String>>[
                for (final contest in widget.contests)
                  DropdownMenuItem(value: contest.id, child: Text(contest.title)),
              ],
              onChanged: (value) => setState(() => _contestId = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Candidate or option name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _party,
              decoration: const InputDecoration(labelText: 'Party / option group'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _abbreviation,
              decoration: const InputDecoration(labelText: 'Abbreviation'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _manifesto,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Platform / option description'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (_contestId == null || _name.text.trim().isEmpty) return;
                Navigator.of(context).pop(<String, dynamic>{
                  'election_id': widget.election.id,
                  'contest_id': _contestId,
                  'full_name': _name.text.trim(),
                  'party_name': _party.text.trim(),
                  'party_abbreviation': _abbreviation.text.trim(),
                  'manifesto': _manifesto.text.trim(),
                  'accent_color': '#1D5FD0',
                  'ballot_position': 0,
                });
              },
              child: const Text('Add to ballot'),
            ),
          ],
        ),
      ),
    );
  }
}

String _auditLabel(String eventType) => switch (eventType) {
  'voter_verification_updated' => 'Voter verification updated',
  'voter_assigned_to_election' => 'Voter ballot assignment updated',
  'election_created' => 'Election created',
  'election_updated' => 'Election updated',
  'contest_created' => 'Contest created',
  'candidate_created' => 'Candidate added',
  'ballot_submitted' => 'Ballot submission recorded',
  _ => eventType.replaceAll('_', ' '),
};

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    for (final item in this) {
      return item;
    }
    return null;
  }
}
