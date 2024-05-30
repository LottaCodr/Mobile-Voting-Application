import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_voting_application/components/button.dart';
import 'package:mobile_voting_application/view/authenticate/sign_in.dart';
import 'package:mobile_voting_application/utilities/colors.dart';

class FirstSplashScreen extends StatelessWidget {
  const FirstSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(30),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/imageUrl/vote1.png'),
             const SizedBox(
                height: 30,
              ),
              const Text(
                'Cast Your Vote',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 50),
                child: Text(
                  "The Patriot comes with easy voting user experience, and speak out",
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              Button(
                  text: "Create an Account",
                  color: MVAColors.primaryColor,
                  onPressed: () {}),
              const SizedBox(
                height: 10,
              ),
              Button(
                  text: "Login",
                  textColor: MVAColors.primaryColor,
                  color: Colors.white,
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const SignIn()),
                        (route) => false);
                    Get.to(const SignIn());
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
