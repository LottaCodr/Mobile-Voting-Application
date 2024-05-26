import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_voting_application/models/candidate_model.dart';

class CandidateController extends GetxController {
  final Candidate? candidate;
  CandidateController(this.candidate);

  @override
  void onInit() {
    super.onInit();
    votes.value = candidate!.votes;
  }

  var isVoted = false.obs; //using the RxBool for reactive state
  var votes = 0.obs;

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
      isVoted.value = true;
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
      isVoted.value = false;

      print('Cancelled vote for ${candidate?.name}');

      Get.snackbar('Cancelled Vote', 'Cancelled for ${candidate?.name} ',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          isDismissible: true);

      update();
    }
  }

  String votersCount() {
    int voters = votes.value;
    if (voters < 1000) {
      return '$voters';
    } else {
      return '${(voters / 1000).toStringAsFixed(1)}k';
    }
  }
}
