import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sign_up.dart';
import 'password_reset.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> loginWithEmailPassword(BuildContext context) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      final String firstName = userCredential.user!.displayName ?? '';

      // Save the auth token and first name to shared preferences
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('authToken', userCredential.user!.uid);
      prefs.setString('firstName', firstName);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyApp(authToken: userCredential.user!.uid)),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // TODO show the error in a "snackbar" https://docs.flutter.dev/ui/widgets/material
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        // TODO show the error in a "snackbar" https://docs.flutter.dev/ui/widgets/material
        print('Wrong password provided for that user.');
      }
    } catch (e) {
      // TODO let user know something bad happened..?
      print(e);
    }
  }

  Future<void> loginWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleUser!.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final String firstName = userCredential.user!.displayName ?? '';

      // Save the auth token and first name to shared preferences
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('authToken', userCredential.user!.uid);
      prefs.setString('firstName', firstName);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyApp(authToken: userCredential.user!.uid)),
      );
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
              ),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              child: Text('Log in'),
              onPressed: () {
                loginWithEmailPassword(context);
              },
            ),
            SizedBox(height: 10),
            ElevatedButton(
              child: Text('Log in with Google'),
              onPressed: () {
                loginWithGoogle(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
