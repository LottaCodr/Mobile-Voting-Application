/// Immutable domain objects shared by the presentation and data layers.
///
/// The app deliberately has no model that joins a voter identity to a candidate
/// choice. The server returns eligibility/submission metadata and aggregate
/// results, never a voter-to-candidate history.

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

  String get label => switch (this) {
    ElectionStatus.upcoming => 'Upcoming',
    ElectionStatus.live => 'Open now',
    ElectionStatus.completed => 'Completed',
    ElectionStatus.unknown => 'Status unavailable',
  };
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

  String get label => switch (this) {
    VerificationStatus.pending => 'Verification pending',
    VerificationStatus.verified => 'Verified voter',
    VerificationStatus.rejected => 'Verification needs attention',
    VerificationStatus.unknown => 'Profile status unavailable',
  };
}

enum SubmissionState {
  unavailable,
  eligible,
  submitted,
  ineligible,
  unknown;

  static SubmissionState fromDatabase(Object? value) {
    switch (value?.toString().toLowerCase()) {
      case 'eligible':
      case 'not_started':
        return SubmissionState.eligible;
      case 'submitted':
        return SubmissionState.submitted;
      case 'ineligible':
        return SubmissionState.ineligible;
      case 'unavailable':
        return SubmissionState.unavailable;
      default:
        return SubmissionState.unknown;
    }
  }

  String get label => switch (this) {
    SubmissionState.eligible => 'Ballot available',
    SubmissionState.submitted => 'Ballot submitted',
    SubmissionState.ineligible => 'Not eligible',
    SubmissionState.unavailable => 'Not assigned',
    SubmissionState.unknown => 'Status unavailable',
  };
}

enum ContestType {
  singleChoice,
  referendum,
  unknown;

  static ContestType fromDatabase(Object? value) {
    switch (value?.toString().toLowerCase()) {
      case 'single_choice':
        return ContestType.singleChoice;
      case 'referendum':
      case 'yes_no':
        return ContestType.referendum;
      default:
        return ContestType.unknown;
    }
  }

  String get databaseValue => switch (this) {
    ContestType.singleChoice => 'single_choice',
    ContestType.referendum => 'referendum',
    ContestType.unknown => 'single_choice',
  };
}

enum AppRole {
  voter,
  verifier,
  electionManager,
  auditor,
  administrator;

  static AppRole? fromDatabase(Object? value) {
    switch (value?.toString().toLowerCase()) {
      case 'voter':
        return AppRole.voter;
      case 'verifier':
        return AppRole.verifier;
      case 'election_manager':
        return AppRole.electionManager;
      case 'auditor':
        return AppRole.auditor;
      case 'administrator':
        return AppRole.administrator;
      default:
        return null;
    }
  }

  String get databaseValue => switch (this) {
    AppRole.voter => 'voter',
    AppRole.verifier => 'verifier',
    AppRole.electionManager => 'election_manager',
    AppRole.auditor => 'auditor',
    AppRole.administrator => 'administrator',
  };
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
    required this.isPublic,
    required this.requiresMfa,
    required this.contestCount,
    required this.submissionState,
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
  final bool isPublic;
  final bool requiresMfa;
  final int contestCount;
  final SubmissionState submissionState;

  bool get isOpen => status == ElectionStatus.live;
  bool get canSubmit => isOpen && submissionState == SubmissionState.eligible;
  bool get hasSubmitted => submissionState == SubmissionState.submitted;

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
      isPublic: map['is_public'] == true,
      requiresMfa: map['requires_mfa'] == true,
      contestCount: _integer(map['contest_count'], fallback: 1),
      submissionState: SubmissionState.fromDatabase(map['submission_state'] ?? map['ballot_state']),
    );
  }
}

class BallotContest {
  const BallotContest({
    required this.id,
    required this.electionId,
    required this.title,
    required this.instructions,
    required this.type,
    required this.seats,
    required this.position,
    required this.required,
  });

  final String id;
  final String electionId;
  final String title;
  final String instructions;
  final ContestType type;
  final int seats;
  final int position;
  final bool required;

  factory BallotContest.fromMap(Map<String, dynamic> map) {
    return BallotContest(
      id: _string(map['id']),
      electionId: _string(map['election_id']),
      title: _string(map['title']),
      instructions: _string(
        map['instructions'],
        fallback: 'Choose one option before submitting your ballot.',
      ),
      type: ContestType.fromDatabase(map['contest_type']),
      seats: _integer(map['seats'], fallback: 1),
      position: _integer(map['position'], fallback: 1),
      required: map['is_required'] != false,
    );
  }
}

class Candidate {
  const Candidate({
    required this.id,
    required this.electionId,
    required this.contestId,
    required this.fullName,
    required this.partyName,
    required this.partyAbbreviation,
    required this.manifesto,
    required this.accentColor,
    required this.ballotPosition,
  });

  final String id;
  final String electionId;
  final String contestId;
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
      contestId: _string(map['contest_id']),
      fullName: _string(map['full_name']),
      partyName: _string(map['party_name']),
      partyAbbreviation: _string(map['party_abbreviation']),
      manifesto: _string(map['manifesto']),
      accentColor: _string(map['accent_color'], fallback: '#1D5FD0'),
      ballotPosition: _integer(map['ballot_position']),
    );
  }
}

class BallotChoice {
  const BallotChoice({required this.contestId, required this.candidateId});

  final String contestId;
  final String candidateId;

  Map<String, String> toJson() => <String, String>{
    'contest_id': contestId,
    'candidate_id': candidateId,
  };
}

class BallotSubmissionStatus {
  const BallotSubmissionStatus({
    required this.electionId,
    required this.state,
    required this.requiresMfa,
    this.receiptCode,
    this.submittedAt,
  });

