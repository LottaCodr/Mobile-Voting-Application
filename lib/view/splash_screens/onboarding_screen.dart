import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_onboarding_slider/flutter_onboarding_slider.dart';
import 'package:mobile_voting_application/utilities/colors.dart';
import 'package:mobile_voting_application/view/authenticate/sign_in.dart';
import 'package:mobile_voting_application/view/authenticate/signup.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnBoardingSlider(
      centerBackground: true,
      indicatorAbove: true,
      headerBackgroundColor: Colors.white,
      finishButtonText: 'Sign up',
      finishButtonStyle: const FinishButtonStyle(
        elevation: 4,
        backgroundColor: MVAColors.primaryColor,
      ),
      onFinish: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => const SignUpScreen(),
          ),
        );
      },
      skipTextButton: const Text(
        'Skip',
        style: TextStyle(color: MVAColors.primaryColor),
      ),
      skipFunctionOverride: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => const SignUpScreen(),
          ),
        );
      },
      trailing: const Text('Login'),
      trailingFunction: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => const SignIn(),
          ),
        );
      },
      background: [
        Image.asset(
          'assets/imageUrl/vote1.png',
          height: 400,
        ),
        Image.asset(
          'assets/imageUrl/vote2.png',
          height: 400,
        ),
        Image.asset(
          'assets/imageUrl/vote3.png',
          height: 400,
        ),
      ],
      totalPage: 3,
      speed: 1.8,
      pageBodies: [
        Center(
          child: Container(
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: const Column(
              children: <Widget>[
                SizedBox(
                  height: 400,
                ),
                Text(
                  'The Power is in Your Hands',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: MVAColors.textColor,
                    fontSize: 24.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Text(
                  'Democracy in your pocket. No more long lines, no more missed deadlines. Patriot, the secure and convenient mobile voting app, empowers you to shape your future – on your terms.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black26,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          alignment: Alignment.center,
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: const Column(
            children: <Widget>[
              SizedBox(
                height: 400,
              ),
              Text(
                'Your Voice Matters',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: MVAColors.textColor,
                  fontSize: 24.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Text(
                'Empowering citizens. Shaping the future. Download Patriot and join the movement of engaged voters. Vote securely and conveniently from your smartphone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black26,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          alignment: Alignment.center,
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: const Column(
            children: <Widget>[
              SizedBox(
                height: 400,
              ),
              Text(
                'Vote with Confidence',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: MVAColors.textColor,
                  fontSize: 24.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Text(
                'Every vote counts. Patriot makes voting accessible and ensures your voice is heard. Be a part of shaping the decisions that impact your community and nation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black26,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
