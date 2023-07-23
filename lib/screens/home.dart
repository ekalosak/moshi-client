import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'main/main.dart';
import 'auth/login.dart';
import '../services/auth.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print("HomeScreen.build");
    final AuthService authService = Provider.of<AuthService>(context, listen: false);
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          print("Loading authentication service...");
          return Center(
            child: SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(),
            ),
          );
        }
        final user = snapshot.data;
        if (user != null) {
          return MainScreen();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}
