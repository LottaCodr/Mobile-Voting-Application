import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models.dart';

class RepositoryFailure implements Exception {
  const RepositoryFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class VotingRepository {
  Future<List<Election>> loadElections();
  Future<List<BallotContest>> loadContests(String electionId);
  Future<List<Candidate>> loadCandidates(String electionId, {String? contestId});
  Future<List<ElectionResult>> loadResults(String electionId);
  Stream<List<ElectionResult>> watchResults(String electionId);
  Future<VoterProfile?> loadProfile(String userId);
  Future<BallotSubmissionStatus> loadSubmissionStatus(String electionId);
  Future<VoteReceipt> submitBallot({
    required String electionId,
    required List<BallotChoice> choices,
  });
  Future<List<AppRole>> loadMyRoles();
  Future<NotificationPreferences> loadNotificationPreferences();
  Future<void> saveNotificationPreferences(NotificationPreferences preferences);
  Future<List<AppNotification>> loadNotifications();
  Stream<List<AppNotification>> watchNotifications();
  Future<void> markNotificationRead(String notificationId);
  Future<AdminMetrics> loadAdminMetrics();
  Future<List<AuditEvent>> loadRecentAuditEvents();
  Future<List<Election>> loadManagedElections();
  Future<List<AdminVoter>> loadPendingVoters();
  Future<void> setVoterVerification({
    required String voterId,
    required VerificationStatus status,
    String? jurisdiction,
    String? maskedReference,
  });
  Future<void> assignVoterToElection({required String voterId, required String electionId});
  Future<Election> createElection(Map<String, dynamic> payload);
  Future<void> updateElection(Map<String, dynamic> payload);
  Future<BallotContest> createContest(Map<String, dynamic> payload);
  Future<Candidate> createCandidate(Map<String, dynamic> payload);
}

/// The Supabase implementation deliberately exposes only safe query paths.
///
/// - Personal eligibility/submission state comes from security-definer RPCs.
/// - A ballot is posted as a whole through `submit_ballot`.
/// - The RPC writes voter-free anonymous vote rows and stores only a receipt on
///   the voter/election assignment.
/// - The UI never queries raw ballots or a voter-to-candidate mapping.
class SupabaseVotingRepository implements VotingRepository {
  SupabaseVotingRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Election>> loadElections() async {
    try {
      final response = await _client.rpc('get_my_elections');
      return _rows(response).map(Election.fromMap).toList();
    } on PostgrestException catch (error) {
      throw RepositoryFailure(_readMessage(error));
    } catch (_) {
      throw const RepositoryFailure('Election information is unavailable right now.');
    }
  }

  @override
  Future<List<BallotContest>> loadContests(String electionId) async {
    try {
      final response = await _client
          .from('contests')
          .select('id,election_id,title,instructions,contest_type,seats,position,is_required')
          .eq('election_id', electionId)
          .order('position', ascending: true);
      return _rows(response).map(BallotContest.fromMap).toList();
    } on PostgrestException catch (error) {
      throw RepositoryFailure(_readMessage(error));
    } catch (_) {
      throw const RepositoryFailure('Ballot contests are unavailable right now.');
    }
  }

  @override
  Future<List<Candidate>> loadCandidates(String electionId, {String? contestId}) async {
    try {
      const columns =
          'id,election_id,contest_id,full_name,party_name,party_abbreviation,'
          'manifesto,accent_color,ballot_position';
      final response = contestId == null
          ? await _client
                .from('candidates')
                .select(columns)
                .eq('election_id', electionId)
                .order('ballot_position', ascending: true)
          : await _client
                .from('candidates')
                .select(columns)
                .eq('election_id', electionId)
                .eq('contest_id', contestId)
                .order('ballot_position', ascending: true);
      return _rows(response).map(Candidate.fromMap).toList();
    } on PostgrestException catch (error) {
      throw RepositoryFailure(_readMessage(error));
    } catch (_) {
      throw const RepositoryFailure('Candidate information is unavailable right now.');
    }
  }

