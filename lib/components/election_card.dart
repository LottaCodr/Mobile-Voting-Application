import 'package:flutter/material.dart';
import 'package:mobile_voting_application/models/candidate_model.dart';

import '../utilities/colors.dart';

class ElectionCard extends StatelessWidget {
  final Candidate candidate;

  const ElectionCard({
    super.key,
    required this.candidate,
  });

  @override
  Widget build(BuildContext context) {
    String votersCount() {
      int voters = 0;
      if (voters < 1000) {
        return '${candidate.votes}';
      } else {
        return '${candidate.votes} k';
      }
    }

    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        width: MediaQuery.of(context).size.width,
        height: 170,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8.0,
              spreadRadius: 0.0,
              offset: const Offset(0, 4), // Subtle shadow for depth
            )
          ],
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MVAColors.accentColor, width: 2),
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
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(16)),
                    child: Image(
                      fit: BoxFit.cover,
                      alignment: Alignment.topRight,
                      image: AssetImage(
                        candidate.imageUrl,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        child: Text(
                          candidate.name,
                          style: const TextStyle(
                              color: MVAColors.textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${candidate.votes.toString()}k',
                            style: const TextStyle(
                                color: MVAColors.textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                          const Text(
                            ' People Voted',
                            style: TextStyle(
                                color: MVAColors.textColor, fontSize: 16),
                          ),
                        ],
                      ),
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
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  ElectionButton(
                    candidateName: candidate.name,
                    buttonName: 'Vote',
                  ),
                ],
              ),
            )
          ],
        ));
  }
}

class ElectionButton extends StatelessWidget {
  const ElectionButton({
    super.key,
    required this.candidateName,
    required this.buttonName,
  });

  final String candidateName;
  final String buttonName;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Implement voting logic here (e.g., navigate to voting screen)
        print('Voted for $candidateName ');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: MVAColors.primaryColor, // Adjust button color
        textStyle: const TextStyle(color: Colors.white),
      ),
      child: Row(
        children: [
          Text(
            buttonName,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(
            width: 5,
          ),
          const Icon(
            Icons.how_to_vote_outlined,
            color: Colors.white,
          )
        ],
      ),
    );
  }
}
