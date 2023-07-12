import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
      ),
      body: Center(
        child: ElevatedButton(
          child: Text('Click me'),
          onPressed: () {
            print('Button clicked!');
          },
        ),
      ),
    );
  }
}
