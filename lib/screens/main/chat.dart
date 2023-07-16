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

enum ConvoState { ready, started, failed, done }

class _ChatScreenState extends State<ChatScreen> {
  // Resource state
  bool isRecording = false;
  bool hasPermissions = false;
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
      util.showError(context, errorMessage);
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

  // Check API health, get mic. permissions, create conversation in Firestore
  Future<void> startNewConversation(BuildContext context) async {
    print("startNewConversation");
    final bool healthz = await healthCheck();
    (healthz)
      ? print("Moshi API healthy.")
      : print("Moshi API unhealthy, please try again.");

          // ElevatedButton(  // healthcheck
          //   style: ElevatedButton.styleFrom(
          //     padding: EdgeInsets.all(8.0),
          //   ),
          //   child: Text(
          //     isServerHealthy ? 'Server healthy' : 'Check server health',
          //     style: TextStyle(fontSize: 18.0),
          //   ),
          //   onPressed: () async {
          //     String healthMsg;
          //     if (await healthCheck()) {
          //       healthMsg = "Moshi API healthy.";
          //     } else {
          //       healthMsg = "Moshi API unhealthy, please try again.";
          //     }
          //     final snackBar = SnackBar(content: Text(healthMsg));
          //     ScaffoldMessenger.of(context).showSnackBar(snackBar);
          //   },
          // ),
          // ElevatedButton(  // get audio permissions
          //   style: ElevatedButton.styleFrom(
          //     padding: EdgeInsets.all(8.0),
          //   ),
          //   child: Text(
          //     hasPermissions ? 'Audio access established' : 'Get microphone',
          //     style: TextStyle(fontSize: 18.0),
          //   ),
          //   onPressed: hasPermissions ? null : getPermissions,
          // ),
          // ElevatedButton(  // start new conversation
          //   style: ElevatedButton.styleFrom(
          //     padding: EdgeInsets.all(8.0),
          //   ),
          //   child: Text(
          //     (convoState == ConvoState.started)
          //       ? "End conversation"
          //       : "Start a conversation",
          //     style: TextStyle(fontSize: 18.0),
          //   ),
          //   onPressed: () => startNewConversation(context),
          // ),
          // GestureDetector(  // TODO error handling for recorder being in wrong state when button up/down
          //   onTapDown: (_) {
          //     startRecording(context);
          //   },
          //   onTapUp: (_) {
          //     record.isRecording().then((isRecording) {
          //       if (isRecording) {
          //         stopRecording(context);
          //       }
          //     });
          //   },
          //   onTapCancel: () {
          //     record.isRecording().then((isRecording) {
          //       if (isRecording) {
          //         stopRecording(context);
          //       }
          //     });
          //   },
          //   // child: Center(
          //   //   child: ElevatedButton(
          //   //     style: ElevatedButton.styleFrom(
          //   //       padding: EdgeInsets.all(8.0),
          //   //     ),
          //   //     child: Text(
          //   //       isRecording ? 'Recording...' : 'Hold to chat',
          //   //       style: TextStyle(fontSize: 18.0),
          //   //     ),
          //   //     onPressed: () => print("Recording button clicked"),
          //   //   ),
          //   // ),
          // ),
  }

  /// Create a new Conversation document in the backend and set local CID
  Future<void> getNewConversation(BuildContext context) async {
    print("getNewConversation");
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser!;
    final token = await user.getIdToken();
    String? _cid;
    String msg = "An error occurred, please try again.";
    try {  // network request; json decoding
      final response = await http.get(
        Uri.parse(mNewConvo),
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
      );
      final code = response.statusCode;
      print("\tm/new/unstructured: $code");
      if (code == 200) {
        Map<String, dynamic> json = jsonDecode(response.body);
        msg = json['message'];
        _cid = json['detail']['conversation_id'];
        print("\tmsg: $msg");
        print("\tcid: $_cid");
        setState(() {
          cid = _cid;
        });
      } else if (code == 401) {
        print("\tinvalid token");  // TODO refresh the user token
      }
    } catch (e) {
      print("\tError: $e");
    }
    final snackBar = SnackBar(content: Text(msg));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    // TODO use the errorService to show users error messages
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
                    "Microphone permissions: $hasPermissions",
                    style: TextStyle(fontSize: 16.0),
                  ),
                  Text(
                    "$convoState: ${cid?.substring(0, 8) ?? 'inactive'}",
                    style: TextStyle(fontSize: 16.0),
                  ),
                  Text(
                    "Recording: $isRecording",
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
                  await startNewConversation(context);
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
        ],
      ),
    );
  }
}
