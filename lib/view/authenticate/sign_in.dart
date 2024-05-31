import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
//import 'package:get/get.dart';
import 'package:mobile_voting_application/components/bottom_navbar.dart';
import 'package:mobile_voting_application/components/button.dart';
import 'package:mobile_voting_application/components/user_text_input.dart';
import 'package:mobile_voting_application/services/auth.dart';
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

  Future signInUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Basic client-side validation (optional)
    if (!RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+\.[a-zA-Z]+$")
        .hasMatch(email)) {
      // Show error message: Invalid email format
      return;
    }

    if (password.length < 6) {
      // Show error message: Password must be at least 6 characters
      return;
    }
    showDialog(
      context: context,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    try {
      await AuthService().signIn(
          email: emailController.text.trim(),
          password: passwordController.text.trim());
      await Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (e) => BottomNavBar()), (route) => false);

      print('Logging in as ${emailController.text.trim()}');
    } on FirebaseAuthException catch (error) {
// Handle error with proper user feedback
      String message = 'Login failed.';
      if (error.code == 'user-not-found') {
        message = 'The email address is not registered.';
      } else if (error.code == 'wrong-password') {
        message = 'The password is incorrect.';
      } else {
        print('Login error: ${error.message}');
      }

      // Show user-friendly error message (e.g., snackbar or alert dialog)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    }
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
                        onPressed: () async {
                          //if(emailController.text.le)
                          await signInUser();
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
                      onPressed: () async {
                        await signInUser();
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
