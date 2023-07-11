import 'package:flutter/material.dart';

void main() {
  runApp(MoshiApp());
}

class MoshiApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moshi',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: UnstructuredChatApp(),
    );
  }
}
