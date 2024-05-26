import 'package:flutter/material.dart';
import 'package:mobile_voting_application/components/bar_chart.dart';
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70.0),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              //mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SelectionCard(
                  header: 'Pick Election',
                  selected: selectedElection,
                  electionSelected: pickELection,
                  textColor: MVAColors.primaryColor,
                  bgColor: MVAColors.primaryColor.withOpacity(0.2),
                  textSize: 12,
                  dropDownWidth: 150,
                ),
                SelectionCard(
                    header: 'Region',
                    selected: selectedRegion,
                    electionSelected: pickRegion,
                    textColor: MVAColors.primaryColor,
                    bgColor: MVAColors.primaryColor.withOpacity(0.2),
                    textSize: 12,
                    dropDownWidth: 150),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              const SizedBox(
                height: 10,
              ),
              Container(
                width: MediaQuery.of(context).size.width,
                height: 400,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: MVAColors.backgroundColor),
                child: BarChart(
                  electionType: selectedElection,
                ),
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
              Container(
                padding: const EdgeInsets.only(bottom: 25),
                height: 400,
                width: MediaQuery.of(context).size.width,
                child: ListView.builder(
                    physics: const ScrollPhysics(),
                    scrollDirection: Axis.vertical,
                    itemCount: myCandidates.length,
                    itemBuilder: (context, index) {
                      return ElectionCard(candidate: myCandidates[index]);
                    }),
              )
            ],
          ),
        ),
      ),
    );
  }
}
