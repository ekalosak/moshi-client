import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';

import 'package:moshi/types.dart';
import 'package:moshi/widgets/chat.dart';
import 'package:moshi/widgets/status.dart';

class ChatScreen extends StatefulWidget {
  final Profile profile;
  final Map<String, dynamic> languages;
  ChatScreen({required this.profile, required this.languages});
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  MicStatus micStatus = MicStatus.off;
  ServerStatus serverStatus = ServerStatus.unknown;
  CallStatus callStatus = CallStatus.idle;
  String _activityType = "unstructured";
  final record = Record();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>?>? _transcriptListener;
  Transcript? _transcript; // rendered state

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _transcriptListener?.cancel();
  }

  /// This gets shown to users on page load.
  List<Message> _initMessages() {
    return [
      Message(Role.ast, "Press the call button (📞) to get started."),
      Message(Role.ast, "Would you like to practice ${widget.languages[widget.profile.lang]['language']['name']}?"),
      Message(Role.ast, "Hello, ${widget.profile.name}."),
    ];
  }

  /// Start listening to the transcript document.
  void _initTranscriptListener(String tid) {
    _transcriptListener = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.profile.uid)
        .collection('transcripts')
        .doc(tid)
        .snapshots()
        .listen((doc) {
      Transcript? t;
      print("chat: _initTranscriptListener: ${doc.data()}");
      try {
        t = Transcript.fromDocumentSnapshot(doc);
        print("chat: _initTranscriptListener: ${t.messages.length} messages}");
      } on NullDataError {
        print("chat: _initTranscriptListener: NullDataError");
      }
      if (t != null) {
        if (mounted) {
          setState(() {
            _transcript = t;
          });
        }
      }
    });
  }

  /// Get mic permissions, check server health, and perform Chat connection establishment.
  /// Returns error string if any.
  Future<String?> startPressed() async {
    print("chat: startPressed: [START]");
    setState(() {
      _transcript = null;
      callStatus = CallStatus.ringing;
      serverStatus = ServerStatus.pending;
    });

    // Check and request permission
    print("chat: startPressed: checking permission");
    if (!(await record.hasPermission())) {
      setState(() {
        micStatus = MicStatus.noPermission;
      });
      return "Please grant microphone permission";
    }

    // Call cloud function start_activity
    final HttpsCallable startActivity = FirebaseFunctions.instance.httpsCallable('start_activity');
    HttpsCallableResult result;
    try {
      result = await startActivity.call(<String, dynamic>{
        'type': _activityType,
      });
    } catch (e) {
      setState(() {
        serverStatus = ServerStatus.error;
        callStatus = CallStatus.error;
      });
      if (e is FirebaseFunctionsException) {
        return "😭 Server error: ${e.message}";
      }
      return "❌ Server error: ${e.toString()}";
    }

    print("chat: startPressed: startActivity result: message ${result.data['message']}");
    print("chat: startPressed: startActivity result: detail ${result.data['detail']}");
    _initTranscriptListener(result.data['detail']['transcript_id']);
    setState(() {
      serverStatus = ServerStatus.ready;
      callStatus = CallStatus.inCall;
    });
    print("chat: startPressed: [END]");
    return null;
  }

  /// Terminate the Chat session.
  Future<String?> stopPressed() async {
    print("stopPressed [START]");
    await record.dispose();
    await feedbackAfterCall();
    print("stopPressed [END]");
    return null;
  }

  /// Acquire audio permissions and add audio stream to state `_localRec`.
  Future<String?> chatPressed() async {
    print("chat: startMicrophoneRec [START]");
    await record.start(
      // path: 'aFullPath/myFile.m4a',  // datetime
      path:
          'com.chatmoshi.moshi/audio/permission..m4a', // both ios and android can record to MPEG-4 https://pub.dev/packages/record
      encoder: AudioEncoder.aacLc, // by default
      bitRate: 128000, // by default
      samplingRate: 44100, // by default
    );

    bool isRecording = await record.isRecording();
    if (!isRecording) {
      setState(() {
        micStatus = MicStatus.noPermission;
      });
      return "Error starting microphone, please grant microphone permissions in system settings.";
    }

    setState(() {
      if (isRecording) {
        micStatus = MicStatus.on;
      }
    });

    print("chat: startMicrophoneRec [END]");
    return null;
  }

  /// Stop the audio recording and flush to file.
  Future<void> chatReleased() async {
    print("stopMicrophoneStream [START]");

    bool isRecording = await record.isRecording();
    if (isRecording) {
      print("Is recording, stopping...");
      String? path = await record.stop();
      setState(() {
        if (micStatus == MicStatus.on) {
          micStatus = MicStatus.muted;
        }
      });
      print("TODO upload to storage: $path");
    }
    print("stopMicrophoneStream [END]");
  }

  @override
  Widget build(BuildContext context) {
    Transcript? transcript;
    if (_transcript == null) {
      transcript = Transcript(
        id: "dne",
        createdAt: Timestamp.now(),
        messages: _initMessages(),
        language: widget.profile.lang,
        activityId: "dne",
      );
    } else {
      transcript = _transcript;
    }
    final Row topStatusBar = _topStatusBar(context);
    final Chat middleChatBox = Chat(messages: transcript!.messages);
    final Row bottomButtons = _bottomButtons(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 64,
          child: topStatusBar,
        ),
        Expanded(
          child: middleChatBox,
        ),
        SizedBox(height: 128, child: bottomButtons),
        SizedBox(height: 16),
      ],
    );
  }

  /// The bottom row of buttons.
  Row _bottomButtons(BuildContext context) {
    final GestureDetector holdToChatButton = _holdToChatButton(context);
    return Row(children: [
      Flexible(
          flex: 2,
          child: Align(
              alignment: Alignment.center,
              child: FractionallySizedBox(
                widthFactor: 0.65,
                heightFactor: 0.65,
                child: FloatingActionButton(
                  // New call
                  autofocus: true,
                  onPressed: () async {
                    final String? err;
                    switch (callStatus) {
                      case CallStatus.inCall:
                        err = await stopPressed();
                        break;
                      case CallStatus.idle:
                        err = await startPressed();
                        break;
                      case CallStatus.error:
                        err = await startPressed();
                        break;
                      case CallStatus.ringing:
                        err = null;
                        break;
                    }
                    if (err != null) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(err)),
                        );
                      }
                    }
                  },
                  backgroundColor: {
                    CallStatus.idle: Theme.of(context).colorScheme.tertiary,
                    CallStatus.ringing: Theme.of(context).colorScheme.onSurface,
                    CallStatus.inCall: Theme.of(context).colorScheme.primary,
                    CallStatus.error: Theme.of(context).colorScheme.tertiary,
                  }[callStatus],
                  child: Icon(
                      {
                        CallStatus.idle: Icons.call,
                        CallStatus.ringing: Icons.call_made,
                        CallStatus.inCall: Icons.call_end,
                        CallStatus.error: Icons.wifi_calling_3,
                      }[callStatus],
                      size: Theme.of(context).textTheme.headlineLarge?.fontSize,
                      color: {
                        CallStatus.idle: Theme.of(context).colorScheme.onTertiary,
                        CallStatus.ringing: Theme.of(context).colorScheme.surface,
                        CallStatus.inCall: Theme.of(context).colorScheme.onTertiary,
                        CallStatus.error: Theme.of(context).colorScheme.onTertiary,
                      }[callStatus]),
                ),
              ))),
      Flexible(
        flex: 3,
        child: Align(
          alignment: Alignment.center,
          child: (callStatus == CallStatus.inCall)
              ? FractionallySizedBox(
                  widthFactor: 0.8,
                  heightFactor: 0.65,
                  child: holdToChatButton,
                )
              : SizedBox(),
        ),
      ),
    ]);
  }

  Row _topStatusBar(BuildContext context) {
    return Row(children: [
      Expanded(
        flex: 2,
        // while call is ringing, show a spinner aligned topleft, otherwise nothing
        child: (callStatus == CallStatus.ringing || serverStatus == ServerStatus.pending)
            ? Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : SizedBox(),
      ),
      Expanded(
        flex: 3,
        child: ConnectionStatus(
          micStatus: micStatus,
          serverStatus: serverStatus,
          callStatus: callStatus,
          colorScheme: Theme.of(context).colorScheme,
        ),
      ),
    ]);
  }

  GestureDetector _holdToChatButton(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) {
        chatPressed();
        HapticFeedback.lightImpact();
      },
      onLongPressEnd: (_) {
        chatReleased();
        HapticFeedback.lightImpact();
      },
      child: FloatingActionButton.extended(
        onPressed: () async {},
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        label: Text("Hold to\nspeak",
            style: TextStyle(
              fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
              fontFamily: Theme.of(context).textTheme.headlineSmall?.fontFamily,
              color: Theme.of(context).colorScheme.onSurface,
            )),
        icon: Icon(
          Icons.mic,
          size: Theme.of(context).textTheme.headlineLarge?.fontSize,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  /// Pop up a dialog to ask for feedback.
  Future<void> feedbackAfterCall() async {
    print("feedbackPressed [START]");
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Feedback",
            style: TextStyle(
              fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
              fontFamily: Theme.of(context).textTheme.headlineSmall?.fontFamily,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          content: Text(
            "How was your call?",
          ),
          actions: [
            TextButton(
              child: Text(
                "👍",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              onPressed: () async {
                await _sendFeedback("good");
                _afterFeedbackMessage();
              },
            ),
            TextButton(
              child: Text(
                "👎",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              onPressed: () async {
                await _sendFeedback("bad");
                _afterFeedbackMessage();
              },
            ),
          ],
        );
      },
    );
    print("feedbackPressed [END]");
  }

  Future<void> _sendFeedback(String body) async {
    print("Sending feedback: $body");
    DocumentReference transcriptRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.profile.uid)
        .collection('transcripts')
        .doc(_transcript!.id);
    await transcriptRef.update({
      'feedback': body,
    });
  }

  void _afterFeedbackMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("🙇 Thank you very much for helping us improve."),
        duration: Duration(seconds: 2),
      ),
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
