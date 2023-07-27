import 'package:flutter/material.dart';

void showError(BuildContext context, String msg) async {
  print("Error: $msg");
  final snackBar = SnackBar(content: Text(msg));
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

void log(String msg) {
  print(msg);
}

String getLangEmoji(String lang) {
  switch (lang) {
    case 'en':
      return '🇺🇸';
    case 'es':
      return '🇲🇽';
    case 'fr':
      return '🇫🇷';
    case 'de':
      return '🇩🇪';
    case 'ja':
      return '🇯🇵';
    case 'ko':
      return '🇰🇷';
    case 'zh':
      return '🇨🇳';
    default:
      return lang;
  }
}
