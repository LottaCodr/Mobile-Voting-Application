import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_voting_application/models/candidate_model.dart';
import 'package:mobile_voting_application/utilities/colors.dart';

class CandidateController extends GetxController {
  final Candidate? candidate;
  CandidateController(this.candidate);
  final RxBool isVoted = RxBool(false); //using the RxBool for reactive state

  void makeVote() async {
    await Future.delayed(const Duration(milliseconds: 500));
    isVoted.value = true;
    print(
        'You have voted for ${Get.find<CandidateController>().candidate?.name}');

    Get.snackbar('Vote Counted',
        'Vote submitted successfully for  ${Get.find<CandidateController>().candidate?.name}',
        backgroundColor: Colors.green, colorText: Colors.white);
  }

  void cancelVote() async {
    await Future.delayed(const Duration(milliseconds: 500));
    isVoted.value = false;

    print(
        'Cancelled vote for ${Get.find<CandidateController>().candidate?.name}');

    Get.snackbar('Cancelled Vote',
        'Cancelled for ${Get.find<CandidateController>().candidate?.name} ',
        backgroundColor: MVAColors.accentColor, colorText: MVAColors.textColor);
  }
}
