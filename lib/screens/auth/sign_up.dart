import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String? err;

  Future<void> signUp(BuildContext context) async {
    String email = emailController.text;
    String password = passwordController.text;
    String name = firstNameController.text;
    final AuthService authService = Provider.of<AuthService>(context, listen: false);
    if (name == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide a name Moshi can call you.')),
      );
    } else {
      setState(() {
        isLoading = true;
      });
      final String? authToken = await authService.signUpWithEmailAndPassword(
        email,
        password,
        name,
        context,
      );
      setState(() {
        isLoading = false;
      });

      if (authToken != null) {
        print("Signup succeded!");
        Navigator.of(context).pop(); // TODO move this to synchronous code
      } else {
        print("Signup failed."); // NOTE authService handles the popups for user
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (err != null) {
      // If err isn't null, show a snackbar with the error
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err!)),
        );
        setState(() {
          err = null;
        });
      });
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Stack(children: [
          if (isLoading) CircularProgressIndicator(),
          Column(
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
              SizedBox(height: 24),
              FloatingActionButton.extended(
                heroTag: "signup",
                label: Text('Sign up'),
                icon: Icon(Icons.person_add),
                backgroundColor: Theme.of(context).colorScheme.primary,
                onPressed: () async {
                  await signUp(context); // TODO make signUp return err, do the snackbar
                },
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
