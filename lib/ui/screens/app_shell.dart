import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/app_theme.dart';
import 'ballot_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'results_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  String? _ballotElectionId;
  String? _resultsElectionId;

  void _openBallot(String electionId) {
    setState(() {
      _ballotElectionId = electionId;
      _index = 1;
    });
  }

  void _openResults(String electionId) {
    setState(() {
      _resultsElectionId = electionId;
      _index = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final pages = <Widget>[
      DashboardScreen(onOpenBallot: _openBallot, onOpenResults: _openResults),
      BallotScreen(initialElectionId: _ballotElectionId),
      ResultsScreen(initialElectionId: _resultsElectionId),
      const ProfileScreen(),
    ];
    const labels = <String>['Home', 'Ballot', 'Results', 'Profile'];
    const icons = <IconData>[
      Icons.home_outlined,
      Icons.how_to_vote_outlined,
      Icons.bar_chart_outlined,
      Icons.person_outline_rounded,
    ];
    const selectedIcons = <IconData>[
      Icons.home_rounded,
      Icons.how_to_vote_rounded,
      Icons.bar_chart_rounded,
      Icons.person_rounded,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final content = IndexedStack(index: _index, children: pages);

        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
                    child: NavigationRail(
                      selectedIndex: _index,
                      onDestinationSelected: (index) => setState(() => _index = index),
                      extended: true,
                      minExtendedWidth: 214,
                      backgroundColor: Colors.white,
                      leading: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 4, 10, 26),
                        child: Row(
                          children: [
                            Container(
                              width: 35,
                              height: 35,
                              decoration: BoxDecoration(
                                color: AppColors.blue,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(
                                Icons.how_to_vote_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'CivicVote',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      destinations: List<NavigationRailDestination>.generate(
                        labels.length,
                        (index) => NavigationRailDestination(
                          icon: Icon(icons[index]),
                          selectedIcon: Icon(selectedIcons[index]),
                          label: Text(labels[index]),
                        ),
                      ),
                      trailing: controller.isDemo
                          ? Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: Text(
                                'DEMO MODE',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                  letterSpacing: 0.7,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          body: content,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (index) => setState(() => _index = index),
            destinations: List<NavigationDestination>.generate(
              labels.length,
              (index) => NavigationDestination(
                icon: Icon(icons[index]),
                selectedIcon: Icon(selectedIcons[index]),
                label: labels[index],
              ),
            ),
          ),
        );
      },
    );
  }
}
