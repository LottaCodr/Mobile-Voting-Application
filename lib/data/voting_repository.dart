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
  Future<List<Candidate>> loadCandidates(String electionId);
  Future<List<ElectionResult>> loadResults(String electionId);
  Future<VoterProfile?> loadProfile(String userId);
  Future<VoteReceipt> castVote({required String electionId, required String candidateId});
}

/// Data access for the Supabase schema in `supabase/migrations`.
///
/// There is intentionally no direct `insert` into `votes`. Votes are accepted
/// only by the database RPC, which validates the authenticated voter, election
/// window, candidate/election match, and one-vote constraint atomically.
class SupabaseVotingRepository implements VotingRepository {
  SupabaseVotingRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Election>> loadElections() async {
    try {
      final response = await _client
          .from('elections')
          .select(
            'id,title,description,jurisdiction,status,starts_at,ends_at,'
            'registered_voters,results_visible',
          )
          .eq('is_public', true)
          .order('starts_at', ascending: true);
      return _rows(response).map(Election.fromMap).toList();
    } on PostgrestException catch (error) {
      throw RepositoryFailure(_readMessage(error));
    } catch (_) {
      throw const RepositoryFailure('Election information is unavailable right now.');
    }
  }

  @override
  Future<List<Candidate>> loadCandidates(String electionId) async {
    try {
      final response = await _client
          .from('candidates')
          .select(
            'id,election_id,full_name,party_name,party_abbreviation,'
            'manifesto,accent_color,ballot_position',
          )
          .eq('election_id', electionId)
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
            'election_id,candidate_id,full_name,party_name,'
            'party_abbreviation,accent_color,votes,total_votes,rank',
          )
          .eq('election_id', electionId)
          .order('rank', ascending: true);
      return _rows(response).map(ElectionResult.fromMap).toList();
    } on PostgrestException catch (error) {
      throw RepositoryFailure(_readMessage(error));
    } catch (_) {
      throw const RepositoryFailure('Results are unavailable right now.');
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
  Future<VoteReceipt> castVote({required String electionId, required String candidateId}) async {
    try {
      final response = await _client.rpc(
        'cast_vote',
        params: <String, dynamic>{'p_election_id': electionId, 'p_candidate_id': candidateId},
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
        'Your vote could not be submitted. Please check your connection and try again.',
      );
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

  String _readMessage(PostgrestException error) {
    return error.message.isEmpty
        ? 'The requested information is unavailable right now.'
        : error.message;
  }

  String _voteMessage(PostgrestException error) {
    final message = error.message.toLowerCase();
    if (message.contains('already cast')) {
      return 'A ballot has already been recorded for this election.';
    }
    if (message.contains('not verified')) {
      return 'Your voter verification must be completed before you can vote.';
    }
    if (message.contains('not open') || message.contains('closed')) {
      return 'This election is not open for voting.';
    }
    if (message.contains('candidate')) {
      return 'That candidate is not on this election ballot.';
    }
    return 'Your vote could not be submitted. Please try again.';
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
