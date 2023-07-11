import 'package:flutter/material.dart';
import 'web_rtc_app.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebRTC App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WebRTCApp(),
    );
  }
}
