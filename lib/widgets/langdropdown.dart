import 'package:flutter/material.dart';

// make the Profile optional
DropdownButtonFormField<String> languageDropdown(
  List<String> slans, {
  String? lang,
  String? prompt,
}) {
  String primaryLang = lang ?? slans[0];
  String label = prompt ?? 'Native language';
  return DropdownButtonFormField<String>(
    decoration: InputDecoration(
      labelText: label,
    ),
    value: primaryLang,
    items: slans.map((String value) {
      return DropdownMenuItem<String>(
        value: value,
        // child: Text("${getLangEmoji(value)} ${value.toUpperCase()}"),
        child: Text(value),
      );
    }).toList(),
    onChanged: (String? newValue) {
      primaryLang = newValue!;
    },
  );
}
