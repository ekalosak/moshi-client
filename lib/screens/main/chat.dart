import 'dart:io';
import 'dart:convert';  // jsonDecode

import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../services/auth.dart';
import '../../util.dart' as util;

final String healthz = "http://localhost:8080/healthz";
final String mNewConvo = "http://localhost:8080/m/new/unstructured";

Future<bool> healthCheck() async {
  print("healthCheck");
  try {
    final response = await http.get(Uri.parse(healthz));
    final code = response.statusCode;
    print("\t/healthz: $code");
    return (code == 200);
  } catch (e) {
    print("\tError: $e");
    return false;
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

enum ConvoState { ready, started, failed, done }

class _ChatScreenState extends State<ChatScreen> {
  // Resource state
  bool isRecording = false;
  bool haveMicPermissions = false;
  bool isServerHealthy = false;
  // Conversation state
  ConvoState convoState = ConvoState.ready;
  String? cid;
  // Audio state
  final record = Record();
  final player = AudioPlayer();
  final int bitRate = 128000;
  final int sampleRate = 44100;
  final int numChannels = 1;

  void getPermissions() async {
    String? errorMessage;
    print('ChatScreen GetPermissions clicked');
    print('ChatScreen getting / checking microphone permission');
    bool gotPermission = await record.hasPermission();
    setState(() {
      haveMicPermissions = gotPermission;
    });
  }

  /// Acquire the media resource and begin recording from it.
  /// Return error message.
  Future<String?> startRecording(BuildContext context) async {
    bool micPerm = await record.hasPermission();
    if (!micPerm) {
      return "Microphone permissions required for chat. Please enable in your system settings.";
    } else {
      print("\tStarting to record...");
      await record.start(
        bitRate: bitRate,
        samplingRate: sampleRate,
        numChannels: numChannels,
      );
      setState(() {
        isRecording = true;
      });
      print("\tRecording started.");
    }
  }

  /// Release the media resource
  /// Return error string
  Future<String?> stopRecording() async {
    String? audioPath = await record.stop();
    if (audioPath == null) {
      return "An error occurred while listening, please try again.";
    }
    setState(() {
      isRecording = false;
    });
  }

  /// Send the recording to the API
  Future<void> sendUtterance(String audioPath) async {
    print("Got audioPath: $audioPath");
    await player.play(audioPath);
    // TODO send to the API
    // await player.play(DeviceFileSource(audioPath));
  }

  // Check API health, get mic. permissions, create conversation in Firestore
  Future<String?> startNewConversation(BuildContext context) async {
    print("startNewConversation");
    String? msg;
    final bool micPerm = await record.hasPermission();
    setState(() {
      haveMicPermissions = micPerm;
    });
    if (!micPerm) {
      return "Microphone permissions required for chat. Please enable in your system settings.";
    } else {
      print("\tmicrophone permissions allowed");
      await record.dispose();
    }
    final bool healthz = await healthCheck();
    setState(() {
      isServerHealthy = healthz;
    });
    if (!healthz) {
      return "Moshi servers unhealthy, please try again.";
    } else {
      print("\tmoshi api healthy");
    }
    final authService = Provider.of<AuthService>(context, listen: false);
    final String? erMsg = await getNewConversation(authService);
    if (erMsg != null) {
      return erMsg;
    }
  }

  /// Create a new Conversation document in the backend and set local CID
  /// Return an error message if one occurred.
  Future<String?> getNewConversation(AuthService authService) async {
    print("getNewConversation");
    final user = authService.currentUser!;
    final token = await user.getIdToken();
    try {  // network request; json decoding
      final response = await http.get(
        Uri.parse(mNewConvo),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );
      final code = response.statusCode;
      print("\t/m/new/unstructured: $code");
      if (code == 200) {
        Map<String, dynamic> json = jsonDecode(response.body);
        final String msg = json['message'];
        final String _cid = json['detail']['conversation_id'];
        print("\tmsg: $msg");
        print("\tcid: $_cid");
        setState(() {
          cid = _cid;
          convoState = ConvoState.started;
        });
        return null;
      } else if (code == 401) {
        // NOTE https://firebase.google.com/docs/auth/flutter/start persisting auth state on web
        print("\tinvalid token");  // TODO refresh the user token? Firebase says tokens are long lived: https://firebase.google.com/docs/auth/admin/manage-sessions
        print("\tTODO");
        return "Need to refresh authentication tokens, please try again.";
      } else {
        return "Server error: $code";
      }
    } catch (e) {
      print("\tError: $e");
      return "An error occurred, please try again.";
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    "Microphone permissions: $haveMicPermissions",
                    style: TextStyle(fontSize: 16.0),
                  ),
                  Text(
                    "Recording: $isRecording",
                    style: TextStyle(fontSize: 16.0),
                  ),
                  Text(
                    convoState.toString(),
                    // (convoState != ConvoState.started)
                    //   ? "Conversation: ${cid?.substring(0, 8)}"
                    //   : "Conversation: inactive",
                    style: TextStyle(fontSize: 16.0),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: FloatingActionButton.extended(  // Start convo
              onPressed: () async {
                if (convoState != ConvoState.started) {
                  final String? erMsg = await startNewConversation(context);
                  if (erMsg != null) {
                    util.showError(context, erMsg);
                  }
                } else {
                  print("startButton\n\tconvoState: $convoState");
                  print("TODO");
                }
              },
              label: Text(
                (convoState != ConvoState.started)
                  ? 'Start conversation'
                  : 'Restart conversation',
              ),
              icon: Icon(
                (convoState != ConvoState.started)
                  ? Icons.touch_app
                  : Icons.restart_alt,
              ),
              backgroundColor: Colors.pink,
            ),
          ),
          Positioned(
            bottom: 48.0,
            right: 128.0,
            child: GestureDetector(
              // child: Icon(Icons.add),
              // TODO error handling for recorder being in wrong state when button up/down
              onTapDown: (_) {
                print("\tonTapDown");
                // startRecording(context);
              },
              onTapUp: (_) {
                print("\tonTapUp");
                // record.isRecording().then((isRecording) {
                //   if (isRecording) {
                //     stopRecording(context);
                //   }
                // });
              },
              onTapCancel: () {
                print("\tonTapCancel");
                // record.isRecording().then((isRecording) {
                //   if (isRecording) {
                //     stopRecording(context);
                //   }
                // });
              },
              child: FloatingActionButton(
                onPressed: () => print("\tonPressed"),
                // onPressed:  ? null : () => print("\tonPressed"),
                child: Icon(Icons.add),
                // NOTE onPressed null doesn't disable button: https://github.com/flutter/flutter/issues/107480
                backgroundColor: (convoState != ConvoState.started) ? Colors.grey : Colors.pink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
