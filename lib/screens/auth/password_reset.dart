import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth.dart';

class PasswordResetScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();

  Future<void> resetPassword(BuildContext context) async {
    final AuthService authService = Provider.of<AuthService>(context, listen: false);
    final String? err;
    try {
      err = await authService.sendPasswordResetEmail(emailController.text);
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Password reset email sent!")),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
              ),
            ),
            SizedBox(height: 16),
            FloatingActionButton.extended(
              heroTag: "password_reset",
              label: Text('Reset password'),
              icon: Icon(Icons.login),
              backgroundColor: Theme.of(context).colorScheme.primary,
              onPressed: () async {
                await resetPassword(context);
              },
            )
          ],
        ),
      ),
    );
  }
}
