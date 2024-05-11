import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_voting_application/components/button.dart';
import 'package:mobile_voting_application/controllers/candidate_controller.dart';
import 'package:mobile_voting_application/models/candidate_model.dart';
import 'package:mobile_voting_application/utilities/colors.dart';

class CandidateScreen extends StatefulWidget {
  final Candidate candidate;
  const CandidateScreen({super.key, required this.candidate});

  @override
  State<CandidateScreen> createState() => _CandidateScreenState();
}

class _CandidateScreenState extends State<CandidateScreen> {
  bool vote = false;

  void _makeVote() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      vote = true;
    });
    print('You have voted for ${widget.candidate.name}');

    Get.snackbar('Vote Counted',
        'Vote submitted successfully for  ${widget.candidate.name}',
        backgroundColor: Colors.green, colorText: Colors.white);
  }

  void _cancelVote() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      vote = false;
    });

    print('You have voted for ${widget.candidate.name}');

    Get.snackbar('Cancelled Vote', 'Cancelled for ${widget.candidate.name} ',
        backgroundColor: MVAColors.accentColor, colorText: MVAColors.textColor);
  }

  @override
  Widget build(BuildContext context) {
    final CandidateController controller =
        Get.put(CandidateController(widget.candidate)); //Injecting controller

    return GetBuilder<CandidateController>(
      init: controller,
      builder: (controller) => Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: MVAColors.primaryColor,
          title: Text(
            widget.candidate.name,
            style: const TextStyle(fontSize: 24, color: Colors.white),
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
                          borderRadius: BorderRadius.circular(10))),
                      backgroundColor:
                          MaterialStateProperty.all(MVAColors.primaryColor))),
            )),
        body: SingleChildScrollView(
          child: SizedBox(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: MVAColors.primaryColor,
                        borderRadius: BorderRadius.circular(20)),
                    width: MediaQuery.of(context).size.width,
                    height: 300,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        widget.candidate.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [CircleAvatar(), Text(' Party Name')],
                      ),
                      Row(
                        children: [
                          Text(
                            '${widget.candidate.votes.toString()}K',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: MVAColors.primaryColor),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          const Text('People Voted')
                        ],
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Text(widget.candidate.manifesto)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
