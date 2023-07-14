import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth.dart';

class ProgressScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Provider.of<AuthService>(context, listen: false);
    final User? user = authService.currentUser;
    // print("ProgressScreen user: $user");  // NOTE prints refresh token
    final String? firstName = user?.displayName ?? 'MissingName';
    print("ProgressScreen firstName: $firstName");
    return Center(
      child: Text('Welcome, $firstName!'),
    );
  }

}
