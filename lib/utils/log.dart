import 'package:flutter/material.dart';

void showError(BuildContext context, String msg) async {
  print("Error: $msg");
  final snackBar = SnackBar(content: Text(msg));
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

void log(String msg) {
  print(msg);
}
