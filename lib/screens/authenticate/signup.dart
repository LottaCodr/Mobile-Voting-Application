import 'package:flutter/material.dart';
import 'package:mobile_voting_application/components/button.dart';
import 'package:mobile_voting_application/screens/authenticate/sign_in.dart';
import 'package:mobile_voting_application/utilities/colors.dart';

import '../../components/user_text_input.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController voterIDController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

//   //create user
//   Future signUP() async {
//     showDialog(
//       context: context,
//       builder: (context) => const Center(
//         child: CircularProgressIndicator(),
//       ),
//     );
//     try {
//       UserCredential userCredential =
//           await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email: emailController.text.trim(),
//         password: passwordController.text.trim(),
//       );

//       //Get user id
//       String userID = userCredential.user!.uid;

//       //collect user's name and phoneNumber
//       String name = nameController.text.trim();
//       String phoneNumber = phoneController.text.trim();
//       String voterId = voterIDController.text.trim();
//       String password = passwordController.text.trim();

//       //Create a reference to the users collection in firestore
//       CollectionReference userRef =
//           FirebaseFirestore.instance.collection("users");

//       //Create a new document in the users collection with the userID
//       await userRef.doc(userID).set({
//         'name': name,
//         'phoneNumber': phoneNumber,
//         'email': email,
//         'password': password
//       });

//       //successful user creation
//       redirectToSignInPage();
//     } on FirebaseAuthException catch (e) {
//       if (kDebugMode) {
//         print(e);
//       }
// //display error message to user
//       Get.snackbar('Error:', 'Failed to create account ${e.message}',
//           backgroundColor: Colors.red);
//     } finally {
//       Navigator.pop(context);
//     }
//     navigatorKey.currentState!.popUntil((route) => route.isFirst);
//   }

//   //form validation
//   bool validateForm() {
//     String name = nameController.text.trim();
//     String email = emailController.text.trim();
//     String password = passwordController.text.trim();
//     String phoneNumber = phoneController.text.trim();

//     if (name.isEmpty ||
//         email.isEmpty ||
//         password.isEmpty ||
//         phoneNumber.isEmpty) {
//       Get.snackbar(
//         'Error:',
//         'Please fill ALL the fields',
//         backgroundColor: Colors.red,
//       );
//     } else if (name.length < 3) {
//       Get.snackbar(
//         'Error:',
//         'Name must be at least 3 characters',
//         backgroundColor: Colors.red,
//       );
//     } else if (phoneNumber.length < 11 || phoneNumber.length > 11) {
//       Get.snackbar('Error:', 'Invalid Phone Number',
//           backgroundColor: Colors.red);
//     } else if (!isValidEmail(email)) {
//       Get.snackbar(
//         'Error:',
//         'Invalid Email',
//         backgroundColor: Colors.red,
//       );
//     } else if (phoneNumber.length < 6) {
//       Get.snackbar(
//         'Error:',
//         'Must contain atleast 6 characters',
//         backgroundColor: Colors.red,
//       );
//     } else {
//       Get.snackbar(
//           'Congratulation', 'Your Account has been successfully created',
//           backgroundColor: Colors.green);

//       return false;
//     }
//     return true;
//   }

//   //lets create a custom email validator
//   bool isValidEmail(String email) {
//     RegExp emailRegExp = RegExp(
//         r'^[\w-]+(\.[\w-]+)*@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*(\.[a-zA-Z]{2,})$');
//     return emailRegExp.hasMatch(email);
//   }

//   //register the user
//   void registerValidUser() {
//     if (!validateForm()) {
//       signUP();
//     }
//   }

//   //redirect the user
//   void redirectToSignInPage() {
//     Navigator.pushAndRemoveUntil(context,
//         MaterialPageRoute(builder: (e) => const MyPlan()), (route) => true);
//   }

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
                  onPressed: () {},
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
                                  builder: (context) => SignIn()));
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
