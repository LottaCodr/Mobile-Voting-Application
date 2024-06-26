import 'package:flutter/material.dart';
import 'package:mobile_voting_application/models/election_model.dart';

import '../../../utilities/colors.dart';

class CompletedCard extends StatelessWidget {
  final int index;
  final ElectionModel completed;
  final double currentPageValue;
  final double scaleFactor;
  final double height;
  const CompletedCard(
      {super.key,
      required this.index,
      required this.completed,
      required this.currentPageValue,
      required this.scaleFactor,
      required this.height});

  @override
  Widget build(BuildContext context) {
    Matrix4 matrix = Matrix4.identity();

    if (index == currentPageValue.floor()) {
      var currScale = 1 - (currentPageValue - index) * (1 - scaleFactor);
      var currTransformation = height * (1 - currScale);
      matrix = Matrix4.diagonal3Values(1, currScale, 1)
        ..setTranslationRaw(0, currTransformation, 0);
    } else if (index == currentPageValue.floor() + 1) {
      var currScale =
          scaleFactor + (currentPageValue - index + 1) * (1 - scaleFactor);
      var currTransformation = height * (1 - currScale);

      matrix = Matrix4.diagonal3Values(1, currScale, 1);
      matrix = Matrix4.diagonal3Values(1, currScale, 1)
        ..setTranslationRaw(0, currTransformation, 0);
    } else if (index == currentPageValue.floor() - 1) {
      var currScale = 1 - (currentPageValue - index) * (1 - scaleFactor);
      var currTransformation = height * (1 - currScale);

      matrix = Matrix4.diagonal3Values(1, currScale, 1);
      matrix = Matrix4.diagonal3Values(1, currScale, 1)
        ..setTranslationRaw(0, currTransformation, 0);
    } else {
      var currScale = 0.85;
      matrix = Matrix4.diagonal3Values(1, currScale, 1)
        ..setTranslationRaw(1, height * (1 - scaleFactor), 1);
    }

    return Transform(
      transform: matrix,
      child: Center(
        child: Stack(children: [
          Container(
            padding: const EdgeInsets.all(20),
            width: MediaQuery.of(context).size.width,
            margin: const EdgeInsets.only(left: 7, right: 7),
            height: 280,
            decoration: BoxDecoration(
                color: MVAColors.primaryColor,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                      color: MVAColors.primaryColor,
                      blurRadius: 5.0,
                      offset: Offset(5, 5)),
                  BoxShadow(
                      color: MVAColors.textColor,
                      offset: Offset(5, 5),
                      blurRadius: 4),
                ]),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadiusDirectional.circular(50)),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        const Text(
                          '2 days ago',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    //add the live below
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadiusDirectional.circular(5)),
                      width: 60,
                      height: 25,
                      child: const Center(
                        child: Text(
                          'Done',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 15,
                ),
                //ADDING THE WIDGETS FOR VOTE COUNTING HERE
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${completed.totalVotes.toString()} Votes',
                      style: const TextStyle(
                          color: MVAColors.accentColor,
                          fontSize: 32,
                          fontWeight: FontWeight.w900),
                    ),
                    Text(
                      completed.name.toString(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 29,
                ),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                      decoration: BoxDecoration(
                          color: MVAColors.accentColor,
                          borderRadius: BorderRadiusDirectional.circular(100)),
                      width: 200,
                      height: 40,
                      padding: const EdgeInsets.all(8),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            'Check Results',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: MVAColors.textColor),
                          ),
                          Icon(
                            Icons.arrow_forward_outlined,
                            color: MVAColors.primaryColor,
                          )
                        ],
                      )),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
