import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth.dart';

class ProgressScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AuthService authService = Provider.of<AuthService>(context, listen: false);
    final User? user = authService.currentUser;
    final String firstName = user?.displayName ?? 'MissingName';
    print("ProgressScreen firstName: $firstName");
    return Column(children: [
      SizedBox(height: 16),
      Flexible(
        flex: 1,
        child: Text('Welcome, $firstName!'),
      ),
      Flexible(
        flex: 9,
        child: Container(),
      ),
    ]);
  }
}
