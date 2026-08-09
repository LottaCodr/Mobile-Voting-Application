import '../domain/models.dart';
import 'voting_repository.dart';

/// A deliberately local, clearly labelled preview experience.
///
/// It makes the redesign explorable before a Supabase project is configured.
/// It is never selected once a configured Supabase client fails to initialize.
class DemoVotingRepository implements VotingRepository {
  DemoVotingRepository() {
    final now = DateTime.now();
    _elections = <Election>[
      Election(
        id: 'demo-city-mayor',
        title: 'Riverside mayoral election',
        description:
            'Choose one mayor for Riverside. The demonstrator ballot contains fictional candidates.',
        jurisdiction: 'Riverside Borough',
        status: ElectionStatus.live,
        startsAt: now.subtract(const Duration(hours: 5)),
        endsAt: now.add(const Duration(days: 1, hours: 7)),
        registeredVoters: 48260,
        resultsVisible: true,
      ),
      Election(
        id: 'demo-parks-referendum',
        title: 'Neighbourhood parks referendum',
        description: 'A non-binding sample referendum about improving local green spaces.',
        jurisdiction: 'Riverside Borough',
        status: ElectionStatus.upcoming,
        startsAt: now.add(const Duration(days: 18, hours: 3)),
        endsAt: now.add(const Duration(days: 20, hours: 3)),
        registeredVoters: 48260,
        resultsVisible: false,
      ),
      Election(
        id: 'demo-library-board',
        title: 'Community library board',
        description: 'A completed demonstration of how published results are presented.',
        jurisdiction: 'Riverside Borough',
        status: ElectionStatus.completed,
        startsAt: now.subtract(const Duration(days: 31)),
        endsAt: now.subtract(const Duration(days: 29)),
        registeredVoters: 48260,
        resultsVisible: true,
      ),
    ];

    _candidates = <String, List<Candidate>>{
      'demo-city-mayor': const <Candidate>[
        Candidate(
          id: 'demo-candidate-a',
          electionId: 'demo-city-mayor',
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
          fullName: 'Leila Mensah',
          partyName: 'Neighbourhood Alliance',
          partyAbbreviation: 'NA',
          manifesto:
              'Prioritise affordable homes, create youth advisory panels, and put climate-resilient public spaces at the centre of every ward.',
          accentColor: '#7C3AED',
          ballotPosition: 3,
        ),
        Candidate(
          id: 'demo-candidate-d',
          electionId: 'demo-city-mayor',
          fullName: 'Noah Patel',
          partyName: 'Riverside First',
          partyAbbreviation: 'RF',
          manifesto:
              'Strengthen emergency readiness, keep streets clean, and make essential council services simpler to access for every resident.',
          accentColor: '#B54708',
          ballotPosition: 4,
        ),
      ],
      'demo-parks-referendum': const <Candidate>[
        Candidate(
          id: 'demo-parks-yes',
          electionId: 'demo-parks-referendum',
          fullName: 'Yes — fund green corridors',
          partyName: 'Referendum option',
          partyAbbreviation: 'YES',
          manifesto:
              'Support a five-year investment plan for shaded paths, play areas, accessible benches, and native planting.',
          accentColor: '#007C6C',
          ballotPosition: 1,
        ),
        Candidate(
          id: 'demo-parks-no',
          electionId: 'demo-parks-referendum',
          fullName: 'No — retain current funding',
          partyName: 'Referendum option',
          partyAbbreviation: 'NO',
          manifesto:
              'Keep the current parks maintenance budget and review any future capital expenditure through the annual budget process.',
          accentColor: '#B42318',
          ballotPosition: 2,
        ),
      ],
      'demo-library-board': const <Candidate>[
        Candidate(
          id: 'demo-library-a',
          electionId: 'demo-library-board',
          fullName: 'Sofia Adeyemi',
          partyName: 'Community Readers',
          partyAbbreviation: 'CR',
          manifesto: 'A completed sample candidate.',
          accentColor: '#1D5FD0',
          ballotPosition: 1,
        ),
        Candidate(
          id: 'demo-library-b',
          electionId: 'demo-library-board',
          fullName: 'Marcus Lee',
          partyName: 'Open Shelves',
          partyAbbreviation: 'OS',
          manifesto: 'A completed sample candidate.',
          accentColor: '#B54708',
          ballotPosition: 2,
        ),
      ],
    };

    _votes = <String, int>{
      'demo-candidate-a': 12840,
      'demo-candidate-b': 11020,
      'demo-candidate-c': 9860,
      'demo-candidate-d': 7120,
      'demo-parks-yes': 0,
      'demo-parks-no': 0,
      'demo-library-a': 16042,
      'demo-library-b': 14208,
    };
  }

  late final List<Election> _elections;
  late final Map<String, List<Candidate>> _candidates;
  late final Map<String, int> _votes;
  final Set<String> _votedElectionIds = <String>{};

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
  Future<List<Election>> loadElections() async => List<Election>.unmodifiable(_elections);

  @override
  Future<List<Candidate>> loadCandidates(String electionId) async {
    return List<Candidate>.unmodifiable(_candidates[electionId] ?? const <Candidate>[]);
  }

  @override
  Future<List<ElectionResult>> loadResults(String electionId) async {
    final candidates = _candidates[electionId] ?? const <Candidate>[];
    final total = candidates.fold<int>(0, (sum, candidate) => sum + (_votes[candidate.id] ?? 0));
    final sorted = List<Candidate>.from(candidates)
      ..sort((a, b) => (_votes[b.id] ?? 0).compareTo(_votes[a.id] ?? 0));
    return <ElectionResult>[
      for (var index = 0; index < sorted.length; index++)
        ElectionResult(
          electionId: electionId,
          candidateId: sorted[index].id,
          fullName: sorted[index].fullName,
          partyName: sorted[index].partyName,
          partyAbbreviation: sorted[index].partyAbbreviation,
          accentColor: sorted[index].accentColor,
          votes: _votes[sorted[index].id] ?? 0,
          totalVotes: total,
          rank: index + 1,
        ),
    ];
  }

  @override
  Future<VoterProfile?> loadProfile(String userId) async {
    return userId == demoUser.id ? demoProfile : null;
  }

  @override
  Future<VoteReceipt> castVote({required String electionId, required String candidateId}) async {
    final election = _elections.where((item) => item.id == electionId).firstOrNull;
    if (election == null || !election.isOpen) {
      throw const RepositoryFailure('This demonstration election is not open for voting.');
    }
    if (!_candidates[electionId]!.any((candidate) => candidate.id == candidateId)) {
      throw const RepositoryFailure('That candidate is not on this ballot.');
    }
    if (_votedElectionIds.contains(electionId)) {
      throw const RepositoryFailure('A demo ballot has already been recorded for this election.');
    }

    _votedElectionIds.add(electionId);
    _votes.update(candidateId, (count) => count + 1);
    final now = DateTime.now();
    return VoteReceipt(
      code: 'DEMO-${now.millisecondsSinceEpoch.toRadixString(36).toUpperCase()}',
      castAt: now,
    );
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
