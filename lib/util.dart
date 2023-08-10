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
    case 'en-US':
      return '🇺🇸';
    case 'es-MX':
      return '🇲🇽';
    case 'es-ES':
      return '🇪🇸';
    case 'fr-FR':
      return '🇫🇷';
    case 'fr-CA':
      return '🇨🇦';
    case 'it-IT':
      return '🇮🇹';
    case 'de-DE':
      return '🇩🇪';
    case 'ja-JP':
      return '🇯🇵';
    case 'ko-KR':
      return '🇰🇷';
    case 'cmn-CN':
      return '🇨🇳';
    case 'cmn-TW':
      return '🇹🇼';
    case 'cmn-HK':
      return '🇭🇰';
    case '':
      return '🌎';
    default:
      return lang;
  }
}
