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
  late AuthService authService;
  String? err;

  @override
  void initState() {
    print("LoginScreen.initState");
    authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser != null) {
      context.go('/m');
    }
    super.initState();
  }

  @override
  void dispose() {
    print("LoginScreen.dispose");
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<String?> loginWithEmailPassword() async {
    final String? err = await authService.signInWithEmailAndPassword(
      emailController.text,
      passwordController.text,
    );
    if (err != null) {
      return null;
    } else {
      return "Login with email+password failed.";
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
                          err = await loginWithEmailPassword();
                          setState(() {
                            err = err;
                          });
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
                          context.go('/a/reset');
                        },
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: FloatingActionButton.extended(
                          heroTag: "signup",
                          label: Text('Sign up'),
                          icon: Icon(Icons.person_add),
                          onPressed: () {
                            context.go('/a/signup');
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
