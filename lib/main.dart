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
                  return MainScreen();
                } else {
                  return LoginScreen();
                }
              },
            ),
        '/main': (context) => MainScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/resetpassword': (context) => ResetPasswordScreen(),
        '/settings': (context) => SettingsScreen(authService: _authService),
      },
    );
  }
}
