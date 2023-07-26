import 'dart:core';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

/// The AuthServiceProvider provides an AuthService instance to all descendant widgets.
/// It is used in lib/main.dart, see that source for example usage.
///
/// In effect, it's a state monad for the AuthService instance.
/// Accessible in descendant widgets via:
/// ```dart
/// final authService = Provider.of<AuthService>(context, listen: false);
/// ```
class AuthServiceProvider extends StatelessWidget {
  AuthService authService;
  final Widget child;

  AuthServiceProvider({
    required this.authService,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Provider<AuthService>.value(
      value: authService,
      child: child,
    );
  }
}

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  User? _currentUser;

  AuthService() {
    _firebaseAuth.authStateChanges().listen((user) {
      final String name = user?.displayName ?? 'MissingName';
      print("authStateChange user.displayName: $name");
      _currentUser = user;
    });
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _currentUser;

  Future<String?> signInWithEmailAndPassword(String email, String password) async {
    String? err;
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("signInWithEmailAndPassword userCredential.user: ${userCredential.user}");
      err = null;
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException");
      print(e);
      print("FirebaseAuthException.code");
      print(e.code);
      if (e.code == 'user-not-found') {
        err = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        err = 'Wrong password provided for that user.';
      } else if (e.code == 'unknown') {
        if (e.toString().contains('auth/invalid-email')) {
          err = 'Email invalid.';
        } else if (e.toString().contains('auth/wrong-password')) {
          err = 'Wrong password.';
        } else {
          print("Nonspecific FirebaseAuthException: $e");
          err = 'An error occurred. Please try again later.';
        }
      } else {
        print("Nonspecific Exception: $e");
        err = 'An error occurred. Please try again later.';
      }
    } catch (e) {
      print("Unknown error");
      print(e);
      err = 'An error occurred. Please try again later.';
    }
    return err;
  }

  // Future<String?> signInWithGoogle(BuildContext context) async {
  //   try {
  //     final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
  //     final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
  //     final credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );
  //     final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
  //     return userCredential.user!.uid;
  //   } catch (e) {
  //     print("Unknown error");
  //     print(e);
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('An error occurred. Please try again later.')),
  //     );
  //     return null;
  //   }
  // }

  // Retrun null if successful, otherwise error message.
  Future<String?> signUpWithEmailAndPassword(String email, String password, String firstName) async {
    String? err;
    print("signUpWithEmailAndPassword");
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      await user?.updateDisplayName(firstName);
      await user?.sendEmailVerification();
      err = await signOut();
      if (err == null) {
        err = await signInWithEmailAndPassword(email, password);
      }
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException");
      print(e);
      print("FirebaseAuthException.code");
      print(e.code);
      err = 'An error occurred. Please try again later.';
      if (e.code == 'weak-password') {
        err = 'The password provided is too weak.';
      } else if (e.code == "email-already-in-use") {
        err = 'An account already exists for that email.';
      } else if (e.code == 'unknown') {
        if (e.toString().contains('auth/invalid-email')) {
          err = 'Email invalid.';
        } else if (e.toString().contains('auth/email-already-in-use')) {
          err = 'The account already exists for that email.';
        } else if (e.toString().contains('auth/missing-password')) {
          err = 'Please provide a password.';
        } else {
          err = 'An error occurred. Please try again later.';
        }
      }
    } catch (e) {
      print("Unknown error");
      print(e);
      err = 'An error occurred. Please try again later.';
    }
    return err;
  }

  Future<String?> signOut() async {
    String? err;
    try {
      await _firebaseAuth.signOut(); // NOTE redirect to '/' route is done by caller.
      _currentUser = null; // do this immediately because there might be a delay in the listener.
      err = null;
    } catch (e) {
      print(e);
      err = 'An error occurred. Please try again later.';
    }
    return err;
  }

  // TODO non-brut error handling around sendPasswordResetEmail
  Future<String?> sendPasswordResetEmail(String email) async {
    final String? err;
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return null;
    } catch (e) {
      print(e);
      RegExp regExp = RegExp(r"\[.*?\]");
      err = "$e".replaceAll(regExp, "");
      return err;
    }
  }
}
