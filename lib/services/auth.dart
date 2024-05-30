import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

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

  Future signIn({required String email, required String password}) async {
    if (passwordConfirmed()) {
      await _auth.signInWithEmailAndPassword(
          email: 'email'.trim(), password: 'password'.trim());

      //add user details
    }
  }

  bool passwordConfirmed() {
    if ('password'.trim() == 'confirmed password'.trim()) {
      return true;
    } else {
      return false;
    }
  }

  Future createUserWithEmailAndPassword(
      {required String email, required String password}) async {
    await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future signOut() async {
    await _auth.signOut();
  }
// Future addUserDetails(String firstName, String lastName, String email, String password) async {
//   await FirebaseFirestore.instance.collection('users').add(
//      firstName,
//      lastName,
//     'email': email,
//     'password': password
//   );
// }
}
