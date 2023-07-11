import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'signaling.dart';

class WebRTCApp extends StatefulWidget {
  @override
  _WebRTCAppState createState() => _WebRTCAppState();
}

class _WebRTCAppState extends State<WebRTCApp> {
  // This is half from ChatGPT and half from the futter-webrtc-demo on GitHub
  bool _connected = false;
  String _server = 'localhost:8080';
  // String _server = 'www.chatmoshi.com';
  Signaling? _signaling;
  final _dataChannelLabel = 'datachannel';
  RTCDataChannel? _dataChannel;

  @override
  void initState() {
    super.initState();
    print("initState");
  }

  void _connectWebRTC() async {
    print("_connectWebRTC");
    // TODO use the signaling connect functionality
    await _getUserMedia();
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

  Future<void> _getUserMedia() async {
    print("_getUserMedia");
    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': false,
    };

    final stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    setState(() {
      _localStream = stream;
    });

    print("\tstream: $stream");
    _peerConnection?.addStream(stream);
  }

  Future<void> _createDataChannels() async {
    print("_createDataChannels");
    final dataChannelInit = RTCDataChannelInit();
    _dataChannel = await _peerConnection?.createDataChannel(_dataChannelLabel, dataChannelInit);
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
