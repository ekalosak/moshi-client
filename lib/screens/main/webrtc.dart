import 'dart:async';
import 'dart:convert';  // jsonDecode
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_streamer/audio_streamer.dart';
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
  AudioStreamer streamer = AudioStreamer();
  // List<double> _audio = [];
  bool _moshiHealthy = false;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isConnected = false;
  int _sampleRate = 0;
  double _secRec = 0.0;

  /// TODO updates the audiogram widget,
  /// TODO sends across the WebRTC channel to Moshi servers.
  void onAudio(List<double> buffer) async {
    // _audio.addAll(buffer);
    var sampleRate = await streamer.actualSampleRate;
    double secondsRecorded = _secRec + buffer.length.toDouble() / sampleRate;
    setState(() {
      _sampleRate = sampleRate;
      _secRec = secondsRecorded;
    });
  }

  void handleError(PlatformException error) {
    print(error);
  }

  @override
  void initState() {
    super.initState();
  }

  /// Clean up the mic stream when the widget is disposed
  @override
  void dispose() {
    super.dispose();
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
    setState(() {
      _isRecording = (err == null);
    });
    if (err != null) {
      return err;
      // return "Moshi requires microphone permissions. Please enable in your system settings.";
    }
    // TODO connectWebRTC
    await moshi.connectWebRTC();
    setState(() {
      _isConnected = true;
    });
  }

  Future<String?> stopPressed() async {
    print("stopPressed start");
    await stopRecording();
    setState(() {
      _isConnected = false;
    });
  }

  /// Acquire the microphone and begin recording from it. Idempotent.
  /// Return an error if there is any.
  Future<String?> startRecording() async {
    print("starting recording");
    try {
      streamer.start(onAudio, handleError);  // 44.1kHz
      setState(() {
        _isRecording = true;
      });
    } catch (error) {
      print(error);
    }
    print("started recording");
  }

  Future<void> stopRecording() async {
    print("stopping");
    bool stopped = await streamer.stop();
    setState(() {
      _isRecording = stopped;
    });
    print("stopped");
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
                  Text(
                    "Sample rate: $_sampleRate",
                    style: TextStyle(fontSize: 16.0),
                  ),
                  Text(
                    "Seconds recording: ${_secRec.toStringAsFixed(2)}",
                    style: TextStyle(fontSize: 16.0),
                  ),
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
