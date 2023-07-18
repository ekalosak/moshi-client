import 'dart:async';
import 'dart:convert';  // jsonDecode
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:provider/provider.dart';

import '../../services/auth.dart';
import '../../services/moshi.dart' as moshi;
import '../../util.dart' as util;

const offerEndpoint = "http://localhost:8080/offer";
const connectButtonColor = Colors.tealAccent;
const AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT;
const AUDIO_SOURCE = AudioSource.DEFAULT;
const CHANNEL_CONFIG = ChannelConfig.CHANNEL_IN_MONO;
const SAMPLE_RATE = 16000;

class WebRTCScreen extends StatefulWidget {
  @override
  _WebRTCScreenState createState() => _WebRTCScreenState();
}

class _WebRTCScreenState extends State<WebRTCScreen> {
  bool _moshiHealthy = false;
  bool _isRecording = false;
  bool _isConnected = false;
  Stream<Uint8List>? _micStream;

  @override
  void initState() {
    super.initState();
  }

  /// Clean up the mic stream when the widget is disposed
  @override
  void dispose() {
    _micStream?.dispose();
    super.dispose();
  }

  /// Get mic permissions, check server health, and perform WebRTC connection establishment
  /// Returns error string if any.
  Future<String?> startClicked() async {
    final String? recordingError = await startRecording();
    setState(() {
      _isRecording = (recordingError == null);
    });
    if (recordingError != null) {
      return recordingError;
      // return "Moshi requires microphone permissions. Please enable in your system settings.";
    }
    bool healthy = await moshi.healthCheck();
    setState(() {
      _moshiHealthy = healthy;
    });
    if (!healthy) {
      return "Moshi servers unhealthy, please try again.";
    }
    // TODO connectWebRTC
    await moshi.connectWebRTC();
    setState(() {
      _isConnected = true;
    });
  }

  /// Acquire the microphone and begin recording from it. Idempotent.
  /// Return an error if there is any.
  Future<String?> startRecording() async {
    if (_micStream == null) {
      _micStream = await MicStream.microphone(
        audioFormat: AUDIO_FORMAT,
        audioSource: AUDIO_SOURCE,
        channelConfig: CHANNEL_CONFIG,
        sampleRate: SAMPLE_RATE,
      );
      _micStream?.listen(_onAudioBytes);
      if (_micStream == null) {
        print("Failed to start mic stream.");
        return "Failed to start recording audio from microphone.";
      } else {
        print("Started mic stream.");
      }
    }
  }

  /// This function is meant to be subscribed to the mic. stream.
  /// It consumes the latest available audio and:
  /// TODO updates the audiogram widget,
  /// TODO sends across the WebRTC channel to Moshi servers.
  void _onAudioBytes(Uint8List audioData) {
      print('Received audio data: $audioData');
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
                ],
              ),
            ),
          ),
          Positioned(
            top: 16.0,
            right: 16.0,
            child: FloatingActionButton.extended(  // Start convo
              onPressed: () async {
                final String? err = await startClicked();
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
