import 'package:flutter_riverpod/flutter_riverpod.dart';

// StateNotifier to manage selected candidates for each election
class ElectionNotifier extends StateNotifier<Map<int, int>> {
  ElectionNotifier() : super({});

  // Method to select a candidate in a category
  void selectCandidate(int electionId, int candidateId) {
    state = {
      ...state,
      electionId: candidateId,
    };
  }

  // Method to check if a candidate is currently selected
  bool isCandidateSelected(int electionId, int candidateId) {
    return state[electionId] == candidateId;
  }
}

final electionProvider = StateNotifierProvider<ElectionNotifier, Map<int, int>>(
  (ref) => ElectionNotifier(),
);
