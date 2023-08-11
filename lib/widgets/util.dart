import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:moshi/screens/home.dart';

/// Ensure the user is authorized to view the page.
Widget authorized(BuildContext context, Widget widg) {
  User? user_ = FirebaseAuth.instance.currentUser;
  if (user_ == null) {
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => HomeScreen()), (route) => false);
  }
  return widg;
}
