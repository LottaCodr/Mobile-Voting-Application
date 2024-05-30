import 'package:get/get.dart';

import 'package:mobile_voting_application/models/election_model.dart';

class ElectionController extends GetxController {
  //var votedCandidate = Rxn<Candidate>();
 // final elections = <ElectionModel>[].obs;
  final selectedCandidateId = <int, int>{}.obs;
  // //method to vote for a candidate
  // void voteForCandidate(Candidate candidate) {
  //   votedCandidate.value = candidate;
  // }

  void selectCandidate(int  electionId, int candidateId) {
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

  //Method to cancel vote for the current candidate
  // void cancelVote() {
  //   votedCandidate.value = null;
  // }

  //Method to check if a candidate is the currently voted candidate
  // bool isVOtedCandidate(Candidate candidate) {
  //   return votedCandidate.value == candidate;
  // }
}
