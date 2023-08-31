import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// class PasswordResetScreen extends StatelessWidget {
// stateful widget
class PasswordResetScreen extends StatefulWidget {
  @override
  _PasswordResetScreenState createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final TextEditingController emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<String?> _resetPassword(BuildContext context) async {
    String? err;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text);
    } catch (e) {
      RegExp regExp = RegExp(r"\[.*?\]");
      err = "$e".replaceAll(regExp, "");
    }
    return err;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reset Password',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: Theme.of(context).textTheme.displaySmall!.fontSize,
            fontFamily: Theme.of(context).textTheme.displaySmall!.fontFamily,
          ),
        ),
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
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground,
                  fontSize: Theme.of(context).textTheme.headlineSmall!.fontSize,
                  fontFamily: Theme.of(context).textTheme.headlineSmall!.fontFamily,
                ),
              ),
            ),
            SizedBox(height: 16),
            FloatingActionButton.extended(
              heroTag: "password_reset",
              label: Text(
                'Send reset',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: Theme.of(context).textTheme.headlineSmall!.fontSize,
                  fontFamily: Theme.of(context).textTheme.headlineSmall!.fontFamily,
                ),
              ),
              icon: Icon(
                Icons.lock_reset,
                size: Theme.of(context).textTheme.headlineSmall!.fontSize,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              onPressed: () async {
                final String? err = await _resetPassword(context);
                if (err == null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Password reset email sent!")),
                  );
                  Navigator.pop(context);
                } else if (err != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
