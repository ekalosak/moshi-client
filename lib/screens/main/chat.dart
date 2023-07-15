import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../services/auth.dart';

final String healthz = "http://localhost:8080/healthz";
final String mNewConvo = "http://localhost:8080/m/new/unstructured";

Future<bool> healthCheck() async {
  try {
    final response = await http.get(Uri.parse(healthz));
    final code = response.statusCode;
    print("healthz: $code");
    return (code == 200);
  } catch (e) {
    print("Error: $e");
    return false;
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

typedef ErrorHandlingFunction<T> = Future<T> Function();

class AudioException implements Exception {
  final String message;

  AudioException(this.message);

  @override
  String toString() => '$message';
}

void catchErrorAndShowSnackBar(BuildContext context, ErrorHandlingFunction<void> function) async {
  String errorMessage;
  try {
    await function();
  } catch (error) {
    print(error);
    if (error is AudioException) {
      errorMessage = 'An error occurred: ${error.message}. Please try again.';
    } else {
      errorMessage = 'An error occurred. Please try again.';
    }
    final snackBar = SnackBar(content: Text(errorMessage));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

enum ConvoState { ready, started, failed, done }

class _ChatScreenState extends State<ChatScreen> {
  bool isRecording = false;
  bool hasPermissions = false;
  bool isServerHealthy = false;
  ConvoState convoState = ConvoState.ready;
  // final record = AudioRecorder();  // NOTE v5
  final record = Record();
  final player = AudioPlayer();
  final int bitRate = 128000;
  final int sampleRate = 44100;
  final int numChannels = 1;

  void buttonClicked(String whichButton) {
    print('Button clicked: $whichButton');
  }

  void getPermissions() async {
    String? errorMessage;
    print('ChatScreen GetPermissions clicked');
    print('ChatScreen getting / checking microphone permission');
    bool gotPermission = await record.hasPermission();
    setState(() {
      hasPermissions = gotPermission;
    });
  }

  /// Acquire the media resource and begin recording from it.
  void startRecording(BuildContext context) async {
    String? errorMessage;
    print('ChatScreen start button clicked');
    print('ChatScreen getting / checking microphone permission');
    bool hasPermission = await record.hasPermission();
    if (!hasPermission) {
      print('ChatScreen failed to get microphone permission.');
      errorMessage = "Chat requires microphone permissions.";
    } else {
      print('ChatScreen got microphone permission!');
      await record.start(
        bitRate: bitRate,
        samplingRate: sampleRate,
        numChannels: numChannels,
      );
      setState(() {
        isRecording = true;
      });
    }
    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  /// Release the media resource and send the recording to the APIa
  void stopRecording(BuildContext context) async {
    String? errorMessage;
    String? audioPath = await record.stop();
    if (audioPath != null) {
      // TODO send to the API
      print("Got audioPath: $audioPath");
      await player.play(audioPath);
      // await player.play(DeviceFileSource(audioPath));
    } else {
      print("ChatScreen Error: failed to get audioPath from record.stop()");
      errorMessage = "An error occurred, please try again.";
    }
    setState(() {
      isRecording = false;
    });
    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  String getNewConversationButtonText() {
    switch (convoState) {
      case ConvoState.started:
        return "Restart your conversation";
    }
    return "Start a new conversation";
  }

  Future<void> startNewConversation(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser!;
    final token = await user.getIdToken();
    String? cid;
    print("token: $token");
    try {
      final response = await http.get(
        Uri.parse(mNewConvo),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );
      final code = response.statusCode;
      print("m/new/unstructured: $code");
      print("body: ${response.body}");
      if (code == 200) {
        // Map<String, dynamic> json = jsonDecode(response.body);
        // return json['document_id'];
        cid = null;
      } else {
        cid = null;
      }
    } catch (e) {
      print("Error: $e");
      cid = null;
    }
    String msg;
    if (cid != null) {
      msg = "Started conversation.";
    } else {
      msg = "An error occurred, please try again.";
    }
    final snackBar = SnackBar(content: Text(msg));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Press and hold the button to start recording. Release to stop recording.',
            style: TextStyle(fontSize: 16.0),
          ),
          Text(
            isRecording ? "Recording" : "Not recording",
            style: TextStyle(fontSize: 16.0),
          ),
          ElevatedButton(  // healthcheck
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.all(8.0),
            ),
            child: Text(
              isServerHealthy ? 'Server healthy' : 'Check server health',
              style: TextStyle(fontSize: 18.0),
            ),
            onPressed: () async {
              String healthMsg;
              if (await healthCheck()) {
                healthMsg = "Moshi API healthy.";
              } else {
                healthMsg = "Moshi API unhealthy, please try again.";
              }
              final snackBar = SnackBar(content: Text(healthMsg));
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            },
          ),
          ElevatedButton(  // get audio permissions
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.all(8.0),
            ),
            child: Text(
              hasPermissions ? 'Audio access established' : 'Get microphone',
              style: TextStyle(fontSize: 18.0),
            ),
            onPressed: hasPermissions ? null : getPermissions,
          ),
          ElevatedButton(  // start new conversation
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.all(8.0),
            ),
            child: Text(
              getNewConversationButtonText(),
              style: TextStyle(fontSize: 18.0),
            ),
            onPressed: () => startNewConversation(context),
          ),
          GestureDetector(  // TODO error handling for recorder being in wrong state when button up/down
            onTapDown: (_) {
              startRecording(context);
            },
            onTapUp: (_) {
              record.isRecording().then((isRecording) {
                if (isRecording) {
                  stopRecording(context);
                }
              });
            },
            onTapCancel: () {
              record.isRecording().then((isRecording) {
                if (isRecording) {
                  stopRecording(context);
                }
              });
            },
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(8.0),
                ),
                child: Text(
                  isRecording ? 'Recording...' : 'Hold to chat',
                  style: TextStyle(fontSize: 18.0),
                ),
                onPressed: () => buttonClicked('Start recording'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
