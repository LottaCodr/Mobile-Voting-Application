import 'package:flutter/material.dart';
import 'package:mobile_voting_application/view/stats_screen.dart';
import 'package:mobile_voting_application/utilities/colors.dart';

import '../view/home/home.dart';
import '../view/profile_screen.dart';
import '../view/vote_screen.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int currentPageIndex = 0;
  List<Widget> pages = [];

  @override
  void initState() {
    super.initState();

    pages = [
      const Home(),
      const VoteScreen(),
      const StatsScreen(),
      // const ProgressScreen(),
      const ProfileScreen()
    ];
  }

  void onDestinationSelected(int index) {
    setState(() {
      currentPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentPageIndex],
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: MVAColors.primaryColor,
        selectedIndex: currentPageIndex,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          const NavigationDestination(
              selectedIcon: Icon(Icons.home, color: Colors.white),
              icon: Icon(Icons.home_outlined),
              label: 'Home'),
          const NavigationDestination(
              selectedIcon: Icon(Icons.how_to_vote, color: Colors.white),
              icon: Icon(
                Icons.how_to_vote_outlined,
              ),
              label: 'Vote'),
          const NavigationDestination(
              selectedIcon:
                  Icon(Icons.show_chart_outlined, color: Colors.white),
              icon: Icon(Icons.show_chart),
              label: 'Statistics'),
          NavigationDestination(
              selectedIcon: SizedBox(
                width: 25,
                height: 25,
                child: ClipOval(
                  child: Image.asset(
                    'assets/imageUrl/user.jpg',
                    fit: BoxFit.fill,
                  ),
                ),
              ),
              icon: SizedBox(
                width: 40,
                height: 40,
                child: ClipOval(
                  child: Image.asset(
                    'assets/imageUrl/user.jpg',
                    fit: BoxFit.fill,
                  ),
                ),
              ),
              label: 'Me')
        ],
      ),
    );
  }
}
