import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_voting_application/state/app_state.dart';

void main() {
  test('Riverpod ballot draft keeps one choice per contest and resets per election', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(ballotDraftProvider.notifier);

    notifier.select(electionId: 'election-a', contestId: 'mayor', candidateId: 'candidate-a');
    notifier.select(electionId: 'election-a', contestId: 'referendum', candidateId: 'yes');
    notifier.select(electionId: 'election-a', contestId: 'mayor', candidateId: 'candidate-b');

    expect(container.read(ballotDraftProvider).choices, <String, String>{
      'mayor': 'candidate-b',
      'referendum': 'yes',
    });

    notifier.select(electionId: 'election-b', contestId: 'board', candidateId: 'candidate-c');

    expect(container.read(ballotDraftProvider).electionId, 'election-b');
    expect(container.read(ballotDraftProvider).choices, <String, String>{'board': 'candidate-c'});
  });
}
