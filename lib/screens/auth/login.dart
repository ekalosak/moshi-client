import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:moshi_client/screens/main/main.dart';
import 'password_reset.dart';
import 'sign_up.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<String?> loginWithEmailPassword() async {
    String? err;
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: LayoutBuilder(builder: (context, constraints) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 1,
                child: Container(),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
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
                    Padding(
                      padding: EdgeInsets.all(24),
                      child: FloatingActionButton.extended(
                        heroTag: "login",
                        label: Text('Log in'),
                        icon: Icon(Icons.login),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        onPressed: () async {
                          String? err = await loginWithEmailPassword();
                          if (err != null) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(err)),
                              );
                            });
                          } else if (mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => MainScreen(user: FirebaseAuth.instance.currentUser!),
                              ),
                              (route) => false,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton.extended(
                        heroTag: "reset",
                        label: Text('Reset password'),
                        icon: Icon(Icons.lock),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PasswordResetScreen(),
                            ),
                          );
                        },
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: FloatingActionButton.extended(
                          heroTag: "signup",
                          label: Text('Sign up'),
                          icon: Icon(Icons.person_add),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => SignUpScreen(),
                              ),
                            );
                          },
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
