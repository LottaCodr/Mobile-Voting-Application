import 'package:flutter/material.dart';
import 'package:mobile_voting_application/components/searchbar.dart';
import 'package:mobile_voting_application/components/selection_card.dart';
import 'package:mobile_voting_application/models/candidate_model.dart';
import 'package:mobile_voting_application/models/election_model.dart';
import 'package:mobile_voting_application/utilities/colors.dart';
import 'package:get/get.dart';
import '../components/election_card.dart';

class VoteScreen extends StatefulWidget {
  const VoteScreen({super.key});

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  List<String> data = ['Mr. Barka', 'Worthy', 'Jiggy', 'Emmanuel', 'Peter Obi'];

  List<String> searchResults = [];

  //for the election selections
  List<String> pickELection = ['Presidential', 'Governorship', "Senatorial"];
  List<String> pickRegion = ['National', 'State', "Locale"];
  String selectedElection = 'Presidential';
  String selectedRegion = 'National';

  void onQueryChanged(String query) {
    setState(() {
      searchResults = data
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  List<Candidate> displayCandidates(String theElection) {
    if (theElection == selectedElection && selectedElection == 'Presidential') {
      return presidentialCandidates;
    } else if (selectedElection == 'Senatorial') {
      return senatorialCandidates;
    } else {
      return goveronshipCandidates;
    }
  }

  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    setState(() {
      isLoading = true;
    });
    // Simulate loading for 2 seconds (adjust as needed)
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Vote Your Candidate',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SelectionCard(
                  header: '',
                  electionSelected: pickELection,
                  selected: selectedElection,
                  textColor: MVAColors.primaryColor,
                  bgColor: MVAColors.primaryColor.withOpacity(0.2),
                  textSize: 18,
                  dropDownWidth: 180,
                ),
                const TheSearchBar()
                //SearchBar here
              ],
            ),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 25),
                  decoration: const BoxDecoration(color: Colors.white),
                  height: MediaQuery.of(context).size.height,
                  child: ListView.builder(
                    itemCount: displayCandidates(selectedElection).length,
                    itemBuilder: (context, index) {
                      if (isLoading) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(
                                height: 30,
                              )
                            ],
                          ),
                        );
                      }
                      return ElectionCard(
                        candidate: displayCandidates(selectedElection)[index],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
