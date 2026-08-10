import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_voting_application/data/demo_voting_repository.dart';
import 'package:mobile_voting_application/data/voting_repository.dart';
import 'package:mobile_voting_application/domain/models.dart';

void main() {
  test('demo repository requires every required contest and returns receipt-safe status', () async {
    final repository = DemoVotingRepository();
    const electionId = 'demo-city-mayor';

    await expectLater(
      repository.submitBallot(
        electionId: electionId,
        choices: const <BallotChoice>[
          BallotChoice(contestId: 'demo-mayor-contest', candidateId: 'demo-candidate-a'),
        ],
      ),
      throwsA(isA<RepositoryFailure>()),
    );

    final receipt = await repository.submitBallot(
      electionId: electionId,
      choices: const <BallotChoice>[
        BallotChoice(contestId: 'demo-mayor-contest', candidateId: 'demo-candidate-a'),
        BallotChoice(contestId: 'demo-mobility-contest', candidateId: 'demo-mobility-yes'),
      ],
    );
    final status = await repository.loadSubmissionStatus(electionId);

    expect(receipt.code, startsWith('DEMO-'));
    expect(status.hasSubmitted, isTrue);
    expect(status.receiptCode, isNotEmpty);
  });
}
