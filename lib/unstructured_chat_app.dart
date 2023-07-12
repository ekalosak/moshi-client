import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'signaling.dart';

class UnstructuredChatApp extends StatefulWidget {
  static String tag = 'unstructured_audio_chat';
  @override
  _UnstructuredChatApp createState() => _UnstructuredChatApp();
}

class _UnstructuredChatApp extends State<UnstructuredChatApp> {
  Signaling? _signaling;
  Session? _session;
  bool _connected = false;
  String _server = 'localhost';  // TODO www.chatmoshi.com
  String _port = '8080';

  @override
  void initState() {
    print("initState");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print("build");
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
                  onPressed: _connected ? _disconnect : _connect,
                  child: _connected ? Text("Disconnect") : Text("Connect"),
              ),
              _connected ? Text("_connected is true") : Text("_connected is false"),
            ],
          )
        ),
      ),
    );
  }

  void _connect(BuildContext context) async {
    print("_connect");
    _signaling ??= Signaling(_server, _port, context)..connect();
    _signaling?.onConnectionStateChange = (Session session, ConnectionState state) async {
      print("\tonConnectionStateChange state: $state");
      print("\tonConnectionStateChange session: $session");
      switch (state) {
        case ConnectionState.New:
          setState(() {
            _session = session;
          });
          break;
    setState(() {
      _connected = true;
    });
  }

  void _disconnect() async {
    print("_disconnect");
    await _signaling?.close();
    setState(() {
      _connected = false;
    });
  }
}
