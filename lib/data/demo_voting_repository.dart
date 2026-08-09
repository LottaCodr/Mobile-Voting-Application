import 'dart:async';

import '../domain/models.dart';
import 'voting_repository.dart';

/// A clearly labelled local preview. It is intentionally isolated from every
/// production-only policy and never activates when a configured backend fails.
class DemoVotingRepository implements VotingRepository {
  DemoVotingRepository() {
    final now = DateTime.now();
    _elections = <Election>[
      Election(
        id: 'demo-city-mayor',
        title: 'Riverside community ballot',
        description: 'A fictional multi-contest ballot used to explore the CivicVote experience.',
        jurisdiction: 'Riverside Borough',
        status: ElectionStatus.live,
        startsAt: now.subtract(const Duration(hours: 5)),
        endsAt: now.add(const Duration(days: 1, hours: 7)),
        registeredVoters: 48260,
        resultsVisible: true,
        isPublic: true,
        requiresMfa: false,
        contestCount: 2,
        submissionState: SubmissionState.eligible,
      ),
      Election(
        id: 'demo-parks-referendum',
        title: 'Neighbourhood parks referendum',
        description: 'A non-binding fictional referendum about improving green spaces.',
        jurisdiction: 'Riverside Borough',
        status: ElectionStatus.upcoming,
        startsAt: now.add(const Duration(days: 18, hours: 3)),
        endsAt: now.add(const Duration(days: 20, hours: 3)),
        registeredVoters: 48260,
        resultsVisible: false,
        isPublic: true,
        requiresMfa: false,
        contestCount: 1,
        submissionState: SubmissionState.eligible,
      ),
      Election(
        id: 'demo-library-board',
        title: 'Community library board',
        description: 'A completed fictional election demonstrating published results.',
        jurisdiction: 'Riverside Borough',
        status: ElectionStatus.completed,
        startsAt: now.subtract(const Duration(days: 31)),
        endsAt: now.subtract(const Duration(days: 29)),
        registeredVoters: 48260,
        resultsVisible: true,
        isPublic: true,
        requiresMfa: false,
        contestCount: 1,
        submissionState: SubmissionState.submitted,
      ),
    ];

    _contests = <String, List<BallotContest>>{
      'demo-city-mayor': const <BallotContest>[
        BallotContest(
          id: 'demo-mayor-contest',
          electionId: 'demo-city-mayor',
          title: 'Mayor of Riverside',
          instructions: 'Choose one candidate for mayor.',
          type: ContestType.singleChoice,
          seats: 1,
          position: 1,
          required: true,
        ),
        BallotContest(
          id: 'demo-mobility-contest',
          electionId: 'demo-city-mayor',
          title: 'Safer streets proposal',
          instructions: 'Choose one proposal for the fictional mobility plan.',
          type: ContestType.referendum,
          seats: 1,
          position: 2,
          required: true,
        ),
      ],
      'demo-parks-referendum': const <BallotContest>[
        BallotContest(
          id: 'demo-parks-contest',
          electionId: 'demo-parks-referendum',
          title: 'Fund green corridors?',
          instructions: 'Choose yes or no.',
          type: ContestType.referendum,
          seats: 1,
          position: 1,
          required: true,
        ),
      ],
      'demo-library-board': const <BallotContest>[
        BallotContest(
          id: 'demo-library-contest',
          electionId: 'demo-library-board',
          title: 'Library board representative',
          instructions: 'Choose one candidate.',
          type: ContestType.singleChoice,
          seats: 1,
          position: 1,
          required: true,
        ),
      ],
    };

    _candidates = <String, List<Candidate>>{
      'demo-city-mayor': const <Candidate>[
        Candidate(
          id: 'demo-candidate-a',
          electionId: 'demo-city-mayor',
          contestId: 'demo-mayor-contest',
          fullName: 'Amara Okafor',
          partyName: 'Forward Riverside',
          partyAbbreviation: 'FR',
          manifesto:
              'Expand reliable bus routes, publish quarterly spending updates, and protect neighbourhood services through participatory budgeting.',
          accentColor: '#1D5FD0',
          ballotPosition: 1,
        ),
        Candidate(
          id: 'demo-candidate-b',
          electionId: 'demo-city-mayor',
          contestId: 'demo-mayor-contest',
          fullName: 'Daniel Reyes',
          partyName: 'Civic Independent',
          partyAbbreviation: 'CI',
          manifesto:
              'Make planning decisions easier to follow, support small local businesses, and invest in safe walking and cycling connections.',
          accentColor: '#007C6C',
          ballotPosition: 2,
        ),
        Candidate(
          id: 'demo-candidate-c',
          electionId: 'demo-city-mayor',
          contestId: 'demo-mayor-contest',
          fullName: 'Leila Mensah',
          partyName: 'Neighbourhood Alliance',
          partyAbbreviation: 'NA',
          manifesto:
              'Prioritise affordable homes, create youth advisory panels, and put climate-resilient public spaces at the centre of every ward.',
          accentColor: '#7C3AED',
          ballotPosition: 3,
        ),
        Candidate(
          id: 'demo-mobility-yes',
          electionId: 'demo-city-mayor',
          contestId: 'demo-mobility-contest',
          fullName: 'Yes — prioritise safer streets',
          partyName: 'Referendum option',
          partyAbbreviation: 'YES',
          manifesto: 'Fund slower streets, safer crossings, and direct walking and cycling routes.',
          accentColor: '#007C6C',
          ballotPosition: 1,
        ),
        Candidate(
          id: 'demo-mobility-no',
          electionId: 'demo-city-mayor',
          contestId: 'demo-mobility-contest',
          fullName: 'No — retain the current plan',
          partyName: 'Referendum option',
          partyAbbreviation: 'NO',
          manifesto:
              'Keep the existing street programme and reconsider through the annual budget cycle.',
          accentColor: '#B42318',
          ballotPosition: 2,
        ),
      ],
      'demo-parks-referendum': const <Candidate>[
        Candidate(
          id: 'demo-parks-yes',
          electionId: 'demo-parks-referendum',
          contestId: 'demo-parks-contest',
          fullName: 'Yes — fund green corridors',
          partyName: 'Referendum option',
          partyAbbreviation: 'YES',
          manifesto:
              'Support a five-year investment plan for shaded paths and accessible public spaces.',
          accentColor: '#007C6C',
          ballotPosition: 1,
        ),
        Candidate(
          id: 'demo-parks-no',
          electionId: 'demo-parks-referendum',
          contestId: 'demo-parks-contest',
          fullName: 'No — retain current funding',
          partyName: 'Referendum option',
          partyAbbreviation: 'NO',
          manifesto:
              'Keep the current parks maintenance budget and review future capital spend annually.',
          accentColor: '#B42318',
          ballotPosition: 2,
        ),
      ],
      'demo-library-board': const <Candidate>[
        Candidate(
          id: 'demo-library-a',
          electionId: 'demo-library-board',
          contestId: 'demo-library-contest',
          fullName: 'Sofia Adeyemi',
          partyName: 'Community Readers',
          partyAbbreviation: 'CR',
          manifesto: 'A fictional completed-election candidate for UI testing.',
          accentColor: '#1D5FD0',
          ballotPosition: 1,
        ),
        Candidate(
          id: 'demo-library-b',
          electionId: 'demo-library-board',
          contestId: 'demo-library-contest',
          fullName: 'Marcus Lee',
          partyName: 'Open Shelves',
          partyAbbreviation: 'OS',
          manifesto: 'A fictional completed-election candidate for UI testing.',
          accentColor: '#B54708',
          ballotPosition: 2,
        ),
      ],
    };

    _votes = <String, int>{
      'demo-candidate-a': 12840,
      'demo-candidate-b': 11020,
      'demo-candidate-c': 9860,
      'demo-mobility-yes': 21042,
      'demo-mobility-no': 16783,
      'demo-parks-yes': 0,
      'demo-parks-no': 0,
      'demo-library-a': 16042,
      'demo-library-b': 14208,
    };
  }

