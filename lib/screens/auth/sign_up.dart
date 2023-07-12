import 'package:flutter/material.dart';
import '../../services/auth.dart';

class SignUpScreen extends StatelessWidget {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService;
  final Function(String) loginCallback;

  SignUpScreen({required this.authService, required this.loginCallback});

  Future<void> signUp(BuildContext context) async {
    final String? authToken = await authService.signUpWithEmailAndPassword(
      emailController.text,
      passwordController.text,
      firstNameController.text,
    );

    if (authToken != null) {
      loginCallback(authToken);
    } else {
      print("Signup failed");
      // TODO Handle signup error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: firstNameController,
              decoration: InputDecoration(
                labelText: 'First Name',
              ),
            ),
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
              child: Text('Sign Up'),
              onPressed: () {
                signUp(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
