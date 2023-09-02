/// This module routes the user to login if not auth otherwise to main.
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'main/wrapper.dart';
import 'auth/login.dart';

class SwitchScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SwitchScreenState();
}

class _SwitchScreenState extends State<SwitchScreen> {
  User? user;
  late StreamSubscription<User?> _userListener;

  @override
  void initState() {
    super.initState();
    _userListener = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      print("switch: authStateChanges: $user");
      if (user == null) {
        print('switch: User is currently signed out.');
      } else {
        if (user.emailVerified) {
          print('switch: User is signed in.');
        } else {
          print('switch: User is signed in but email is not verified.');
        }
        print('switch: User: ${user.uid}');
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
    print("switch: SwitchScreen.build");
    return (user == null) ? LoginScreen() : WrapperScreen(user: user!);
  }
}
