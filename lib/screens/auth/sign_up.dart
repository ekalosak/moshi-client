import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/auth.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController firstNameController = TextEditingController();
  // TODO language controller; initState(); make it have flags for each language.
  // final TextEditingController firstNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String? err;

  @override
  void dispose() {
    firstNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<String?> signUp() async {
    String? err;
    String email = emailController.text;
    String password = passwordController.text;
    String name = firstNameController.text;
    final AuthService authService = Provider.of<AuthService>(context, listen: false);
    // TODO add language selector
    // TODO take language from selector, make new profile in Firebase.
    //  - collection profiles
    //  - document uid
    if (name == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide a name Moshi can call you.')),
      );
      return "Please provide a name Moshi can call you.";
    } else {
      setState(() {
        isLoading = true;
      });
      err = await authService.signUpWithEmailAndPassword(email, password, name);
      setState(() {
        isLoading = false;
      });

      if (err == null) {
        print("Signup succeded!");
      } else {
        print("Signup failed: $err");
      }
      return err;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (err != null) {
      // If err isn't null, show a snackbar with the error
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
                  final String? err = await signUp();
                  if (err == null) {
                    context.go('/m');
                  } else {
                    setState(() {
                      this.err = err;
                    });
                  }
                },
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
