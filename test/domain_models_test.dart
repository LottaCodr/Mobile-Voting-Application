import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_voting_application/domain/models.dart';

void main() {
  test('candidate initials and election submission state map safely', () {
    final candidate = Candidate(
      id: 'candidate',
      electionId: 'election',
      contestId: 'contest',
      fullName: 'Amara Okafor',
      partyName: 'Forward Riverside',
      partyAbbreviation: 'FR',
      manifesto: 'A fictional platform.',
      accentColor: '#1D5FD0',
      ballotPosition: 1,
    );
    final election = Election.fromMap(<String, dynamic>{
      'id': 'election',
      'title': 'Example election',
      'description': 'Example',
      'jurisdiction': 'Example borough',
      'status': 'live',
      'starts_at': '2026-08-09T08:00:00Z',
      'ends_at': '2026-08-10T08:00:00Z',
      'registered_voters': 100,
      'results_visible': true,
      'is_public': true,
      'requires_mfa': true,
      'contest_count': 2,
      'submission_state': 'eligible',
    });

    expect(candidate.initials, 'AO');
    expect(election.canSubmit, isTrue);
    expect(election.contestCount, 2);
    expect(election.requiresMfa, isTrue);
  });

  test('submission status does not contain a candidate choice', () {
    final status = BallotSubmissionStatus.fromMap(<String, dynamic>{
      'election_id': 'election',
      'submission_state': 'submitted',
      'requires_mfa': true,
      'receipt_code': 'SAFE-RECEIPT',
      'submitted_at': '2026-08-09T10:00:00Z',
    });

    expect(status.hasSubmitted, isTrue);
    expect(status.receiptCode, 'SAFE-RECEIPT');
  });
}
