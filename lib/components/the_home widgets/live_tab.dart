import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';

import '../../utilities/colors.dart';
import '../../view/authenticate/sign_in.dart';
import '../candidate_scorecard.dart';
import 'tab_cards/live_card.dart';

class LiveTab extends StatefulWidget {
  const LiveTab({super.key});

  @override
  State<LiveTab> createState() => _LiveTabState();
}

class _LiveTabState extends State<LiveTab> {
  PageController pageController = PageController(viewportFraction: 0.9);
  var _currentPageValue = 0.0;
  final double _scaleFactor = 0.85;
  final double _height = 300;
  //bool onchange = false;

  @override
  void initState() {
    super.initState();
    pageController.addListener(() {
      setState(() {
        _currentPageValue = pageController.page!;
      });
    });
  }

   @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
          child: Column(
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 320,
            child: PageView.builder(
                controller: pageController,
                itemCount: 5,
                itemBuilder: (context, position) {
                  return VoteCountingCard(
                    index: position,
                    currentPageValue: _currentPageValue,
                    scaleFactor: _scaleFactor,
                    height: _height,
                  );
                }),
          ),

          DotsIndicator(
            dotsCount: 5,
            position: _currentPageValue.toInt(),
            decorator: const DotsDecorator(
              color: Colors.grey, // Inactive color
              activeColor: MVAColors.primaryColor,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(10),
            width: MediaQuery.of(context).size.width,
            height: 160,
            decoration: BoxDecoration(
                color: Colors.red, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Report Any Vote Buying',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900),
                ),
                const Text(
                  'Contact us concerning any illegal vote.',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(
                  height: 25,
                ),
                Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadiusDirectional.circular(50)),
                    width: 160,
                    height: 40,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          'Click here',
                          style: TextStyle(
                              color: MVAColors.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                        Icon(
                          Icons.report_problem,
                          color: Colors.red,
                        ),
                      ],
                    )),
              ],
            ),
          ),

          //The Candidates
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Top Candidates',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                TextButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignIn()),
                          (route) => false);
                    },
                    child: const Text(
                      'See all',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: MVAColors.primaryColor),
                    ))
              ],
            ),
          ),

          //The Candidates circular Cards
          const CandidateScore(
            axisDirection: Axis.horizontal,
          )
        ],
      )),
    );
  }
}
