import 'package:flutter/material.dart';
import 'package:mobile_voting_application/utilities/colors.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: CustomColors.accentColor,
        selectedIndex: currentPageIndex,
        destinations: const [
          NavigationDestination(
              selectedIcon: Icon(Icons.home),
              icon: Icon(Icons.home_outlined),
              label: 'Home'),
          NavigationDestination(
              selectedIcon: Icon(Icons.how_to_vote),
              icon: Icon(Icons.how_to_vote_outlined),
              label: 'Votes'),
          NavigationDestination(
              icon: Icon(Icons.priority_high_rounded), label: 'progress'),
          NavigationDestination(
              selectedIcon: Icon(Icons.person),
              icon: Icon(Icons.person_outline_outlined),
              label: 'Profile')
        ],
      ),
    );
  }
}
