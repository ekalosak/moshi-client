import 'package:flutter/material.dart';

import '../../services/auth.dart';
import 'login.dart';
import 'password_reset.dart';
import 'sign_up.dart';

class AuthScreen extends StatefulWidget {
  final AuthService authService;

  AuthScreen({required this.authService});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int _currentIndex = 0;
  late AuthService _authService; // Declare a local variable

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _authService = widget.authService; // Assign authService to the local variable
    _screens.addAll([
      LoginScreen(authService: _authService),
      SignUpScreen(authService: _authService),
      PasswordResetScreen(authService: _authService),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Moshi Authentication'),
      ),
      body: _screens[_currentIndex],
    );
  }
}
