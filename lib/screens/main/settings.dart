import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: FloatingActionButton.extended(
        heroTag: "logout",
        label: Text('Log out'),
        icon: Icon(Icons.logout),
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
        },
      ),
    );
  }
}
