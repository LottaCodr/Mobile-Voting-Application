import 'package:flutter/material.dart';

class CandidateCard extends StatelessWidget {
  final String candidateName;
  final String candidateImage;
  const CandidateCard(
      {super.key, required this.candidateName, required this.candidateImage});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
              color: Colors.grey, borderRadius: BorderRadius.circular(70)),
          child: ClipOval(
            clipBehavior: Clip.hardEdge,
            child: Image.asset(
              candidateImage,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Text(
          candidateName,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ],
    );
  }
}
