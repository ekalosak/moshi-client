import 'package:flutter/material.dart';

Future<void> showError(BuildContext context, String msg) async {
  final snackBar = SnackBar(content: Text(msg));
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

