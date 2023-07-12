import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/main/main.dart';
import 'screens/auth/login.dart';

/// The entrypoint for the Moshi client.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final authToken = prefs.getString('authToken');

  runApp(MyApp(authToken: authToken));
}

/// The wrapper for all widgets. Theme and and an entrypoint.
class MyApp extends StatelessWidget {
  final String? authToken;

  const MyApp({Key? key, required this.authToken}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moshi',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: authToken != null ? MainScreen() : LoginScreen(),
    );
  }
}
