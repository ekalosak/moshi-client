import 'dart:async';
import 'dart:convert';  // jsonDecode
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../services/auth.dart';
import '../../util.dart' as util;

final String host = "http://localhost:8080";
final String healthz = "http://localhost:8080/healthz";
final String mNewConvo = "http://localhost:8080/m/new/unstructured";

final Color recordButtonColor = Colors.tealAccent;
// final Color recordButtonColor = Color(int.parse("FAEB54", radix: 16));

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
  bool haveMicPermissions = false;
  bool isServerHealthy = false;
  bool isRecording = false;
  // Conversation state
  ConvoState convoState = ConvoState.ready;
  String? cid;
  // Audio state
  final _audioRecorder = Record();
  StreamSubscription<RecordState>? _recordSub;
  RecordState _recordState = RecordState.stop;  // NOTE this doesn't get updated...
  final player = AudioPlayer();
  final int bitRate = 128000;
  final int sampleRate = 44100;
  final int numChannels = 1;

  @override
  void initState() {
    super.initState();
    _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
      print("_audioRecorder state change: $recordState");
      setState(() => _recordState = recordState);
    });
  }

  void getPermissions() async {
    String? errorMessage;
    print('ChatScreen GetPermissions clicked');
    print('ChatScreen getting / checking microphone permission');
    bool gotPermission = await _audioRecorder.hasPermission();
    setState(() {
      haveMicPermissions = gotPermission;
    });
  }

  /// Acquire the media resource and begin recording from it.
  /// Return error message.
  Future<String?> startRecording() async {
    bool micPerm = await _audioRecorder.hasPermission();
    if (!micPerm) {
      return "Microphone permissions required for chat. Please enable in your system settings.";
    } else {
      print("\tStarting to record...");
      await _audioRecorder.start(
        // TODO check platform for codec availablility
        // encoder: AudioEncoder.pcm16bit,  // NOTE supported on ios, android, and most web: https://pub.dev/packages/record#platform-feature-parity-matrix
        encoder: AudioEncoder.aacLc,  // MP4
        // encoder: AudioEncoder.opus,
        bitRate: bitRate,
        samplingRate: sampleRate,
        numChannels: numChannels,
      );
      print("\tRecording started.");
    }
  }

  /// Release the media resource
  /// Return error string
  Future<String?> stopRecording() async {
    String? audioPath = await _audioRecorder.stop();
    if (audioPath == null) {
      return "An error occurred while listening, please try again.";
    }
  }

  /// Release the media resource and send the recording to the API
  /// Return error string
  Future<String?> stopRecordingAndSubmitAudio(AuthService authService) async {
    print( "stopRecordingAndSubmitAudio");
    String url = "$host/m/next/$cid";
    String? audioBlobUrl = await _audioRecorder.stop();
    if (audioBlobUrl == null) {
      return "An error occurred while listening, please try again.";
    }
    // print('\n\tPLAYING AUDIO');
    // await player.play(audioBlobUrl);
    print("\taudioBlob: $audioBlobUrl");
    // NOTE cache manager loads the file from the blob:http:// audioPath
    File audioFile = await DefaultCacheManager().getSingleFile(audioBlobUrl);
    print("\taudioFile: $audioFile");
    var audioBytes = await audioFile.readAsBytes();
    // print(audioBytes.sublist(0, 32));
    // NOTE the following will let us see the header strings in the file
    // var byteString = Latin1Codec().decode(audioBytes);
    // print(byteString.substring(0, 256));
    var multipartFile = http.MultipartFile.fromBytes(
        'utterance',
        audioBytes,
        filename: 'utterance.m4a',
    );
    print("\tPreparing POST to Moshi endpoint $url");
    final user = authService.currentUser!;
    final token = await user.getIdToken();
    var request = http.MultipartRequest(
      'POST',
      Uri.parse(url),
    );
    request.headers['Authorization'] = "Bearer $token";
    request.files.add(multipartFile);
    print("\tAwaiting POST request: $request");
    // TODO try catch return error
    final response = await request.send();
    print("\tresponse.statusCode: ${response.statusCode}");
    print("\tresponse.headers:\n${response.headers}");
    // print("\tresponse.headers['user-utterance']:\n${response.headers['user-utterance']}");
    // print("\tresponse.headers['assistant-utterance']:\n${response.headers['user-utterance']}");
    final responseBytes = await response.stream.toBytes();
    // print("responseBytes");
    // print(responseBytes.sublist(0, 32));
    // final parsedResponse = json.decode(responseBody);
    // print("\tparsedResponse: $parsedResponse");
    if (response.statusCode != 200) {
      return "An error occurred sending speech to Moshi servers, please try again.";
    } else {
      return "Didn't barf";
    }
  }

  // Check API health, get mic. permissions, create conversation in Firestore
  Future<String?> startNewConversation(AuthService authService) async {
    print("startNewConversation");
    String? msg;
    final bool micPerm = await _audioRecorder.hasPermission();
    setState(() {
      haveMicPermissions = micPerm;
    });
    if (!micPerm) {
      return "Microphone permissions required for chat. Please enable in your system settings.";
    } else {
      print("\tmicrophone permissions allowed");
      await _audioRecorder.dispose();
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
                    "Server health: $isServerHealthy",
                    style: TextStyle(fontSize: 16.0),
                  ),
                  Text(
                    "Microphone permissions: $haveMicPermissions",
                    style: TextStyle(fontSize: 16.0),
                  ),
                  Text(
                    "Recording: $_recordState",
                    style: TextStyle(fontSize: 16.0),
                  ),
                  Text(
                    (convoState != ConvoState.started)
                      ? "Conversation: inactive"
                      : "Conversation: ${cid?.substring(0, 8)}",
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
                final String? erMsg = await startNewConversation(authService);
                if (erMsg != null) {
                  util.showError(context, erMsg);
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
              backgroundColor: Colors.purple[800],
            ),
          ),
          Positioned(
            bottom: 48.0,
            right: 128.0,
            // TODO Make all onTap functions do nothing when convoState != ConvoState.started;
            // TODO Container to make the gesture detector take on size;
            child: GestureDetector(
              // TODO error handling for recorder being in wrong state when button up/down
              onTapDown: (_) {
                print("\tonTapDown");
                startRecording().then((erMsg) {
                  if (erMsg != null) {
                    util.showError(context, erMsg);
                  }
                });
              },
              // TODO fix the size of the GestureDetector so onTapCancel isn't so prevalent and I can dedupe this code
              onTapUp: (_) {
                print("\tonTapUp");
                _audioRecorder.isRecording().then((isRecording) {
                  if (isRecording) {
                    stopRecordingAndSubmitAudio(authService).then((erMsg) {
                      if (erMsg != null) {
                        util.showError(context, erMsg);
                      }
                    });
                  }
                });
              },
              onTapCancel: () {
                print("\tonTapCancel");
                _audioRecorder.isRecording().then((isRecording) {
                  if (isRecording) {
                    stopRecordingAndSubmitAudio(authService).then((erMsg) {
                      if (erMsg != null) {
                        util.showError(context, erMsg);
                      }
                    });
                  }
                });
              },
              child: FloatingActionButton(
                onPressed: () {
                  print("\tonPressed");
                },
                child: Icon(Icons.mic),
                // NOTE onPressed null doesn't disable button: https://github.com/flutter/flutter/issues/107480
                backgroundColor: (convoState != ConvoState.started) ? Colors.grey : recordButtonColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
