import 'package:easy_splash_screen/easy_splash_screen.dart';
import 'package:mobile_voting_application/utilities/colors.dart';
import 'package:mobile_voting_application/view/splash_screens/first_splash.dart';
import 'package:flutter/material.dart';

import 'onboarding_screen.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  Widget build(BuildContext context) {
    return EasySplashScreen(
      logo: Image.network(
          'https://cdn4.iconfinder.com/data/icons/logos-brands-5/24/flutter-512.png'),
      title: const Text(
        "P A T R I O T",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.grey.shade400,
      showLoader: true,
      loaderColor: MVAColors.primaryColor,
      loadingText: const Text("Welcome to the Patriot..."),
      navigator: const OnBoardingScreen(),
      durationInSeconds: 6,
    );
  }
}
