import 'package:flutter/material.dart';
import 'package:mobile_voting_application/components/election_card.dart';
import 'package:mobile_voting_application/presentation/widgets/searchbar.dart';
import 'package:mobile_voting_application/presentation/widgets/selection_card.dart';
import 'package:mobile_voting_application/data/models/candidate_model.dart';
import 'package:mobile_voting_application/data/models/election_model.dart';
import 'package:mobile_voting_application/core/theme/colors.dart';

class VoteScreen extends StatefulWidget {
  const VoteScreen({super.key});

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}



class _VoteScreenState extends State<VoteScreen> {
  List<String> data = ['Mr. Barka', 'Worthy', 'Jiggy', 'Emmanuel', 'Peter Obi'];
  List<String> searchResults = [];
  List<String> pickELection = ['Presidential', 'Governorship', "Senatorial"];
  List<String> pickRegion = ['National', 'State', "Locale"];
  String selectedElection = 'Presidential';
  String selectedRegion = 'National';

  // Store selected candidates' voting status
  Map<String, bool> selectedVotes = {};

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
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        isLoading = false;
      });
    });
  }

  void toggleVote(String candidateId) {
    setState(() {
      selectedVotes[candidateId] = !(selectedVotes[candidateId] ?? false);
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(height: 10),
                              CircularProgressIndicator(),
                              SizedBox(height: 60)
                            ],
                          ),
                        );
                      }
                      Candidate candidate = displayCandidates(selectedElection)[index];
                      return ElectionCard(
                        candidate: candidate,
                        isVoted: selectedVotes[candidate.id] ?? false,
                        onVoteToggle: () => toggleVote(candidate.id as String),
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
