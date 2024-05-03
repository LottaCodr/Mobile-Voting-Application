import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
//import 'package:get/get.dart';
import 'package:mobile_voting_application/components/bottom_navbar.dart';
import 'package:mobile_voting_application/components/button.dart';
import 'package:mobile_voting_application/components/user_text_input.dart';
import 'package:mobile_voting_application/view/authenticate/signup.dart';
//import 'package:mobile_voting_application/screens/candidate_screen.dart';
//import 'package:mobile_voting_application/screens/stats_screen.dart';
import 'package:mobile_voting_application/utilities/colors.dart';
//Simport 'package:mobile_voting_application/services/auth.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  // final AuthService _auth = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  void registerNewUser(BuildContext context) async {
    // final FirebaseUser firebaseUser =
    //     (await _firebaseAuth.createUserWithEmailAndPassword(
    //         email: emailController.text, password: passwordController.text)).user;
    //         if(firebaseUser != null) {
    //           //save to db

    //         } else {
    //           //error display
    //         }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PATRIOT',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: MVAColors.primaryColor),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  const Row(
                    children: [
                      Text(
                        'Welcome Back',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Icon(Icons.handshake)
                    ],
                  ),
                  const SizedBox(
                    height: 50,
                  ),
                  UserTextInput(
                      labelName: "Email",
                      textInputType: TextInputType.emailAddress,
                      textController: emailController),
                  UserTextInput(
                      labelName: "Password",
                      textInputType: TextInputType.text,
                      textController: passwordController),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          //if(emailController.text.le)
                          registerNewUser(context);
                        },
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                              color: MVAColors.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 200,
                  ),
                  Button(
                      text: "Sign In",
                      color: MVAColors.primaryColor,
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const BottomNavBar()),
                            (route) => false);
                      }),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignUpScreen()),
                              (route) => false);
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                              color: MVAColors.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
