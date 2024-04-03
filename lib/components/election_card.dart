import 'package:flutter/material.dart';
import 'package:mobile_voting_application/models/candidate_model.dart';

import '../utilities/colors.dart';

class ElectionCard extends StatelessWidget {
  final String candidateName;
  final String imageUrl;

  const ElectionCard({
    super.key,
    required this.candidateName,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(12),
        width: MediaQuery.of(context).size.width,
        height: 170,
        decoration: BoxDecoration(
            color: MVAColors.accentColor,
            borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipOval(
              clipBehavior: Clip.hardEdge,
              child: Container(
                width: 150,
                height: 150,
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(90)),
                child: Image(
                  fit: BoxFit.fill,
                  width: 150,
                  alignment: Alignment.topRight,
                  image: AssetImage(
                    imageUrl,
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
                  Text(
                    candidateName,
                    style: const TextStyle(
                        color: MVAColors.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                  const Row(
                    children: [
                      Text(
                        '30.4k',
                        style: TextStyle(
                            color: MVAColors.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      Text(
                        ' People Voted',
                        style:
                            TextStyle(color: MVAColors.textColor, fontSize: 16),
                      ),
                    ],
                  ),
                  const Text(
                    '',
                    style: TextStyle(
                        color: MVAColors.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                ],
              ),
            )
          ],
        ));
  }
}
