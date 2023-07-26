import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/auth.dart';

class SettingsScreen extends StatelessWidget {
  Future<void> logOut(BuildContext context) async {
    final AuthService authService = Provider.of<AuthService>(context, listen: false);
    try {
      await authService.signOut();
      context.go('/');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again later.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FloatingActionButton.extended(
        heroTag: "logout",
        label: Text('Log out'),
        icon: Icon(Icons.logout),
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: () {
          logOut(context);
        },
      ),
    );
  }
}
