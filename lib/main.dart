import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'screens/main/chat.dart';
import 'screens/main/main.dart';
import 'screens/main/progress.dart';
import 'screens/main/settings.dart';
import 'screens/auth/login.dart';
import 'screens/auth/password_reset.dart';
import 'screens/auth/sign_up.dart';
import 'services/auth.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App Title',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => StreamBuilder<User?>(
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
            ),
        '/login': (context) => LoginScreen(authService: _authService),
        '/main': (context) => MainScreen(authService: _authService),
      },
    );
  }
}
