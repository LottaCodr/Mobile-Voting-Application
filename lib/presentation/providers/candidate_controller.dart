import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_voting_application/data/models/candidate_model.dart';
import 'package:mobile_voting_application/data/models/election_model.dart';

// import 'election_controller.dart';

class CandidateController extends GetxController {
  final Candidate? candidate;
  // final ElectionController electionController = Get.find<ElectionController>();

  CandidateController(this.candidate);

  @override
  void onInit() {
    super.onInit();
    votes.value = candidate!.votes;
    totalLiveVote.value = presidentialElection.totalVotes;
    isVoted.value = electionController.isCandidateSelected(
        candidate!.electionId, candidate!.id);
  }

  Map<String, String> selectedVotes = {};

  var isVoted = false.obs; // Using obs for reactive state
  var votes = 0.obs;
  var totalLiveVote = 0.obs;

  // Method to cast a vote, ensuring only one vote per election category
  void makeVote() async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if this candidate is already selected in the election
    if (!isVoted.value) {
      // Cancel any previous selection within this election
      int? previousVote =
          electionController.selectedCandidateId[candidate!.electionId];
      if (previousVote != null && previousVote != candidate!.id) {
        electionController.selectCandidate(
            candidate!.electionId, -1); // Deselect previous candidate
      }

      // Register the new vote
      candidate!.votes++;
      votes.value = candidate!.votes;
      presidentialElection.totalVotes++;
      isVoted.value = true;
      electionController.selectCandidate(candidate!.electionId, candidate!.id);

      Get.snackbar(
          'Vote Counted', 'Vote submitted successfully for ${candidate?.name}',
          backgroundColor: Colors.green, colorText: Colors.white);

      update();
    } else {
      // If already voted, show a message indicating duplicate attempt
      Get.snackbar('Already Voted', 'You have already voted in this election.',
          backgroundColor: Colors.blue, colorText: Colors.white);
    }
  }

  // Method to cancel an existing vote
  void cancelVote() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (isVoted.value) {
      // Adjust vote counts
      candidate!.votes--;
      votes.value = candidate!.votes;
      presidentialElection.totalVotes--;

      // Update the vote state and deselect in the election controller
      isVoted.value = false;
      electionController.selectCandidate(candidate!.electionId, -1);

      Get.snackbar('Vote Cancelled', 'Cancelled for ${candidate?.name}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          isDismissible: true);

      update();
    }
  }

  // Method to format the vote count display
  String votersCount() {
    int voters = candidate!.votes;
    if (voters < 1000) {
      return '$voters';
    } else {
      return '${(voters / 1000).toStringAsFixed(1)}k';
    }
  }
}
