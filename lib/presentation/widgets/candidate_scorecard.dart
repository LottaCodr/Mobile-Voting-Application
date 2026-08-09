import 'package:flutter/material.dart';

import '../models/candidate_model.dart';
import 'candidate_cards.dart';

class CandidateScore extends StatelessWidget {
  final Axis axisDirection;
  const CandidateScore({
    super.key,
    required this.axisDirection,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      width: MediaQuery.of(context).size.width,
      child: ListView.builder(
          padding: const EdgeInsets.all(8),
          physics: const ScrollPhysics(),
          scrollDirection: axisDirection,
          itemCount: myCandidates.length,
          itemBuilder: (context, index) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CandidateCard(
                    candidateName: myCandidates[index].name,
                    candidateImage: myCandidates[index].imageUrl),
                const SizedBox(
                  width: 7,
                )
              ],
            );
          }),
    );
  }
}


// // AnimationConfiguration.staggeredList(
// //                           position: index,
// //                           duration: const Duration(milliseconds: 375),
// //                           child: SlideAnimation(
// //                             horizontalOffset: 200,
// //                             child: FadeInAnimation(
// //                               child: Row(
// //                                 children: [
// //                                   CandidateCard(
//                               candidateName: myCandidates[index].name,
//                               candidateImage: ''),
//                           SizedBox(
//                             width: 7,
//                           )
// //                                   )
// //                                 ],
// //                               ),
// //                             ),
// //                           ),
// //                         );