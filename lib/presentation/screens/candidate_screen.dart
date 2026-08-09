import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_voting_application/presentation/providers/candidate_controller.dart';
import 'package:mobile_voting_application/data/models/candidate_model.dart';
import 'package:mobile_voting_application/core/theme/colors.dart';

class CandidateScreen extends StatelessWidget {
  final Candidate candidate;
  const CandidateScreen({super.key, required this.candidate});

  @override
  Widget build(BuildContext context) {
    String votersCount() {
      int voters = candidate.votes;
      if (voters < 1000) {
        return '$voters';
      } else {
        return '${(voters / 1000).toStringAsFixed(1)} k';
      }
    }

    return GetBuilder<CandidateController>(
      init: CandidateController(candidate),
      tag: candidate.id.toString(),
      builder: (controller) => Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: MVAColors.primaryColor,
          title: Text(
            candidate.name,
            style: const TextStyle(fontSize: 28, color: Colors.white),
          ),
        ),
        bottomNavigationBar: Padding(
            padding: const EdgeInsets.only(bottom: 20.0, left: 20, right: 20),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 60,
              child: TextButton.icon(
                  onPressed: () {
                    if (controller.isVoted.value) {
                      controller.cancelVote();
                    } else {
                      controller.makeVote();
                    }
                  },
                  icon: controller.isVoted.value
                      ? const Icon(
                          Icons.check_circle,
                        )
                      : const Icon(
                          Icons.how_to_vote,
                        ),
                  label: Text(
                    controller.isVoted.value ? 'Voted' : 'Vote Now',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ButtonStyle(
                      iconSize: MaterialStateProperty.all(30),
                      textStyle: MaterialStateProperty.all(
                          const TextStyle(fontSize: 20)),
                      iconColor: MaterialStateProperty.all(Colors.white),
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32))),
                      backgroundColor:
                          MaterialStateProperty.all(MVAColors.primaryColor))),
            )),
        body: SingleChildScrollView(
          child: SizedBox(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: MVAColors.primaryColor,
                        borderRadius: BorderRadius.circular(24)),
                    width: MediaQuery.of(context).size.width,
                    height: 300,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        candidate.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  FittedBox(
                    child: Row(
                      //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(
                                width: 30,
                                height: 30,
                                child: ClipOval(
                                  child: Image.asset(
                                    candidate.partyImage,
                                    fit: BoxFit.fill,
                                  ),
                                )),
                            const SizedBox(
                              width: 8,
                            ),
                            FittedBox(
                                child: Text(candidate.partyName,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: MVAColors.textColor))),
                          ],
                        ),
                        SizedBox(
                          width: 70,
                        ),
                        Row(
                          children: [
                            Text(
                              controller.votersCount(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: MVAColors.primaryColor),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            const Text(
                              'People Voted',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Text(
                    candidate.manifesto,
                    textAlign: TextAlign.justify,
                    textHeightBehavior: const TextHeightBehavior(
                        applyHeightToFirstAscent: false),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
