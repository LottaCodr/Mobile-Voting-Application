import 'package:flutter/material.dart';
// import 'package:get/get.dart';
import 'package:mobile_voting_application/data/models/candidate_model.dart';
import 'package:mobile_voting_application/presentation/screens/candidate_screen.dart';
import '../utilities/colors.dart';

class ElectionCard extends StatelessWidget {
  final Candidate candidate;
  final bool isVoted;
  final VoidCallback onVoteToggle;

  const ElectionCard({
    super.key,
    required this.candidate,
    required this.isVoted,
    required this.onVoteToggle,
  });

  @override
  Widget build(BuildContext context) {
    String votersCount() {
      int voters = candidate.votes;
      return voters < 1000 ? '$voters' : '${(voters / 1000).toStringAsFixed(1)} k';
    }

    void onPressedMandate() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CandidateScreen(candidate: candidate),
        ),
      );
      print('Reading mandate of candidate');
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(16),
      width: MediaQuery.of(context).size.width,
      height: 170,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8.0,
            spreadRadius: 0.0,
            offset: const Offset(0, 4),
          )
        ],
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MVAColors.primaryColor, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipOval(
                clipBehavior: Clip.hardEdge,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                  child: Image(
                    fit: BoxFit.cover,
                    alignment: Alignment.topRight,
                    image: AssetImage(candidate.imageUrl),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      child: Text(
                        candidate.name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          color: MVAColors.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        FittedBox(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: ClipOval(
                              child: Image.asset(
                                candidate.partyImage,
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FittedBox(
                          child: Row(
                            children: [
                              Text(
                                votersCount(),
                                style: const TextStyle(
                                  color: MVAColors.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Text(
                                ' People Voted',
                                style: TextStyle(
                                  color: MVAColors.textColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElectionButton(
                  candidateName: candidate.name,
                  buttonName: 'Mandate',
                  onPressed: onPressedMandate,
                  icon: Icons.gavel,
                  bgColor: Colors.white,
                  borderColor: MVAColors.primaryColor,
                  textColor: MVAColors.primaryColor,
                  iconColor: MVAColors.primaryColor,
                ),
                const SizedBox(width: 6),
                ElectionButton(
                  candidateName: candidate.name,
                  buttonName: isVoted ? 'Voted' : 'Vote Now',
                  onPressed: onVoteToggle,
                  icon: isVoted ? Icons.check : Icons.how_to_vote,
                  bgColor: isVoted ? Colors.grey : MVAColors.primaryColor,
                  borderColor: Colors.transparent,
                  textColor: Colors.white,
                  iconColor: Colors.white,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class ElectionButton extends StatelessWidget {
  const ElectionButton({
    super.key,
    required this.candidateName,
    required this.buttonName,
    required this.onPressed,
    required this.icon,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.iconColor,
  });

  final String candidateName;
  final String buttonName;
  final IconData icon;
  final VoidCallback onPressed;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 1.7,
          backgroundColor: bgColor,
          side: BorderSide(color: borderColor),
          textStyle: const TextStyle(color: Colors.white),
        ),
        child: Row(
          children: [
            FittedBox(
              child: Text(
                buttonName,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
