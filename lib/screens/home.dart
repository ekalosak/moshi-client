import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'main/main.dart';
import 'auth/login.dart';
import '../services/auth.dart';

class HomeScreen extends StatelessWidget {
  final AuthService authService;

  HomeScreen({required this.authService});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: StreamBuilder<User?>(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();  // TODO this can brick the app
          }
          final user = snapshot.data;
          if (user != null) {
            return MainScreen(authService: authService);
          } else {
            return LoginScreen(authService: authService);
          }
        },
      ),
    );
  }
}
