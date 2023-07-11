import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCApp extends StatefulWidget {
  @override
  _WebRTCAppState createState() => _WebRTCAppState();
}

class _WebRTCAppState extends State<WebRTCApp> {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final _dataChannelLabel1 = 'status';
  final _dataChannelLabel2 = 'transcript';
  RTCDataChannel? _dataChannel1;
  RTCDataChannel? _dataChannel2;

  @override
  void initState() {
    super.initState();
    _initWebRTC();
  }

  void _initWebRTC() async {
    await _createPeerConnection();
    await _getUserMedia();
    await _createDataChannels();
  }

  Future<void> _createPeerConnection() async {
    final configuration = <String, dynamic>{
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection?.onIceCandidate = (candidate) {
      // Handle ICE candidates if needed
    };

    _peerConnection?.onAddStream = (stream) {
      // Handle remote stream if needed
    };
  }

  Future<void> _getUserMedia() async {
    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': false,
    };

    final stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    setState(() {
      _localStream = stream;
    });

    _peerConnection?.addStream(stream);
  }

  Future<void> _createDataChannels() async {
    final dataChannel1Init = RTCDataChannelInit();
    _dataChannel1 = await _peerConnection?.createDataChannel(_dataChannelLabel1, dataChannel1Init);

    final dataChannel2Init = RTCDataChannelInit();
    _dataChannel2 = await _peerConnection?.createDataChannel(_dataChannelLabel2, dataChannel2Init);
  }

  @override
  Widget build(BuildContext context) {
    // Implement your UI here
    return Scaffold(
      appBar: AppBar(
        title: Text('WebRTC App'),
      ),
      body: Center(
        child: Text('WebRTC App'),
      ),
    );
  }
}
