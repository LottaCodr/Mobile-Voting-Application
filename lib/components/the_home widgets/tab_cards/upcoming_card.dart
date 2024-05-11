import 'package:flutter/material.dart';

import '../../../utilities/colors.dart';

class UpcomingCard extends StatelessWidget {
  final int index;
  final double currentPageValue;
  final double scaleFactor;
  final double height;
  const UpcomingCard(
      {super.key,
      required this.index,
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
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  //ADDING THE WIDGETS FOR ELECTION TYPE HERE
                  const Text(
                    'Upcoming Election:',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.normal),
                  ),

                  const Center(
                    child: Text(
                      'Students Representative Council Election',
                      style: TextStyle(
                          color: MVAColors.accentColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w600),
                    ),
                  ),

                  const SizedBox(
                    height: 29,
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                        decoration: BoxDecoration(
                            color: MVAColors.accentColor,
                            borderRadius:
                                BorderRadiusDirectional.circular(100)),
                        width: 200,
                        height: 40,
                        padding: const EdgeInsets.all(8),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Icon(
                              Icons.alarm_add_outlined,
                              color: MVAColors.primaryColor,
                            ),
                            Text(
                              'Set Reminder',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: MVAColors.textColor),
                            ),
                          ],
                        )),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
