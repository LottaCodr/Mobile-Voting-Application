import 'package:flutter_riverpod/flutter_riverpod.dart';

// Notifier to manage selected candidates for each election
class ElectionNotifier extends Notifier<Map<int, int>> {
  @override
  Map<int, int> build() => <int, int>{};

  // Method to select a candidate in a category
  void selectCandidate(int electionId, int candidateId) {
    state = <int, int>{...state, electionId: candidateId};
  }

  // Method to check if a candidate is currently selected
  bool isCandidateSelected(int electionId, int candidateId) {
    return state[electionId] == candidateId;
  }
}

final electionProvider = NotifierProvider<ElectionNotifier, Map<int, int>>(
  ElectionNotifier.new,
);