  late final List<Election> _elections;
  late final Map<String, List<BallotContest>> _contests;
  late final Map<String, List<Candidate>> _candidates;
  late final Map<String, int> _votes;
  final Set<String> _submittedElectionIds = <String>{'demo-library-board'};
  final StreamController<List<AppNotification>> _notificationController =
      StreamController<List<AppNotification>>.broadcast();
  final List<AppNotification> _notifications = <AppNotification>[
    AppNotification(
      id: 'demo-notification-1',
      title: 'Your fictional ballot is open',
      body: 'Review the Riverside community ballot before the demo deadline.',
      type: 'election_open',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      readAt: null,
      actionRoute: '/ballot/demo-city-mayor',
    ),
  ];
  NotificationPreferences _preferences = const NotificationPreferences(
    electionReminders: true,
    verificationUpdates: true,
    resultsUpdates: true,
  );

  static const demoUser = AppUser(
    id: 'demo-voter',
    email: 'maya@demo.civicvote.app',
    displayName: 'Maya Chen',
  );

  static const demoProfile = VoterProfile(
    id: 'demo-voter',
    displayName: 'Maya Chen',
    voterReference: 'CV-••••-4812',
    verificationStatus: VerificationStatus.verified,
    jurisdiction: 'Riverside Borough',
  );

