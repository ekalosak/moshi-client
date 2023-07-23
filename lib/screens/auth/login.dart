import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/auth.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? err;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<String?> loginWithEmailPassword(AuthService authService) async {
    final String? authToken = await authService.signInWithEmailAndPassword(
      emailController.text,
      passwordController.text,
      context,
    );
    if (authToken != null) {
      return null;
    } else {
      return "Login with email+password failed.";
    }
  }

  // Future<void> loginWithGoogle(BuildContext context) async {
  //   final AuthService authService = Provider.of<AuthService>(context, listen: false);
  //   final String? authToken = await authService.signInWithGoogle(context);
  //   if (authToken != null) {
  //     print("Login with google succeded!");
  //     context.go('/m');
  //   } else {
  //     print("Login with google failed.");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Provider.of<AuthService>(context, listen: false);
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingActionButton.extended(
                      heroTag: "signup",
                      label: Text('Sign up'),
                      icon: Icon(Icons.person_add),
                      onPressed: () {
                        context.go('/a/signup');
                      },
                    ),
                  ],
                ),
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
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: FloatingActionButton.extended(
                    heroTag: "login",
                    label: Text('Log in'),
                    icon: Icon(Icons.login),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    onPressed: () async {
                      err = await loginWithEmailPassword(authService);
                      setState(() {
                        err = err;
                      });
                    },
                  ),
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
                          context.go('/a/reset');
                        },
                      ),
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
