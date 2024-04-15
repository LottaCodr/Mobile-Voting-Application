import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_voting_application/models/candidate_model.dart';
import 'package:mobile_voting_application/screens/candidate_screen.dart';
import 'package:mobile_voting_application/utilities/colors.dart';

import '../components/election_card.dart';

class VoteScreen extends StatefulWidget {
  const VoteScreen({super.key});

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'President',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                      const Text(
                        'Presidential Election',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      TextField(
                        controller: TextEditingController(),
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.none,
                        decoration: InputDecoration(
                            hintText: 'Search for candidate',
                            icon: Icon(Icons.search)),
                      )
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
                          String name = myCandidates[index].name;
                          Get.to(CandidateScreen(
                            name: name,
                          ));
                        },
                        child: ElectionCard(
                          candidateName: myCandidates[index].name,
                          imageUrl: myCandidates[index].imageUrl,
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
