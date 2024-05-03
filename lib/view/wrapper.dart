import 'package:flutter/material.dart';
import 'package:mobile_voting_application/components/bottom_navbar.dart';
import 'package:mobile_voting_application/view/home/home.dart';

import 'splash_screens/first_splash.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    //return Home or Authenticate
    return const BottomNavBar();
  }
}
