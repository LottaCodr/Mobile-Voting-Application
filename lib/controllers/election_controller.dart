import 'package:get/get.dart';

class ElectionController extends GetxController {
  final selectedCandidateId = <int, int>{}.obs;

  void selectCandidate(int electionId, int candidateId) {
    if (selectedCandidateId[electionId] == candidateId) {
      selectedCandidateId[electionId] = -1; //Deselect if already selected
    } else {
      selectedCandidateId[electionId] = candidateId;
    }
    update();
  }

  bool isCandidateSelected(int electionId, int candidateId) {
    return selectedCandidateId[electionId] == candidateId;
  }
}
