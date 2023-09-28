import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

mixin FirebaseListenerMixin<T extends StatefulWidget> on State<T> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _authStateSubscription;
  List<StreamSubscription> _firebaseListeners = [];

  /// Implement this method in your widget to set up Firebase listeners.
  List<StreamSubscription> initFirebaseListeners();

  @override
  void initState() {
    super.initState();
    _authStateSubscription = _auth.authStateChanges().listen((user) {
      if (user == null) {
        _cancelListeners();
      } else {
        setState(() {
          _firebaseListeners = initFirebaseListeners();
        });
      }
    });
  }

  @override
  void dispose() {
    _cancelListeners();
    _authStateSubscription?.cancel();
    super.dispose();
  }

  void _cancelListeners() {
    for (var subscription in _firebaseListeners) {
      subscription.cancel();
    }
    _firebaseListeners.clear();
  }
}
