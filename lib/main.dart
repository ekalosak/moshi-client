import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/main/main.dart';
import 'screens/auth/login.dart';
import 'services/auth.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? authToken;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final token = await _authService.getToken();
    setState(() {
      authToken = token;
    });
  }

  void loginCallback(String token) {
    setState(() {
      authToken = token;
    });
  }

  void logoutCallback() {
    _authService.removeToken();
    setState(() {
      authToken = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: authToken != null
          ? MainScreen(authService: _authService, logoutCallback: logoutCallback)
          : LoginScreen(authService: _authService, loginCallback: loginCallback),
    );
  }
}
