import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'signaling.dart';

class UnstructuredChatApp extends StatefulWidget {
  @override
  _UnstructuredChatApp createState() => _UnstructuredChatApp();
}

class _UnstructuredChatApp extends State<UnstructuredChatApp> {
  bool _connected = false;
  String _server = 'localhost:8080';  // TODO www.chatmoshi.com
  Signaling? _signaling;

  @override
  void initState() {
    super.initState();
    print("initState");
  }

  void _connectWebRTC() async {
    print("_connectWebRTC");
    // TODO use the signaling connect functionality
    await _createDataChannels();
    setState(() {
      _connected = true;
    });
  }

  void _disconnectWebRTC() async {
    print("_disconnectWebRTC");
    // TODO use the signaling disconnect functionality
    setState(() {
      _connected = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Moshi'),
          ),
        body: Center(
          child: Column(
            children: <Widget>[
              Text('is a spoken language tutor.'),
              FilledButton(
                  onPressed: _connected ? _disconnectWebRTC : _connectWebRTC,
                  child: _connected ? Text("Disconnect") : Text("Connect"),
              ),
              _connected ? Text("_connected is true") : Text("_connected is false"),
            ],
          )
        ),
      ),
    );
  }
}
