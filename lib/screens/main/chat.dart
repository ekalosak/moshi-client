import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';

import 'package:moshi/types.dart';
import 'package:moshi/utils/audio.dart';
import 'package:moshi/widgets/chat.dart';
import 'package:moshi/widgets/status.dart';

const int maxRecordingSeconds = 30;
const int waitForResponseTimeout = 25;

class ChatScreen extends StatefulWidget {
  final Profile profile;
  final Map<String, dynamic> languages;
  final Function(String) setTitle;
  ChatScreen({required this.profile, required this.languages, required this.setTitle});
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  MicStatus micStatus = MicStatus.off;
  ServerStatus serverStatus = ServerStatus.unknown;
  CallStatus callStatus = CallStatus.idle;
  bool _isLoading = false; // true when waiting for ast response
  bool _isRecording = false; // true when user is speaking
  late Timer _recordingTimer;
  late Timer _timeoutTimer;
  double _recordingSeconds = 0.0;
  double _timeoutSeconds = 0.0;
  late Record record; // NOTE there's no reason why these are public v private right now
  late AudioPlayer audioPlayer;
  final FirebaseStorage storage = FirebaseStorage.instance;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>?>? _transcriptListener;
  late Transcript _transcript; // must be late to get profile.name and lang from widget
  /// For supported codecs, see: https://pub.dev/packages/record
  final AudioEncoder encoder = defaultTargetPlatform == TargetPlatform.iOS ? AudioEncoder.flac : AudioEncoder.wav;
  final String extension = defaultTargetPlatform == TargetPlatform.iOS ? "flac" : "wav";

  @override
  void initState() {
    super.initState();
    _transcript = Transcript(
        id: 'dne',
        messages: _initMessages(),
        language: widget.profile.lang,
        createdAt: Timestamp.now(),
        activityId: 'dne');
    record = Record();
    audioPlayer = AudioPlayer();
  }

  @override
  void dispose() async {
    super.dispose();
    await stopPressed();
    await _transcriptListener?.cancel();
    await record.dispose();
    await audioPlayer.dispose();
    if (_isRecording) {
      _recordingTimer.cancel();
    }
    try {
      _timeoutTimer.cancel();
    } catch (e) {
      print("_timeoutTimer not initialized, indicating the user switched screens before starting a call.");
    }
  }

  /// This gets shown to users on page load.
  List<Message> _initMessages() {
    return [
      Message(Role.ast, "Press that button to get started."),
      Message(Role.ast, "Would you like to practice ${widget.languages[widget.profile.lang]['language']['name']}?"),
      Message(Role.ast, "Hello, ${widget.profile.name}."),
    ];
  }

