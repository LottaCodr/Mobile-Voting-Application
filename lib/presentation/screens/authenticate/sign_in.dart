import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
//import 'package:get/get.dart';
import 'package:mobile_voting_application/presentation/widgets/bottom_navbar.dart';
import 'package:mobile_voting_application/presentation/widgets/button.dart';
import 'package:mobile_voting_application/presentation/widgets/user_text_input.dart';
import 'package:mobile_voting_application/services/auth.dart';
import 'package:mobile_voting_application/presentation/screens/authenticate/signup.dart';
//import 'package:mobile_voting_application/screens/candidate_screen.dart';
//import 'package:mobile_voting_application/screens/stats_screen.dart';
import 'package:mobile_voting_application/core/theme/colors.dart';
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
              fontWeight: FontWeight.bold, color: MVAColors.onPrimary),
        ),
        backgroundColor: MVAColors.primaryColor,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Welcome Back',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 24, color: MVAColors.primaryColor),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.handshake, color: MVAColors.secondaryColor)
                    ],
                  ),
                  const SizedBox(height: 40),
                  UserTextInput(
                    labelName: "Email",
                    textInputType: TextInputType.emailAddress,
                    obscureText: false,
                    textController: emailController,
                  ),
                  const SizedBox(height: 16),
                  UserTextInput(
                    labelName: "Password",
                    textInputType: TextInputType.text,
                    obscureText: true,
                    textController: passwordController,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
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
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () async {
                      await signInUser();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MVAColors.primaryColor,
                      foregroundColor: MVAColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      "Sign In",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
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
