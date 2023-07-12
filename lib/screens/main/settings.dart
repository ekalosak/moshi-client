import 'package:flutter/material.dart';
import '../../services/auth.dart';

class SettingsScreen extends StatelessWidget {
  final AuthService authService;

  SettingsScreen({required this.authService});

  Future<void> logOut(BuildContext context) async {
    try {
      await authService.signOut(context);
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again later.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Center(
        child: ElevatedButton(
          child: Text('Log Out'),
          onPressed: () {
            logOut(context);
          },
        ),
      ),
    );
  }
}
