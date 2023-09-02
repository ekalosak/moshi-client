/// This module provides a signup screen that prompts the user for their email and password.
/// It creates the user in Firebase Auth and then navigates to the profile creation page.
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, FirebaseAuthException, UserCredential;
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  final String initEmail;
  final String initPassword;
  SignUpScreen({required this.initEmail, required this.initPassword});
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

// Prompt user for email and password, create user in Firebase Auth.
Future<String?> _signUpWithEmailAndPassword(String email, String password) async {
  String? err;
  print("_signUpWithEmailAndPassword");
  try {
    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCredential.user;
    await user?.sendEmailVerification();
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

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    emailController.text = widget.initEmail;
    passwordController.text = widget.initPassword;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Create the user in FB Auth.
  Future<String?> _signUp() async {
    String? err;
    String email = emailController.text;
    String password = passwordController.text;
    setState(() {
      isLoading = true;
    });
    err = await _signUpWithEmailAndPassword(email, password);
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
    return err;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            'Create an account',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: Theme.of(context).textTheme.displaySmall!.fontSize,
              fontFamily: Theme.of(context).textTheme.displaySmall!.fontFamily,
            ),
          ),
        ),
        body: Padding(
            padding: EdgeInsets.all(16.0),
            child: Stack(children: [
              if (isLoading) CircularProgressIndicator(),
              Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Let's get started!\nFirst, set your login credentials.",
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: Theme.of(context).textTheme.headlineSmall,
                      ),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: Theme.of(context).textTheme.headlineSmall,
                      ),
                      style: Theme.of(context).textTheme.headlineSmall,
                      obscureText: true,
                    ),
                    SizedBox(height: 24),
                    _signUpButton()
                  ]
                      .map((e) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: e,
                          ))
                      .toList()),
            ])));
  }

  // Button that calls _signUp() and then navigates to the profile creation page.
  FloatingActionButton _signUpButton() => FloatingActionButton.extended(
      heroTag: "signup",
      label: Text(
        'Sign up',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: Theme.of(context).textTheme.headlineSmall!.fontSize,
          fontFamily: Theme.of(context).textTheme.headlineSmall!.fontFamily,
        ),
      ),
      icon: Icon(
        Icons.person_add,
        size: Theme.of(context).textTheme.headlineSmall!.fontSize,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      onPressed: () {
        _signUp().then((err) {
          if (err == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("✅ Account created!\n📧 Please check your email to verify your account."),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
            // Once this exits and the user is logged in, they will be redirected to the profile creation page via home -> main -> profile doesn't exist -> profile creation
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(err)),
              );
            });
          }
        });
      });
}
