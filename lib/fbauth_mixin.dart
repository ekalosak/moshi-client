import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

mixin FirebaseListenerMixin<T extends StatefulWidget> on State<T> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _authStateSubscription;
  List<StreamSubscription> _firebaseListeners = [];

  // Implement this method in your widget to set up Firebase listeners.
  void initFirebaseListeners();

  @override
  void initState() {
    super.initState();
    _authStateSubscription = _auth.authStateChanges().listen((user) {
      if (user == null) {
        _cancelListeners();
      } else {
        initFirebaseListeners();
      }
    });
  }

  @override
  void dispose() {
    _cancelListeners();
    _authStateSubscription?.cancel();
    super.dispose();
  }

  // Method to cancel Firebase listeners.
  void _cancelListeners() {
    for (var subscription in _firebaseListeners) {
      subscription.cancel();
    }
    _firebaseListeners.clear();
  }
}

class ExampleFBAuthWidget extends StatefulWidget {
  @override
  _ExampleFBAuthWidgetState createState() => _ExampleFBAuthWidgetState();
}

class _ExampleFBAuthWidgetState extends State<ExampleFBAuthWidget> with FirebaseListenerMixin {
  @override
  void initFirebaseListeners() {
    // Initialize your Firebase listeners here.
    // Example:
    // _firebaseListeners.add(someFirestoreStream.listen((data) {
    //   // Handle data from Firestore.
    // }));
  }

  @override
  Widget build(BuildContext context) {
    return Text("Demo");
  }
}
