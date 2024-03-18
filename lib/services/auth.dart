// import 'package:firebase_auth/firebase_auth.dart';

// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   //sign in anon

//   Future signInAnon() async {
//     try {
//       AuthResult result = await _auth.signInAnonymously();
//       FireBaseUser user = result.user;
//       return user;
//     } catch (e) {
//       print(e.toString());
//       return null;
//     }
//   }
// }

//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future signIn() async {
  if (passwordConfirmed()) {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'email'.trim(), password: 'password'.trim());

    //add user details
  }
}

bool passwordConfirmed() {
  if ('password'.trim() == 'confirme password'.trim()) {
    return true;
  } else {
    return false;
  }
}

// Future addUserDetails(String firstName, String lastName, String email, String password) async {
//   await FirebaseFirestore.instance.collection('users').add(
//     'first name' : firstName,
//     'last name'; lastName,
//     'email': email,
//     'password': password
//   );
// }