  @override
  Future<List<Election>> loadElections() async => List<Election>.unmodifiable(
    _elections.map(
      (election) => Election(
        id: election.id,
        title: election.title,
        description: election.description,
        jurisdiction: election.jurisdiction,
        status: election.status,
        startsAt: election.startsAt,
        endsAt: election.endsAt,
        registeredVoters: election.registeredVoters,
        resultsVisible: election.resultsVisible,
        isPublic: election.isPublic,
        requiresMfa: election.requiresMfa,
        contestCount: election.contestCount,
        submissionState: _submittedElectionIds.contains(election.id)
            ? SubmissionState.submitted
            : election.submissionState,
      ),
    ),
  );

  @override
  Future<List<BallotContest>> loadContests(String electionId) async =>
      List<BallotContest>.unmodifiable(_contests[electionId] ?? const <BallotContest>[]);

  @override
  Future<List<Candidate>> loadCandidates(String electionId, {String? contestId}) async {
    final values = _candidates[electionId] ?? const <Candidate>[];
    return List<Candidate>.unmodifiable(
      contestId == null ? values : values.where((candidate) => candidate.contestId == contestId),
    );
  }

  @override
  Future<List<ElectionResult>> loadResults(String electionId) async => _buildResults(electionId);

  @override
  Stream<List<ElectionResult>> watchResults(String electionId) async* {
    yield await _buildResults(electionId);
  }

  @override
  Future<VoterProfile?> loadProfile(String userId) async =>
      userId == demoUser.id ? demoProfile : null;

  @override
  Future<BallotSubmissionStatus> loadSubmissionStatus(String electionId) async {
    final election = _elections.where((item) => item.id == electionId).firstOrNull;
    return BallotSubmissionStatus(
      electionId: electionId,
      state: _submittedElectionIds.contains(electionId)
          ? SubmissionState.submitted
          : election?.submissionState ?? SubmissionState.unavailable,
      requiresMfa: election?.requiresMfa ?? false,
      receiptCode: _submittedElectionIds.contains(electionId) ? 'DEMO-RECORDED' : null,
      submittedAt: _submittedElectionIds.contains(electionId) ? DateTime.now() : null,
    );
  }

  @override
  Future<VoteReceipt> submitBallot({
    required String electionId,
    required List<BallotChoice> choices,
  }) async {
    final election = _elections.where((item) => item.id == electionId).firstOrNull;
    if (election == null || !election.isOpen) {
      throw const RepositoryFailure('This demonstration election is not open for voting.');
    }
    if (_submittedElectionIds.contains(electionId)) {
      throw const RepositoryFailure('A demo ballot has already been recorded for this election.');
    }
    final contests = _contests[electionId] ?? const <BallotContest>[];
    final requiredIds = contests
        .where((contest) => contest.required)
        .map((contest) => contest.id)
        .toSet();
    if (choices.map((choice) => choice.contestId).toSet().length != choices.length ||
        !choices.map((choice) => choice.contestId).toSet().containsAll(requiredIds)) {
      throw const RepositoryFailure('Choose one option in every required contest first.');
    }
    final candidates = _candidates[electionId] ?? const <Candidate>[];
    for (final choice in choices) {
      if (!candidates.any(
        (candidate) =>
            candidate.id == choice.candidateId && candidate.contestId == choice.contestId,
      )) {
        throw const RepositoryFailure('One of the selected options is not on this ballot.');
      }
    }

    _submittedElectionIds.add(electionId);
    for (final choice in choices) {
      _votes.update(choice.candidateId, (count) => count + 1);
    }
    final now = DateTime.now();
    _notifications.insert(
      0,
      AppNotification(
        id: 'demo-receipt-${now.millisecondsSinceEpoch}',
        title: 'Demo ballot recorded',
        body: 'Your fictional submission receipt is ready. It does not reveal your selections.',
        type: 'ballot_submitted',
        createdAt: now,
        readAt: null,
        actionRoute: '/profile',
      ),
    );
    _emitNotifications();
    return VoteReceipt(
      code: 'DEMO-${now.millisecondsSinceEpoch.toRadixString(36).toUpperCase()}',
      castAt: now,
    );
  }