  final String electionId;
  final SubmissionState state;
  final bool requiresMfa;
  final String? receiptCode;
  final DateTime? submittedAt;

  bool get hasSubmitted => state == SubmissionState.submitted;

  factory BallotSubmissionStatus.fromMap(Map<String, dynamic> map) {
    return BallotSubmissionStatus(
      electionId: _string(map['election_id']),
      state: SubmissionState.fromDatabase(map['submission_state']),
      requiresMfa: map['requires_mfa'] == true,
      receiptCode: _nullableString(map['receipt_code']),
      submittedAt: _nullableDate(map['submitted_at']),
    );
  }
}

class ElectionResult {
  const ElectionResult({
    required this.electionId,
    required this.contestId,
    required this.contestTitle,
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
  final String contestId;
  final String contestTitle;
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
      contestId: _string(map['contest_id']),
      contestTitle: _string(map['contest_title'], fallback: 'Result'),
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
    return VoteReceipt(
      code: _string(map['receipt_code']),
      castAt: _date(map['submitted_at'] ?? map['cast_at']),
    );
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

class MfaStatus {
  const MfaStatus({
    required this.currentLevel,
    required this.nextLevel,
    required this.hasVerifiedFactor,
  });

  final String currentLevel;
  final String nextLevel;
  final bool hasVerifiedFactor;

  bool get isElevated => currentLevel.toLowerCase().contains('aal2');

  factory MfaStatus.fromValues({
    required Object? currentLevel,
    required Object? nextLevel,
    required bool hasVerifiedFactor,
  }) {
    return MfaStatus(
      currentLevel: currentLevel?.toString() ?? 'aal1',
      nextLevel: nextLevel?.toString() ?? 'aal1',
      hasVerifiedFactor: hasVerifiedFactor,
    );
  }
}

class MfaFactor {
  const MfaFactor({required this.id, required this.friendlyName, required this.status});

  final String id;
  final String friendlyName;
  final String status;

  bool get isVerified => status.toLowerCase().contains('verified');
}

class MfaEnrollment {
  const MfaEnrollment({required this.factorId, required this.qrCode, required this.secret});

  final String factorId;
  final String qrCode;
  final String secret;
}

class NotificationPreferences {
  const NotificationPreferences({
    required this.electionReminders,
    required this.verificationUpdates,
    required this.resultsUpdates,
  });

  final bool electionReminders;
  final bool verificationUpdates;
  final bool resultsUpdates;

  NotificationPreferences copyWith({
    bool? electionReminders,
    bool? verificationUpdates,
    bool? resultsUpdates,
  }) {
    return NotificationPreferences(
      electionReminders: electionReminders ?? this.electionReminders,
      verificationUpdates: verificationUpdates ?? this.verificationUpdates,
      resultsUpdates: resultsUpdates ?? this.resultsUpdates,
    );
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      electionReminders: map['election_reminders'] != false,
      verificationUpdates: map['verification_updates'] != false,
      resultsUpdates: map['results_updates'] != false,
    );
  }

  Map<String, bool> toMap() => <String, bool>{
    'election_reminders': electionReminders,
    'verification_updates': verificationUpdates,
    'results_updates': resultsUpdates,
  };
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.readAt,
    required this.actionRoute,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? actionRoute;

  bool get isRead => readAt != null;

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: _string(map['id']),
      title: _string(map['title']),
      body: _string(map['body']),
      type: _string(map['notification_type'], fallback: 'general'),
      createdAt: _date(map['created_at']),
      readAt: _nullableDate(map['read_at']),
      actionRoute: _nullableString(map['action_route']),
    );
  }
}

class AdminVoter {
  const AdminVoter({
    required this.id,
    required this.displayName,
    required this.verificationStatus,
    required this.jurisdiction,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final VerificationStatus verificationStatus;
  final String? jurisdiction;
  final DateTime createdAt;

  factory AdminVoter.fromMap(Map<String, dynamic> map) {
    return AdminVoter(
      id: _string(map['id']),
      displayName: _string(map['display_name'], fallback: 'Voter'),
      verificationStatus: VerificationStatus.fromDatabase(map['verification_status']),
      jurisdiction: _nullableString(map['jurisdiction']),
      createdAt: _date(map['created_at']),
    );
  }
}

class AuditEvent {
  const AuditEvent({
    required this.id,
    required this.eventType,
    required this.targetType,
    required this.occurredAt,
  });

  final String id;
  final String eventType;
  final String targetType;
  final DateTime occurredAt;

  factory AuditEvent.fromMap(Map<String, dynamic> map) {
    return AuditEvent(
      id: _string(map['id']),
      eventType: _string(map['event_type']),
      targetType: _string(map['target_type']),
      occurredAt: _date(map['occurred_at']),
    );
  }
}

class AdminMetrics {
  const AdminMetrics({
    required this.pendingVerifications,
    required this.liveElections,
    required this.eligibleAssignments,
    required this.submittedBallots,
  });

  final int pendingVerifications;
  final int liveElections;
  final int eligibleAssignments;
  final int submittedBallots;

  factory AdminMetrics.fromMap(Map<String, dynamic> map) {
    return AdminMetrics(
      pendingVerifications: _integer(map['pending_verifications']),
      liveElections: _integer(map['live_elections']),
      eligibleAssignments: _integer(map['eligible_assignments']),
      submittedBallots: _integer(map['submitted_ballots']),
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

int _integer(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime _date(Object? value) {
  if (value is DateTime) return value.toLocal();
  return DateTime.tryParse(value?.toString() ?? '')?.toLocal() ?? DateTime.now();
}

DateTime? _nullableDate(Object? value) {
  if (value == null) return null;
  final parsed = DateTime.tryParse(value.toString());
  return parsed?.toLocal();
}
