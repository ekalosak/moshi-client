import 'package:flutter/material.dart';

import 'unstructured_chat_app.dart';

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
