import 'package:flutter/material.dart';
import 'package:mobile_voting_application/components/election_card.dart';
import 'package:mobile_voting_application/components/selection_card.dart';
import 'package:mobile_voting_application/models/candidate_model.dart';
import 'package:mobile_voting_application/utilities/colors.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<String> pickELection = ['Presidential', 'State', "LG"];
  List<String> pickRegion = ['National', 'State', "Locale"];
  String selectedElection = 'Presidential';
  String selectedRegion = 'National';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vote Statistics"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SelectionCard(
                    header: 'Pick Election',
                    selected: selectedElection,
                    electionSelected: pickELection,
                  ),
                  SelectionCard(
                    header: 'Region',
                    selected: selectedRegion,
                    electionSelected: pickRegion,
                  ),
                ],
              ),
              const SizedBox(
                height: 30,
              ),
              Container(
                width: MediaQuery.of(context).size.width,
                height: 400,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: MVAColors.backgroundColor),
              ),
              const SizedBox(
                height: 40,
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Candidates',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    'Votes',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 18),
                  ),
                ],
              ),
              SizedBox(
                height: 190,
                width: MediaQuery.of(context).size.width,
                child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    physics: const ScrollPhysics(),
                    scrollDirection: Axis.vertical,
                    itemCount: myCandidates.length,
                    itemBuilder: (context, index) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElectionCard(
                              candidateName: myCandidates[index].name,
                              imageUrl: myCandidates[index].imageUrl),
                          const SizedBox(
                            height: 7,
                          )
                        ],
                      );
                    }),
              )
            ],
          ),
        ),
      ),
    );
  }
}
