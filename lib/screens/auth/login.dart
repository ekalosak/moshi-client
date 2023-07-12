import 'package:flutter/material.dart';

import '../../services/auth.dart';
import 'sign_up.dart';
import 'password_reset.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService;

  LoginScreen({required this.authService});

  Future<void> loginWithEmailPassword(BuildContext context) async {
    final String? authToken = await authService.signInWithEmailAndPassword(
      emailController.text,
      passwordController.text,
      context,
    );

    if (authToken != null) {
      print("Login with email+password succeded!");
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      // TODO Handle login error
      print("Login with email+password failed.");
    }
  }

  Future<void> loginWithGoogle(BuildContext context) async {
    final String? authToken = await authService.signInWithGoogle(context);

    if (authToken != null) {
      print("Login with google succeded!");
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      // TODO Handle login error
      print("Login with google failed.");
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
            // SizedBox(height: 10),
            // TODO add teh clientId
            // ElevatedButton(
            //   child: Text('Log in with Google'),
            //   onPressed: () {
            //     loginWithGoogle(context);
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}