  @override
  Future<List<ElectionResult>> loadResults(String electionId) async {
    try {
      final response = await _client
          .from('election_results')
          .select(
            'election_id,contest_id,contest_title,candidate_id,full_name,party_name,'
            'party_abbreviation,accent_color,votes,total_votes,rank',
          )
          .eq('election_id', electionId)
          .order('contest_id', ascending: true)
          .order('rank', ascending: true);
      return _rows(response).map(ElectionResult.fromMap).toList();
    } on PostgrestException catch (error) {
      throw RepositoryFailure(_readMessage(error));
    } catch (_) {
      throw const RepositoryFailure('Results are unavailable right now.');
    }
  }

  @override
  Stream<List<ElectionResult>> watchResults(String electionId) {
    try {
      return _client
          .from('result_snapshots')
          .stream(primaryKey: <String>['candidate_id'])
          .eq('election_id', electionId)
          .map((rows) => _rankSnapshotRows(_rows(rows)));
    } catch (_) {
      return Stream<List<ElectionResult>>.error(
        const RepositoryFailure('Live result updates are unavailable right now.'),
      );
    }
  }

  @override
  Future<VoterProfile?> loadProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('id,display_name,voter_reference,verification_status,jurisdiction')
          .eq('id', userId)
          .maybeSingle();
      if (response == null) return null;
      return VoterProfile.fromMap(Map<String, dynamic>.from(response));
    } on PostgrestException catch (error) {
      throw RepositoryFailure(_readMessage(error));
    } catch (_) {
      throw const RepositoryFailure('Your voter profile is unavailable right now.');
    }
  }

  @override
  Future<BallotSubmissionStatus> loadSubmissionStatus(String electionId) async {
    try {
      final response = await _client.rpc(
        'get_my_ballot_status',
        params: <String, dynamic>{'p_election_id': electionId},
      );
      final row = _rows(response).firstOrNull;
      if (row == null) {
        return BallotSubmissionStatus(
          electionId: electionId,
          state: SubmissionState.unavailable,
          requiresMfa: false,
        );
      }
      return BallotSubmissionStatus.fromMap(row);
    } on PostgrestException catch (error) {
      throw RepositoryFailure(_readMessage(error));
    } catch (_) {
      throw const RepositoryFailure('Your ballot status is unavailable right now.');
    }
  }

  @override
  Future<VoteReceipt> submitBallot({
    required String electionId,
    required List<BallotChoice> choices,
  }) async {
    try {
      final response = await _client.rpc(
        'submit_ballot',
        params: <String, dynamic>{
          'p_election_id': electionId,
          'p_choices': choices.map((choice) => choice.toJson()).toList(),
        },
      );
      final row = _rows(response).firstOrNull;
      if (row == null) {
        throw const RepositoryFailure('The voting service did not return a receipt.');
      }
      return VoteReceipt.fromMap(row);
    } on RepositoryFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw RepositoryFailure(_voteMessage(error));
    } catch (_) {
      throw const RepositoryFailure(
        'Your ballot could not be submitted. Check your connection before trying again.',
      );
    }
  }

  @override
  Future<List<AppRole>> loadMyRoles() async {
    try {
      final response = await _client.rpc('get_my_roles');
      return _rows(
        response,
      ).map((row) => AppRole.fromDatabase(row['role'])).whereType<AppRole>().toList();
    } catch (_) {
      return const <AppRole>[];
    }
  }

  @override
  Future<NotificationPreferences> loadNotificationPreferences() async {
    try {
      final response = await _client.rpc('get_my_notification_preferences');
      final row = _rows(response).firstOrNull;
      return row == null
          ? const NotificationPreferences(
              electionReminders: true,
              verificationUpdates: true,
              resultsUpdates: true,
            )
          : NotificationPreferences.fromMap(row);
    } on PostgrestException catch (error) {
      throw RepositoryFailure(_readMessage(error));
    } catch (_) {
      throw const RepositoryFailure('Notification preferences are unavailable right now.');
    }
  }

  @override
  Future<void> saveNotificationPreferences(NotificationPreferences preferences) async {
    try {
      await _client.rpc(
        'set_my_notification_preferences',
        params: <String, dynamic>{'p_preferences': preferences.toMap()},
      );
    } on PostgrestException catch (error) {
      throw RepositoryFailure(_readMessage(error));
    } catch (_) {
      throw const RepositoryFailure('Your notification preferences could not be saved.');
    }
  }

  @override
  Future<List<AppNotification>> loadNotifications() async {
    try {
      final response = await _client
          .from('notifications')
          .select('id,title,body,notification_type,created_at,read_at,action_route')
          .order('created_at', ascending: false)
          .limit(50);
      return _rows(response).map(AppNotification.fromMap).toList();
    } on PostgrestException catch (error) {
      throw RepositoryFailure(_readMessage(error));
    } catch (_) {
      throw const RepositoryFailure('Notifications are unavailable right now.');
    }
  }

  @override
  Stream<List<AppNotification>> watchNotifications() {
    try {
      return _client.from('notifications').stream(primaryKey: <String>['id']).map((rows) {
        final notifications = _rows(rows).map(AppNotification.fromMap).toList();
        notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return notifications;
      });
    } catch (_) {
      return Stream<List<AppNotification>>.error(
        const RepositoryFailure('Live notifications are unavailable right now.'),
      );
    }
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _client.rpc(
        'mark_notification_read',
        params: <String, dynamic>{'p_notification_id': notificationId},
      );
    } on PostgrestException catch (error) {
      throw RepositoryFailure(_readMessage(error));
    } catch (_) {
      throw const RepositoryFailure('The notification could not be marked as read.');
    }
  }

  @override
  Future<AdminMetrics> loadAdminMetrics() async {
    try {
      final response = await _client.rpc('admin_dashboard_metrics');
      final row = _rows(response).firstOrNull;
      if (row == null) throw const RepositoryFailure('No administrative metrics were returned.');
      return AdminMetrics.fromMap(row);
    } on RepositoryFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw RepositoryFailure(_readMessage(error));
    } catch (_) {
      throw const RepositoryFailure('Administrative metrics are unavailable right now.');
    }
  }

  @override
  Future<List<AuditEvent>> loadRecentAuditEvents() async {
    try {
      final response = await _client.rpc('admin_recent_audit_events');
      return _rows(response).map(AuditEvent.fromMap).toList();
    } on PostgrestException catch (error) {
      throw RepositoryFailure(_readMessage(error));
    } catch (_) {
      throw const RepositoryFailure('Recent audit activity is unavailable right now.');
    }
  }

  @override
  Future<List<Election>> loadManagedElections() async {
    try {
      final response = await _client
          .from('elections')
          .select(
            'id,title,description,jurisdiction,status,starts_at,ends_at,'
            'registered_voters,results_visible,is_public,requires_mfa',
          )
          .order('starts_at', ascending: true);
      return _rows(response).map(Election.fromMap).toList();
    } on PostgrestException catch (error) {
      throw RepositoryFailure(_readMessage(error));
    } catch (_) {
      throw const RepositoryFailure('Managed elections are unavailable right now.');
    }
  }

  @override
  Future<List<AdminVoter>> loadPendingVoters() async {
    try {
      final response = await _client.rpc('admin_pending_voters');
      return _rows(response).map(AdminVoter.fromMap).toList();
    } on PostgrestException catch (error) {
      throw RepositoryFailure(_readMessage(error));
    } catch (_) {
      throw const RepositoryFailure('The verification queue is unavailable right now.');
    }
  }

  @override
  Future<void> setVoterVerification({
    required String voterId,
    required VerificationStatus status,
    String? jurisdiction,
    String? maskedReference,
  }) async {
    try {
      await _client.rpc(
        'admin_set_voter_verification',
        params: <String, dynamic>{
          'p_voter_id': voterId,
          'p_verification_status': status.name,
          'p_jurisdiction': jurisdiction,
          'p_masked_reference': maskedReference,
        },
      );
    } on PostgrestException catch (error) {
      throw RepositoryFailure(_readMessage(error));
    } catch (_) {
      throw const RepositoryFailure('The voter verification update could not be saved.');
    }
  }

  @override
  Future<void> assignVoterToElection({required String voterId, required String electionId}) async {
    try {
      await _client.rpc(
        'admin_assign_voter_to_election',
        params: <String, dynamic>{'p_voter_id': voterId, 'p_election_id': electionId},
      );
    } on PostgrestException catch (error) {
      throw RepositoryFailure(_readMessage(error));
    } catch (_) {
      throw const RepositoryFailure('The voter could not be assigned to this election.');
    }
  }

  @override
  Future<Election> createElection(Map<String, dynamic> payload) async {
    try {
      final response = await _client.rpc(
        'admin_create_election',
        params: <String, dynamic>{'p_election': payload},
      );
      final row = _rows(response).firstOrNull;
      if (row == null) throw const RepositoryFailure('The election could not be created.');
      return Election.fromMap(row);
    } on RepositoryFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw RepositoryFailure(_readMessage(error));
    } catch (_) {
      throw const RepositoryFailure('The election could not be created.');
    }
  }

  @override
  Future<void> updateElection(Map<String, dynamic> payload) async {
    try {
      await _client.rpc('admin_update_election', params: <String, dynamic>{'p_election': payload});
    } on PostgrestException catch (error) {
      throw RepositoryFailure(_readMessage(error));
    } catch (_) {
      throw const RepositoryFailure('The election update could not be saved.');
    }
  }

  @override
  Future<BallotContest> createContest(Map<String, dynamic> payload) async {
    try {
      final response = await _client.rpc(
        'admin_create_contest',
        params: <String, dynamic>{'p_contest': payload},
      );
      final row = _rows(response).firstOrNull;
      if (row == null) throw const RepositoryFailure('The contest could not be created.');
      return BallotContest.fromMap(row);
    } on RepositoryFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw RepositoryFailure(_readMessage(error));
    } catch (_) {
      throw const RepositoryFailure('The contest could not be created.');
    }
  }

  @override
  Future<Candidate> createCandidate(Map<String, dynamic> payload) async {
    try {
      final response = await _client.rpc(
        'admin_create_candidate',
        params: <String, dynamic>{'p_candidate': payload},
      );
      final row = _rows(response).firstOrNull;
      if (row == null) throw const RepositoryFailure('The candidate could not be created.');
      return Candidate.fromMap(row);
    } on RepositoryFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw RepositoryFailure(_readMessage(error));
    } catch (_) {
      throw const RepositoryFailure('The candidate could not be created.');
    }
  }

  List<Map<String, dynamic>> _rows(dynamic response) {
    if (response is List) {
      return response.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
    }
    if (response is Map) {
      return <Map<String, dynamic>>[Map<String, dynamic>.from(response)];
    }
    return const <Map<String, dynamic>>[];
  }

  List<ElectionResult> _rankSnapshotRows(List<Map<String, dynamic>> rows) {
    final byContest = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      byContest.putIfAbsent(row['contest_id'].toString(), () => <Map<String, dynamic>>[]).add(row);
    }
    final output = <ElectionResult>[];
    for (final contestRows in byContest.values) {
      contestRows.sort((a, b) {
        final byVotes = _toInt(b['votes']).compareTo(_toInt(a['votes']));
        if (byVotes != 0) return byVotes;
        return (a['full_name']?.toString() ?? '').compareTo(b['full_name']?.toString() ?? '');
      });
      final total = contestRows.fold<int>(0, (sum, row) => sum + _toInt(row['votes']));
      for (var index = 0; index < contestRows.length; index++) {
        final row = Map<String, dynamic>.from(contestRows[index]);
        row['total_votes'] = total;
        row['rank'] = index + 1;
        output.add(ElectionResult.fromMap(row));
      }
    }
    output.sort((a, b) {
      final contest = a.contestTitle.compareTo(b.contestTitle);
      return contest == 0 ? a.rank.compareTo(b.rank) : contest;
    });
    return output;
  }

  int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _readMessage(PostgrestException error) {
    return error.message.isEmpty
        ? 'The requested information is unavailable right now.'
        : error.message;
  }

  String _voteMessage(PostgrestException error) {
    final message = error.message.toLowerCase();
    if (message.contains('already submitted') || message.contains('already cast')) {
      return 'A ballot has already been recorded for this election.';
    }
    if (message.contains('not verified')) {
      return 'Your voter verification must be completed before you can vote.';
    }
    if (message.contains('mfa') || message.contains('second factor')) {
      return 'Complete your second-factor verification before submitting this ballot.';
    }
    if (message.contains('eligible') || message.contains('assignment')) {
      return 'You are not assigned to this election ballot.';
    }
    if (message.contains('not open') || message.contains('closed')) {
      return 'This election is not open for voting.';
    }
    if (message.contains('candidate') || message.contains('contest')) {
      return 'Your ballot choices do not match this election.';
    }
    return 'Your ballot could not be submitted. Please check your status before trying again.';
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