  @override
  Future<List<AppRole>> loadMyRoles() async => const <AppRole>[];

  @override
  Future<NotificationPreferences> loadNotificationPreferences() async => _preferences;

  @override
  Future<void> saveNotificationPreferences(NotificationPreferences preferences) async {
    _preferences = preferences;
  }

  @override
  Future<List<AppNotification>> loadNotifications() async =>
      List<AppNotification>.unmodifiable(_notifications);

  @override
  Stream<List<AppNotification>> watchNotifications() {
    Future.microtask(_emitNotifications);
    return _notificationController.stream;
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    final index = _notifications.indexWhere((notification) => notification.id == notificationId);
    if (index == -1 || _notifications[index].isRead) return;
    final current = _notifications[index];
    _notifications[index] = AppNotification(
      id: current.id,
      title: current.title,
      body: current.body,
      type: current.type,
      createdAt: current.createdAt,
      readAt: DateTime.now(),
      actionRoute: current.actionRoute,
    );
    _emitNotifications();
  }

  @override
  Future<AdminMetrics> loadAdminMetrics() async =>
      throw const RepositoryFailure('Administrative tools are unavailable in the demo.');

  @override
  Future<List<AuditEvent>> loadRecentAuditEvents() async =>
      throw const RepositoryFailure('Administrative tools are unavailable in the demo.');

  @override
  Future<List<Election>> loadManagedElections() async =>
      throw const RepositoryFailure('Administrative tools are unavailable in the demo.');

  @override
  Future<List<AdminVoter>> loadPendingVoters() async =>
      throw const RepositoryFailure('Administrative tools are unavailable in the demo.');

  @override
  Future<void> setVoterVerification({
    required String voterId,
    required VerificationStatus status,
    String? jurisdiction,
    String? maskedReference,
  }) async => throw const RepositoryFailure('Administrative tools are unavailable in the demo.');

  @override
  Future<void> assignVoterToElection({required String voterId, required String electionId}) async =>
      throw const RepositoryFailure('Administrative tools are unavailable in the demo.');

  @override
  Future<Election> createElection(Map<String, dynamic> payload) async =>
      throw const RepositoryFailure('Administrative tools are unavailable in the demo.');

  @override
  Future<void> updateElection(Map<String, dynamic> payload) async =>
      throw const RepositoryFailure('Administrative tools are unavailable in the demo.');

  @override
  Future<BallotContest> createContest(Map<String, dynamic> payload) async =>
      throw const RepositoryFailure('Administrative tools are unavailable in the demo.');

  @override
  Future<Candidate> createCandidate(Map<String, dynamic> payload) async =>
      throw const RepositoryFailure('Administrative tools are unavailable in the demo.');

  Future<List<ElectionResult>> _buildResults(String electionId) async {
    final candidates = _candidates[electionId] ?? const <Candidate>[];
    final contests = _contests[electionId] ?? const <BallotContest>[];
    final output = <ElectionResult>[];
    for (final contest in contests) {
      final inContest = candidates.where((candidate) => candidate.contestId == contest.id).toList()
        ..sort((a, b) => (_votes[b.id] ?? 0).compareTo(_votes[a.id] ?? 0));
      final total = inContest.fold<int>(0, (sum, candidate) => sum + (_votes[candidate.id] ?? 0));
      for (var index = 0; index < inContest.length; index++) {
        final candidate = inContest[index];
        output.add(
          ElectionResult(
            electionId: electionId,
            contestId: contest.id,
            contestTitle: contest.title,
            candidateId: candidate.id,
            fullName: candidate.fullName,
            partyName: candidate.partyName,
            partyAbbreviation: candidate.partyAbbreviation,
            accentColor: candidate.accentColor,
            votes: _votes[candidate.id] ?? 0,
            totalVotes: total,
            rank: index + 1,
          ),
        );
      }
    }
    return output;
  }

  void _emitNotifications() {
    if (!_notificationController.isClosed) {
      _notificationController.add(List<AppNotification>.unmodifiable(_notifications));
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    for (final item in this) {
      return item;
    }
    return null;
  }
}
