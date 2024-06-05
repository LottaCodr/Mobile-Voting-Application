import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;


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

  Future<void> addUserDetails(
      String firstName, String email, String password) async {
    // 1. Hash the password before storing
    final hashedPassword =
        await _hashPassword(password); // Implement password hashing

    // 2. Create a user map with secure password
    final userMap = {
      'firstName': firstName,
      'email': email,
      'password': hashedPassword, // Use hashed password here
    };

    // 3. Add the user document to Firestore
    await FirebaseFirestore.instance.collection('users').add(userMap);
  }

// (Optional) Implement a password hashing function
  Future<String> _hashPassword(String password) async {
    // Use a secure hashing algorithm (e.g., bcrypt)
    // Replace with your chosen hashing implementation
    return password; // Placeholder for actual hashing logic
  }
}

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
