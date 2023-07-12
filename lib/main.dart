import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/main/chat.dart';
import 'screens/main/main.dart';
import 'screens/main/progress.dart';
import 'screens/main/settings.dart';
import 'screens/auth/login.dart';
import 'screens/auth/password_reset.dart';
import 'screens/auth/sign_up.dart';
import 'services/auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moshi',
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