  /// Start listening to the transcript document.
  Future<void> _initTranscriptListener(String tid) async {
    await _transcriptListener?.cancel();
    _transcriptListener = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.profile.uid)
        .collection('transcripts')
        .doc(tid)
        .snapshots()
        .listen((doc) {
      Transcript? t;
      try {
        t = Transcript.fromDocumentSnapshot(doc);
      } on NullDataError {
        // nothing
        print("NULLDATATERROR");
      }
      if (t != null) {
        // check if the transcript has any new messages
        // if so, play the audio
        if (_transcript.id == 'dne') {
          print("chat: _transcriptListener: _transcript is startup instructions, setting it to received value.");
        } else if (t.messages.length > _transcript.messages.length) {
          print("chat: _transcriptListener: new messages, playing audio if it's AST");
        } else {
          print("chat: _transcriptListener: no new messages");
        }
        print("chat: _transcriptListener: messages: ${t.messages}");
        if (t.messages.isNotEmpty) {
          print("latest message: ${t.messages.first.role} ${t.messages.first.msg}");
        }
        if (t.messages.isNotEmpty && t.messages.last.role == Role.ast) {
          print("chat: _transcriptListener: playing audio from message ${t.messages.last.msg}");
          if (mounted) {
            if (callStatus == CallStatus.inCall) {
              playAudioFromMessage(t.messages.last, t.id, audioPlayer, storage);
            }
            _timeoutTimer.cancel();
            setState(() {
              _isLoading = false;
              _timeoutSeconds = 0.0;
            });
          }
        }
        if (mounted) {
          setState(() {
            _transcript = t!;
          });
        }
      } else {
        print("WARNING chat: _transcriptListener: t is null; failed to parse");
      }
    });
  }

  /// TODO DUMMY TEST FUNCTION
  Future<void> _testAppCheck() async {
    try {
      print("START test_app_check");
      await FirebaseFunctions.instance.httpsCallable('test_app_check').call();
      print("SUCCEEDED test_app_check");
    } catch (e) {
      print("FAILED test_app_check");
    }
  }

  /// Get mic Permissions, check server health, and perform Chat connection establishment.
  /// Returns error string if any.
  Future<String?> startPressed() async {
    await _testAppCheck();
    setState(() {
      callStatus = CallStatus.ringing;
      serverStatus = ServerStatus.pending;
      micStatus = MicStatus.off;
    });

    // Make sure we have a cached audio directory
    await ensureAudioCacheExists();
    // If it's 5MB or less, then don't bother deleting it. Otherwise, trim to 5MB.
    await trimAudioCache(maxAudioCacheSize: 5 * 1024 * 1024);

    // Check and request permission
    if (!(await record.hasPermission())) {
      setState(() {
        micStatus = MicStatus.noPermission;
        callStatus = CallStatus.idle;
        serverStatus = ServerStatus.ready;
      });
      return "Please grant microphone permission";
    }

    // Negotiate codec
    final isSupported = await record.isEncoderSupported(encoder);
    if (!isSupported) {
      throw ("chat: startPressed: ${encoder.name} not supported");
    }

    // Call cloud function start_activity
    final HttpsCallable startActivity = FirebaseFunctions.instance.httpsCallable('start_activity');
    HttpsCallableResult result;
    try {
      result = await startActivity.call(<String, dynamic>{
        'name': 'unstructured',
        'type': 'unstructured',
        'language': widget.profile.lang,
        'level': widget.profile.level,
      });
    } catch (e) {
      setState(() {
        serverStatus = ServerStatus.error;
        callStatus = CallStatus.error;
        micStatus = MicStatus.off;
      });
      if (e is FirebaseFunctionsException) {
        return "😭 Server error: ${e.message}";
      }
      return "❌ Server error: ${e.toString()}";
    }

    // Listen to the transcript provisioned by the start_activity call
    await _initTranscriptListener(result.data['detail']['transcript_id']);

    // Show the user we're ready
    setState(() {
      serverStatus = ServerStatus.ready;
      callStatus = CallStatus.inCall;
      micStatus = MicStatus.muted;
    });
    return null;
  }

  /// Terminate the Chat session.
  Future<String?> stopPressed() async {
    await record.stop();
    await audioPlayer.stop();
    if (mounted) {
      setState(() {
        callStatus = CallStatus.idle;
        _isLoading = false;
        _isRecording = false;
        _recordingSeconds = 0.0;
        _timeoutSeconds = 0.0;
      });
    }
    try {
      _recordingTimer.cancel();
    } catch (e) {
      print("WARNING chat: stopPressed: _recordingTimer not initialized");
      print(e);
    }
    try {
      _timeoutTimer.cancel();
    } catch (e) {
      print("WARNING chat: stopPressed: _timeoutTimer not initialized");
      print(e);
    }
    if (mounted) {
      await feedbackAfterCall();
    } else {
      await _sendFeedback("none");
    }
    return null;
  }

  /// Acquire audio permissions and record audio to file.
  Future<String?> chatPressed() async {
    await audioPlayer.stop();
    final File audioPath = await nextUsrAudio(_transcript.id, extension);
    await record.start(
      path: audioPath.path,
      encoder: encoder,
      samplingRate: 16000,
      numChannels: 1,
    );

    // If failed to start, return error and update UI icon.
    bool isRecording = await record.isRecording();
    if (!isRecording) {
      setState(() {
        micStatus = MicStatus.noPermission;
      });
      return "Error starting microphone, please grant microphone permissions in system settings.";
    }

    // Start the recording timer
    _recordingTimer = Timer.periodic(Duration(milliseconds: 100), (Timer t) {
      setState(() {
        _recordingSeconds = _recordingSeconds + 0.1;
      });
      if (_recordingSeconds >= maxRecordingSeconds) {
        chatReleased();
      }
    });

    setState(() {
      micStatus = MicStatus.on;
      _isRecording = true;
    });
    return null;
  }

  /// Stop the audio recording and flush to file.
  Future<void> chatReleased() async {
    _recordingTimer.cancel();
    bool isRecording = await record.isRecording();
    if (!isRecording) {
      print("WARNING chat: chatReleased: Is not recording, returning...");
      return;
    }
    String? path = await record.stop();

    // Timeout if we wait too long for AST audio
    _timeoutTimer = Timer.periodic(Duration(milliseconds: 100), (Timer t) {
      if (mounted) {
        setState(() {
          _timeoutSeconds = _timeoutSeconds + 0.1;
        });
      }
      if (_timeoutSeconds >= waitForResponseTimeout) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⌛️ Waiting for response timed out.")),
        );
        setState(() {
          _isLoading = false;
          _timeoutSeconds = 0.0;
        });
        stopPressed();
      }
    });

    setState(() {
      if (micStatus == MicStatus.on) {
        micStatus = MicStatus.muted;
        _isLoading = true;
        _isRecording = false;
        _recordingSeconds = 0.0;
      }
    });
    File audioFile = File(path!);
    if (!await audioFile.exists()) {
      throw ("chat: chatReleased: audio file does not exist: $path");
    }
    await uploadAudio(_transcript.id, audioFile.path, widget.profile.uid, storage);
  }

  Future<void> _playAudio(Audio aud) async {
    File? lap = await localAudioPath(aud);
    if (lap == null) {
      print("WARNING chat: _playAudio: localAudioPath returned null");
      return;
    }
    print("chat: _playAudio: playing ${lap.path}");
    await audioPlayer.play(DeviceFileSource(lap.path));
    print("played");
  }

  @override
  Widget build(BuildContext context) {
    final Widget topStatusBar = _topStatusBar(context);
    final Chat middleChatBox = Chat(messages: _transcript.messages, onLongPress: _playAudio);
    final Widget bottomButtons = _bottomButtons(context);
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
    return Row(children: [
      Flexible(
          flex: 3,
          child: Align(
              alignment: Alignment.center,
              child: FractionallySizedBox(
                widthFactor: 0.8,
                heightFactor: 0.65,
                child: _callButton(context),
              ))),
      Flexible(
        flex: 4,
        child: Align(
          alignment: Alignment.center,
          child: (callStatus == CallStatus.inCall)
              ? FractionallySizedBox(
                  widthFactor: 0.8,
                  heightFactor: 0.65,
                  child: _holdToChatButton(context),
                )
              : SizedBox(),
        ),
      ),
    ]);
  }

  Widget _progressBar(BuildContext context) {
    double loadingHeight = 8;
    double spacingHeight = 4;
    Widget loadingBar;
    if (_isRecording) {
      double progressValue = _recordingSeconds / maxRecordingSeconds;
      loadingBar = LinearProgressIndicator(
        value: progressValue,
        minHeight: loadingHeight,
        color: Theme.of(context).colorScheme.tertiary,
      );
    } else if (callStatus == CallStatus.ringing || serverStatus == ServerStatus.pending) {
      loadingBar = LinearProgressIndicator(minHeight: loadingHeight);
    } else if (_isLoading) {
      loadingBar = LinearProgressIndicator(minHeight: loadingHeight);
    } else {
      loadingBar = SizedBox(height: loadingHeight);
    }
    return Column(
      children: [
        loadingBar,
        SizedBox(height: spacingHeight),
      ],
    );
  }

  Widget _topStatusBar(BuildContext context) {
    return Column(children: [
      _progressBar(context),
      Row(children: [
        Expanded(flex: 7, child: SizedBox()),
        Expanded(
          flex: 2,
          child: ConnectionStatus(
            micStatus: micStatus,
            serverStatus: serverStatus,
            callStatus: callStatus,
            colorScheme: Theme.of(context).colorScheme,
          ),
        ),
      ])
    ]);
  }

  Widget _callButton(BuildContext context) {
    String buttonText = (callStatus == CallStatus.inCall) ? "End" : "Start";
    return FloatingActionButton.extended(
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
        CallStatus.inCall: Theme.of(context).colorScheme.secondary,
        CallStatus.error: Theme.of(context).colorScheme.tertiary,
      }[callStatus],
      icon: Icon(
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
      label: Text(buttonText,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.background,
              )),
    );
  }

  Widget _holdToChatButton(BuildContext context) {
    return _isLoading
        ? SizedBox()
        : GestureDetector(
            onLongPressStart: (_) {
              HapticFeedback.lightImpact();
              chatPressed();
            },
            onLongPressEnd: (_) {
              HapticFeedback.lightImpact();
              // print("Long press end");
              chatReleased();
            },
            child: FloatingActionButton.extended(
              onPressed: () async {},
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              label: Text("Hold to\nspeak",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
    // print("feedbackPressed [START]");
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Feedback", style: Theme.of(context).textTheme.headlineSmall),
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
    // print("feedbackPressed [END]");
  }

  Future<void> _sendFeedback(String body) async {
    // print("Sending feedback: $body");
    DocumentReference transcriptRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.profile.uid)
        .collection('transcripts')
        .doc(_transcript.id);
    try {
      await transcriptRef.update({
        'feedback': body,
      });
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        if (_transcript.id == 'dne') {
          // print("WARNING chat: _sendFeedback: transcript not found");
        } else {
          print("WARNING chat: _sendFeedback: failed to update transcript: ${e.message}");
        }
      } else {
        print("WARNING chat: _sendFeedback: failed to update transcript: ${e.message}");
      }
    }
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
