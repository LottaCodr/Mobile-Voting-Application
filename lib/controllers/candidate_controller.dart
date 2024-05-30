import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_voting_application/models/candidate_model.dart';
import 'package:mobile_voting_application/models/election_model.dart';

import 'election_controller.dart';

class CandidateController extends GetxController {
  final Candidate? candidate;
  final ElectionController electionController = Get.find<ElectionController>();

  CandidateController(this.candidate);

  @override
  void onInit() {
    super.onInit();
    votes.value = candidate!.votes;
    totalLiveVote.value = presidentialElection.totalVotes;
    // isVoted.value = electionController.isVOtedCandidate(candidate!);
  }

  var isVoted = false.obs; //using the obs for reactive state
  var votes = 0.obs;
  var totalLiveVote = 0.obs;

  // @override
  // void onInit() {
  //   super.onInit();
  //   votes.value = candidate!.votes;
  // }

  void makeVote() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!isVoted.value) {
      candidate!.votes++;
      votes.value = candidate!.votes;
      presidentialElection.totalVotes++;
      isVoted.value = true;

      // electionController.voteForCandidate(candidate!);
      print('You have voted for ${candidate?.name}');

      Get.snackbar(
          'Vote Counted', 'Vote submitted successfully for  ${candidate?.name}',
          backgroundColor: Colors.green, colorText: Colors.white);

      update();
    }
  }

  void cancelVote() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (isVoted.value) {
      candidate!.votes--;
      votes.value = candidate!.votes;
      presidentialElection.totalVotes--;
      isVoted.value = false;
      // electionController.cancelVote();
      print('Cancelled vote for ${candidate?.name}');

      Get.snackbar('Cancelled Vote', 'Cancelled for ${candidate?.name} ',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          isDismissible: true);

      update();
    }
  }

  String votersCount() {
    int voters = candidate!.votes;
    if (voters < 1000) {
      return '$voters';
    } else {
      return '${(voters / 1000).toStringAsFixed(1)}k';
    }
  }
}
