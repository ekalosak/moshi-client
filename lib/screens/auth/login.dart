import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/auth.dart';
import '../main/main.dart';
import 'sign_up.dart';
import 'password_reset.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> loginWithEmailPassword(BuildContext context) async {
    final AuthService authService =
        Provider.of<AuthService>(context, listen: false);
    final String? authToken = await authService.signInWithEmailAndPassword(
      emailController.text,
      passwordController.text,
      context,
    );

    if (authToken != null) {
      print("Login with email+password succeded!");
      context.go('/');
    } else {
      print(
          "Login with email+password failed."); // NOTE the authService handles the popups for user info
    }
  }

  // Future<void> signupWithEmailPassword(BuildContext context) async {
  //  context.go('/a/signup');
  // }

  Future<void> loginWithGoogle(BuildContext context) async {
    final AuthService authService =
        Provider.of<AuthService>(context, listen: false);
    final String? authToken = await authService.signInWithGoogle(context);

    if (authToken != null) {
      print("Login with google succeded!");
      context.go('/m');
    } else {
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
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
              ),
              autofillHints: [AutofillHints.email],
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
              autofillHints: [AutofillHints.password],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              child: Text('Log in'),
              onPressed: () {
                loginWithEmailPassword(context);
              },
            ),
            SizedBox(height: 10),
            Text("- or -"),
            SizedBox(height: 10),
            ElevatedButton(
              child: Text('Sign up'),
              onPressed: () {
                // context.go('/a/signup');
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => SignUpScreen()),
                );
              },
            ),
            SizedBox(height: 10),
            Text("- or -"),
            SizedBox(height: 10),
            ElevatedButton(
              child: Text('Reset password'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => PasswordResetScreen()),
                );
              },
            )
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
