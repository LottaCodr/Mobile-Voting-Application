//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:mobile_voting_application/components/the_home%20widgets/completed_tab.dart';
import 'package:mobile_voting_application/components/the_home%20widgets/live_tab.dart';

import 'package:mobile_voting_application/components/vote_counting_card.dart';
import 'package:mobile_voting_application/models/election_model.dart';

import 'package:mobile_voting_application/utilities/colors.dart';

import '../../components/candidate_scorecard.dart';
import '../../components/the_home widgets/upcoming_tab.dart';
import '../authenticate/sign_in.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> tabLabels = [
      // Specify key types and dynamic value
      {'text': 'Upcoming', 'icon': Icons.calendar_today},
      {'text': 'Live', 'icon': Icons.play_arrow},
      {'text': 'Completed', 'icon': Icons.check_circle},
    ];
    List<Widget> tabBarViews = [UpcomingTab(), LiveTab(), CompletedTab()];

    // for (final label in tabLabels) {
    //   Future < ElectionModel> _electionModel() async{
    //     if(ElectionModel.isNotEmpty) {

    //     }
    //   }
    // }

    tabBarViews.add(
      LiveTab(),
    );
    tabBarViews.add(CompletedTab());
    tabBarViews.add(UpcomingTab());

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        //backgroundColor: MVAColors.backgroundColor,
        appBar: AppBar(
          bottom: TabBar(
              indicatorWeight: 4,
              labelPadding: EdgeInsets.only(right: 24, left: 24),
              labelColor: MVAColors.primaryColor,
              indicatorColor: MVAColors.primaryColor,
              isScrollable: true,
              tabs: tabLabels
                  .map(
                    (label) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(label['icon'] as IconData),
                        const SizedBox(
                          width: 3,
                        ),
                        FittedBox(child: Text(label['text'] as String))
                      ],
                    ),
                  )
                  .toList()),
          title: const Text(
            "Patriot",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30,
                color: MVAColors.primaryColor),
          ),
        ),
        body: TabBarView(children: tabBarViews),
      ),
    );
  }
}
