import 'package:flutter/material.dart';

import 'screens/main/main.dart';
import 'screens/auth/login.dart';
import 'services/auth.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        final user = snapshot.data;
        if (user != null) {
          return MainScreen(authService: _authService);
        } else {
          return LoginScreen(authService: _authService);
        }
      },
    );
  }
}
