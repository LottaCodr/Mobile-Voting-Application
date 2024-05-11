import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_voting_application/components/searchbar.dart';
import 'package:mobile_voting_application/models/candidate_model.dart';
import 'package:mobile_voting_application/view/candidate_screen.dart';
import 'package:mobile_voting_application/utilities/colors.dart';

import '../components/election_card.dart';

class VoteScreen extends StatefulWidget {
  const VoteScreen({super.key});

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  List<String> data = ['Mr. Barka', 'Worthy', 'Jiggy', 'Emmanuel', 'Peter Obi'];

  List<String> searchResults = [];

  void onQueryChanged(String query) {
    setState(() {
      searchResults = data
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Read Candidates Mandate',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.all(20),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'President',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                      Text(
                        'Presidential Election',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      //SearchBar here
                      TheSearchBar()
                    ],
                  ),
                ),
                Container(
                  decoration:
                      const BoxDecoration(color: MVAColors.backgroundColor),
                  height: MediaQuery.of(context).size.height,
                  child: ListView.builder(
                    itemCount: myCandidates.length,
                    itemBuilder: (context, int index) {
                      return GestureDetector(
                        onTap: () {
                          Candidate name = myCandidates[index];
                          Get.to(CandidateScreen(
                            candidate: name,
                          ));
                        },
                        child: ElectionCard(
                          candidate: myCandidates[index],
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
