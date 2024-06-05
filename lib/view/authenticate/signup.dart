import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_voting_application/components/button.dart';
import 'package:mobile_voting_application/services/auth.dart';
import 'package:mobile_voting_application/view/authenticate/sign_in.dart';
import 'package:mobile_voting_application/utilities/colors.dart';

import '../../components/bottom_navbar.dart';
import '../../components/user_text_input.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController voterIDController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  //create user
  Future signUP() async {
    //Get user id
    String userID = AuthService().currentUser.toString();

    //collect user's name and phoneNumber
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String phoneNumber = phoneController.text.trim();
    //String voterId = voterIDController.text.trim();
    String password = passwordController.text.trim();

    showDialog(
      context: context,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      // Show error message: All fields are required
      return;
    }
    try {
      await AuthService()
          .createUserWithEmailAndPassword(email: email, password: password);
      await AuthService().addUserDetails(name, email, password);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => BottomNavBar()), // Redirect user to HomeScreen after signup
        (route) => false,
      );

      //Create a reference to the users collection in firestore
      CollectionReference userRef =
          FirebaseFirestore.instance.collection("voters");

      //Create a new document in the users collection with the userID
      await userRef.doc(userID).set({
        'name': name,
        'phoneNumber': phoneNumber,
        'email': email,
        'password': password
      });

      //successful user creation
      redirectToSignInPage();
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed.';
      if (e.code == 'email-already-in-use') {
        message = 'The email address is already in use.';
      } else {
        print('Registration error: ${e.message}');
      }
      // Show user-friendly error message (e.g., snackbar or alert dialog)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
//display error message to user
    } catch (e) {
      print('Registration error: $e');
      // Show generic error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred during registration.'),
        ),
      );
      Navigator.pop(context);
    }
    //navigatorKey.currentState!.popUntil((route) => route.isFirst);
  }

  //form validation
  bool validateForm() {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String voterId = voterIDController.text.trim();
    String password = passwordController.text.trim();
    String phoneNumber = phoneController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        phoneNumber.isEmpty) {
      Get.snackbar(
        'Error:',
        'Please fill ALL the fields',
        backgroundColor: Colors.red,
      );
    } else if (name.length < 3) {
      Get.snackbar(
        'Error:',
        'Name must be at least 3 characters',
        backgroundColor: Colors.red,
      );
    } else if (phoneNumber.length < 11 || phoneNumber.length > 11) {
      Get.snackbar('Error:', 'Invalid Phone Number',
          backgroundColor: Colors.red);
    } else if (!isValidEmail(email)) {
      Get.snackbar(
        'Error:',
        'Invalid Email',
        backgroundColor: Colors.red,
      );
    } else if (phoneNumber.length < 6) {
      Get.snackbar(
        'Error:',
        'Must contain atleast 6 characters',
        backgroundColor: Colors.red,
      );
    } else {
      Get.snackbar(
          'Congratulation', 'Your Account has been successfully created',
          backgroundColor: Colors.green);

      return false;
    }
    return true;
  }

  //lets create a custom email validator
  bool isValidEmail(String email) {
    RegExp emailRegExp = RegExp(
        r'^[\w-]+(\.[\w-]+)*@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*(\.[a-zA-Z]{2,})$');
    return emailRegExp.hasMatch(email);
  }

//   //register the user
  void registerValidUser() {
    if (!validateForm()) {
      signUP();
    }
  }

  //redirect the user
  void redirectToSignInPage() {
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (e) => const SignIn()), (route) => true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create An Account',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: MVAColors.primaryColor),
                ),
                const Text(
                  'Kindly fill out your details carefully.',
                ),
                const SizedBox(
                  height: 40,
                ),
                Column(
                  children: [
                    UserTextInput(
                      labelName: 'Full Name Here',
                      textInputType: TextInputType.text,
                      textController: nameController,
                    ),
                    UserTextInput(
                      labelName: 'Email Address',
                      textInputType: TextInputType.emailAddress,
                      textController: emailController,
                    ),
                    UserTextInput(
                      labelName: 'Phone Number',
                      textInputType: TextInputType.phone,
                      textController: phoneController,
                    ),
                    UserTextInput(
                      labelName: "Voter's ID Number (Optional)",
                      textInputType: TextInputType.number,
                      textController: voterIDController,
                    ),
                    UserTextInput(
                      icon: Icons.remove_red_eye,
                      labelName: 'Password',
                      textInputType: TextInputType.text,
                      textController: passwordController,
                    ),
                    UserTextInput(
                      icon: Icons.remove_red_eye,
                      labelName: 'Confirm Password',
                      textInputType: TextInputType.text,
                      textController: passwordController,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 80,
                ),
                Button(
                  text: 'Create an Account',
                  onPressed: () {
                    registerValidUser();
                    ;
                  },
                  color: MVAColors.primaryColor,
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignIn()));
                        },
                        child: const Text(
                          'Sign-in here',
                          style: TextStyle(
                              color: MVAColors.primaryColor,
                              fontWeight: FontWeight.bold),
                        ))
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
