import 'dart:async';
import 'dart:convert';  // jsonDecode
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:flutter/services.dart';

import '../../services/auth.dart';
import '../../services/moshi.dart' as moshi;
import '../../util.dart' as util;

const offerEndpoint = "http://localhost:8080/offer";
const connectButtonColor = Colors.tealAccent;

class WebRTCScreen extends StatefulWidget {
  @override
  _WebRTCScreenState createState() => _WebRTCScreenState();
}

class _WebRTCScreenState extends State<WebRTCScreen> {
  MediaStream? _localStream;
  List<MediaDeviceInfo>? _mediaDevicesList;
  RTCPeerConnection? _pc;
  RTCDataChannel? _ping;
  RTCDataChannel? _status;
  RTCDataChannel? _transcript;
  bool _moshiHealthy = false;
  bool _isRecording = false;
  bool _isConnected = false;

  /// TODO updates the audiogram widget,
  /// TODO sends across the WebRTC channel to Moshi servers.

  @override
  void initState() {
    super.initState();
  }

  /// Clean up the mic stream when the widget is disposed
  @override
  void dispose() async {
    super.dispose();
    await _localStream?.dispose();
    await _pc?.dispose();
  }

  /// Get mic permissions, check server health, and perform WebRTC connection establishment
  /// Returns error string if any.
  Future<String?> startPressed() async {
    print("startPressed start");
    // Backend server check
    bool healthy = await moshi.healthCheck();
    setState(() {
      _moshiHealthy = healthy;
    });
    if (!healthy) {
      return "Moshi servers unhealthy, please try again.";
    }
    // Microphone check
    final String? err = await startRecording();
    if (err != null) {
      return err;
      // return "Moshi requires microphone permissions. Please enable in your system settings.";
    }
    print("startPressed end");
  }

  Future<String?> stopPressed() async {
    print("stopPressed start");
    await stopRecording();
    setState(() {
      _isConnected = false;  // TODO hangUp();
    });
    print("stopPressed end");
  }

  /// Acquire the microphone and begin recording from it. Idempotent.
  /// Return an error if there is any.
  Future<String?> startRecording() async {
    print("starting recording");
    try {
      final mediaConstraints = <String, dynamic>{
        'audio': true,
        'video': false
      };
      var stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _mediaDevicesList = await navigator.mediaDevices.enumerateDevices();
      print("_mediaDevicesList.length: ${_mediaDevicesList?.length}");
      for (var md in (_mediaDevicesList ?? [])) {
        print("media device: ${md.label}");
      }
      _localStream = stream;
      setState(() {
        _isRecording = true;
      });
    } catch (error) {
      print(error);
    }
    await callMoshi();
    print("started recording");
  }

  Future<void> stopRecording() async {
    print("stopping");
    await _localStream?.dispose();
    setState(() {
      _isRecording = false;
    });
    print("stopped");
  }

  /// Create peer connections, create data channels, and listen for tracks
  // TODO
  Future<void> callMoshi() async {
    print("callMoshi start");
    if (_pc != null) return;
    try {
      final pcConfig ={
        'sdpSemantics': 'unified-plan',
      };
      _pc = await createPeerConnection(pcConfig);
      print("created pc: $_pc \n\tconnectionState : ${_pc?.connectionState}");
    } catch (error) {
      print("callMoshi Error: $error");
    }
    setState(() {
      _isConnected = true;
    });
    print("callMoshi end");
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    return Container(
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Moshi healthy: $_moshiHealthy",
                    style: TextStyle(fontSize: 16.0),
                  ),
                  Text(
                    "Recording: $_isRecording",
                    style: TextStyle(fontSize: 16.0),
                  ),
                  Text(
                    "Connected: $_isConnected",
                    style: TextStyle(fontSize: 16.0),
                  ),
                  // Text(
                  //   "Sample rate: $_sampleRate",
                  //   style: TextStyle(fontSize: 16.0),
                  // ),
                  // Text(
                  //   "Seconds recording: ${_secRec.toStringAsFixed(2)}",
                  //   style: TextStyle(fontSize: 16.0),
                  // ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 16.0,
            right: 16.0,
            child: FloatingActionButton.extended(  // Start convo
              onPressed: () async {
                final String? err = (_isRecording)
                  ? await stopPressed()
                  : await startPressed();
                if (err != null) {
                  util.showError(context, err);
                }
              },
              label: Text(
                (_isConnected)
                  ? 'Hang up'
                  : 'Call Moshi',
              ),
              icon: Icon(
                (_isConnected)
                  ? Icons.call_end
                  : Icons.add_call,
              ),
              backgroundColor: Colors.purple[800],
            ),
          ),
        ],
      ),
    );
  }
}
