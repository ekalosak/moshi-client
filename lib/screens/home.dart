/// This module routes the user to login if not auth otherwise to main.
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'main/main.dart';
import 'auth/login.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? user;
  late StreamSubscription<User?> _userListener;

  @override
  void initState() {
    super.initState();
    _userListener = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print('User is currently signed out.');
      } else {
        print('User is signed in.');
      }
      setState(() {
        this.user = null;
      });
    });
  }

  @override
  void dispose() {
    _userListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("HomeScreen.build");
    return (user == null) ? LoginScreen() : MainScreen(user: user!);
  }
}
