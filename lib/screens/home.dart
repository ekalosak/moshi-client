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
        print('home: User is currently signed out.');
      } else {
        if (user.emailVerified) {
          print('home: User is signed in.');
        } else {
          print('home: User is signed in but email is not verified.');
        }
        print('home: User: ${user.uid}');
      }
      setState(() {
        this.user = user;
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
    print("home: HomeScreen.build");
    return (user == null) ? LoginScreen() : MainScreen(user: user!);
  }
}
