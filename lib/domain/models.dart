/// Domain objects shared by the interface and data layer.
///
/// The models intentionally do not expose a voter-to-candidate relationship.
/// A ballot is private; the app only receives a short confirmation receipt
/// after a database-side vote transaction succeeds.

enum ElectionStatus {
  upcoming,
  live,
  completed,
  unknown;

  static ElectionStatus fromDatabase(Object? value) {
    switch (value?.toString().toLowerCase()) {
      case 'upcoming':
        return ElectionStatus.upcoming;
      case 'live':
      case 'open':
        return ElectionStatus.live;
      case 'completed':
      case 'closed':
        return ElectionStatus.completed;
      default:
        return ElectionStatus.unknown;
    }
  }

  String get label {
    switch (this) {
      case ElectionStatus.upcoming:
        return 'Upcoming';
      case ElectionStatus.live:
        return 'Open now';
      case ElectionStatus.completed:
        return 'Completed';
      case ElectionStatus.unknown:
        return 'Status unavailable';
    }
  }
}

enum VerificationStatus {
  pending,
  verified,
  rejected,
  unknown;

  static VerificationStatus fromDatabase(Object? value) {
    switch (value?.toString().toLowerCase()) {
      case 'pending':
        return VerificationStatus.pending;
      case 'verified':
        return VerificationStatus.verified;
      case 'rejected':
        return VerificationStatus.rejected;
      default:
        return VerificationStatus.unknown;
    }
  }

  String get label {
    switch (this) {
      case VerificationStatus.pending:
        return 'Verification pending';
      case VerificationStatus.verified:
        return 'Verified voter';
      case VerificationStatus.rejected:
        return 'Verification needs attention';
      case VerificationStatus.unknown:
        return 'Profile status unavailable';
    }
  }
}

class Election {
  const Election({
    required this.id,
    required this.title,
    required this.description,
    required this.jurisdiction,
    required this.status,
    required this.startsAt,
    required this.endsAt,
    required this.registeredVoters,
    required this.resultsVisible,
  });

  final String id;
  final String title;
  final String description;
  final String jurisdiction;
  final ElectionStatus status;
  final DateTime startsAt;
  final DateTime endsAt;
  final int registeredVoters;
  final bool resultsVisible;

  bool get isOpen => status == ElectionStatus.live;

  factory Election.fromMap(Map<String, dynamic> map) {
    return Election(
      id: _string(map['id']),
      title: _string(map['title']),
      description: _string(map['description']),
      jurisdiction: _string(map['jurisdiction']),
      status: ElectionStatus.fromDatabase(map['status']),
      startsAt: _date(map['starts_at']),
      endsAt: _date(map['ends_at']),
      registeredVoters: _integer(map['registered_voters']),
      resultsVisible: map['results_visible'] == true,
    );
  }
}

class Candidate {
  const Candidate({
    required this.id,
    required this.electionId,
    required this.fullName,
    required this.partyName,
    required this.partyAbbreviation,
    required this.manifesto,
    required this.accentColor,
    required this.ballotPosition,
  });

  final String id;
  final String electionId;
  final String fullName;
  final String partyName;
  final String partyAbbreviation;
  final String manifesto;
  final String accentColor;
  final int ballotPosition;

  String get initials {
    final words = fullName.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return '${words.first.substring(0, 1)}${words.last.substring(0, 1)}'.toUpperCase();
  }

  factory Candidate.fromMap(Map<String, dynamic> map) {
    return Candidate(
      id: _string(map['id']),
      electionId: _string(map['election_id']),
      fullName: _string(map['full_name']),
      partyName: _string(map['party_name']),
      partyAbbreviation: _string(map['party_abbreviation']),
      manifesto: _string(map['manifesto']),
      accentColor: _string(map['accent_color'], fallback: '#1D5FD0'),
      ballotPosition: _integer(map['ballot_position']),
    );
  }
}

class ElectionResult {
  const ElectionResult({
    required this.electionId,
    required this.candidateId,
    required this.fullName,
    required this.partyName,
    required this.partyAbbreviation,
    required this.accentColor,
    required this.votes,
    required this.totalVotes,
    required this.rank,
  });

  final String electionId;
  final String candidateId;
  final String fullName;
  final String partyName;
  final String partyAbbreviation;
  final String accentColor;
  final int votes;
  final int totalVotes;
  final int rank;

  double get percentage => totalVotes == 0 ? 0 : votes / totalVotes;

  factory ElectionResult.fromMap(Map<String, dynamic> map) {
    return ElectionResult(
      electionId: _string(map['election_id']),
      candidateId: _string(map['candidate_id']),
      fullName: _string(map['full_name']),
      partyName: _string(map['party_name']),
      partyAbbreviation: _string(map['party_abbreviation']),
      accentColor: _string(map['accent_color'], fallback: '#1D5FD0'),
      votes: _integer(map['votes']),
      totalVotes: _integer(map['total_votes']),
      rank: _integer(map['rank']),
    );
  }
}

class VoteReceipt {
  const VoteReceipt({required this.code, required this.castAt});

  final String code;
  final DateTime castAt;

  factory VoteReceipt.fromMap(Map<String, dynamic> map) {
    return VoteReceipt(code: _string(map['receipt_code']), castAt: _date(map['cast_at']));
  }
}

class AppUser {
  const AppUser({required this.id, required this.email, required this.displayName});

  final String id;
  final String email;
  final String displayName;
}

class VoterProfile {
  const VoterProfile({
    required this.id,
    required this.displayName,
    required this.voterReference,
    required this.verificationStatus,
    required this.jurisdiction,
  });

  final String id;
  final String displayName;
  final String? voterReference;
  final VerificationStatus verificationStatus;
  final String? jurisdiction;

  bool get isVerified => verificationStatus == VerificationStatus.verified;

  factory VoterProfile.fromMap(Map<String, dynamic> map) {
    return VoterProfile(
      id: _string(map['id']),
      displayName: _string(map['display_name'], fallback: 'Voter'),
      voterReference: _nullableString(map['voter_reference']),
      verificationStatus: VerificationStatus.fromDatabase(map['verification_status']),
      jurisdiction: _nullableString(map['jurisdiction']),
    );
  }
}

String _string(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

int _integer(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime _date(Object? value) {
  if (value is DateTime) return value.toLocal();
  return DateTime.tryParse(value?.toString() ?? '')?.toLocal() ?? DateTime.now();
}
