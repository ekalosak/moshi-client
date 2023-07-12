import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/auth.dart';
import 'sign_up.dart';
import 'password_reset.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService;
  final Function(String) loginCallback;

  LoginScreen({required this.authService, required this.loginCallback});

  Future<void> loginWithEmailPassword(BuildContext context) async {
    final String? authToken = await authService.signInWithEmailAndPassword(
      emailController.text,
      passwordController.text,
    );

    if (authToken != null) {
      loginCallback(authToken);
    } else {
      print("Authentication failed");
      // TODO Handle login error, see below
    }
  }

  Future<void> loginWithGoogle(BuildContext context) async {
    final String? authToken = await authService.signInWithGoogle();

    if (authToken != null) {
      loginCallback(authToken);
    } else {
      print("Authentication failed");
      // TODO instead of return null, throw the exception and catch here.
      // } on FirebaseAuthException catch (e) {
      //   if (e.code == 'user-not-found') {
      //     // TODO show the error in a "snackbar" https://docs.flutter.dev/ui/widgets/material
      //     print('No user found for that email.');
      //   } else if (e.code == 'wrong-password') {
      //     // TODO show the error in a "snackbar" https://docs.flutter.dev/ui/widgets/material
      //     print('Wrong password provided for that user.');
      //   }
      // } catch (e) {
      //   // TODO let user know something bad happened..?
      //   print(e);
      // }
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
