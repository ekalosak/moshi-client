import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:moshi/types.dart';
import 'package:moshi/widgets/chat.dart';
import 'package:moshi/widgets/status.dart';

const int maxRecordingSeconds = 30;

class ChatScreen extends StatefulWidget {
  final Profile profile;
  final Map<String, dynamic> languages;
  // function from Str to void to update title of wrapper
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
  double _recordingSeconds = 0.0;
  late Record record; // NOTE there's no reason why these are public v private right now
  late AudioPlayer audioPlayer;
  final FirebaseStorage storage = FirebaseStorage.instance;
  List<Activity> _activities = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>?>? _activityListener;
  Activity? _activity;
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
    _activityListener = FirebaseFirestore.instance.collection('activities').snapshots().listen((querySnapshot) {
      print("chat: _activityListener: querySnapshot: ${querySnapshot.docs.length} docs");
      if (querySnapshot.docs.isEmpty) {
        print("WARNING chat: _activityListener: querySnapshot.docs.length == 0");
        return;
      }
      for (var doc in querySnapshot.docs) {
        try {
          Activity a = Activity.fromDocumentSnapshot(doc);
          print("chat: _activityListener: doc -> activity: ${a.name} ${a.title}");
          setState(() {
            _activities.add(a);
            _activity = a;
          });
        } catch (e) {
          print("WARNING chat: _activityListener: failed to parse activity: ${doc.data()}");
          continue;
        }
      }
    });
    record = Record();
    audioPlayer = AudioPlayer();
  }

  @override
  void dispose() async {
    super.dispose();
    await _transcriptListener?.cancel();
    await _activityListener?.cancel();
    await record.dispose();
    await audioPlayer.dispose();
    if (_isRecording) {
      _recordingTimer.cancel();
    }
  }

  // Where audio files will be stored on the device.
  Future<Directory> _audioCacheDir() async {
    Directory cacheDir = await getApplicationCacheDirectory();
    print("chat: _audioCacheDir: cacheDir: $cacheDir");
    return Directory('${cacheDir.path}/audio/');
  }

  /// This gets shown to users on page load.
  List<Message> _initMessages() {
    return [
      // Message(Role.ast,
      //     "Then, hold the walkie-talkie button to speak. Let go when you're done speaking. You should feel your phone vibrate when the recording starts."),
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
      print("chat: _transcriptListener: doc.data: ${doc.data()}");
      Transcript? t;
      try {
        t = Transcript.fromDocumentSnapshot(doc);
        print("chat: _transcriptListener: ${t.messages.length} messages}");
      } on NullDataError {
        print("chat: _transcriptListener: NullDataError");
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
        if (t.messages.isNotEmpty && t.messages.first.role == Role.ast) {
          if (!t.messages.first.played) {
            print("chat: _transcriptListener: playing AST audio");
            _playAudioFromMessage(t.messages.first);
          } else {
            print("chat: _transcriptListener: AST audio already played");
          }
        }
        setState(() {
          _transcript = t!;
          _isLoading = false;
        });
      } else {
        print("WARNING chat: _transcriptListener: t is null; failed to parse");
      }
    });
  }

  /// Get mic Permissions, check server health, and perform Chat connection establishment.
  /// Returns error string if any.
  Future<String?> startPressed() async {
    print("chat: startPressed: [START]");
    setState(() {
      callStatus = CallStatus.ringing;
      serverStatus = ServerStatus.pending;
      micStatus = MicStatus.off;
    });

    // Make sure we have a cached audio directory
    await _clearCachedAudio();
    await _ensureAudioCacheExists();

    // Check and request permission
    print("chat: startPressed: checking permission");
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
    if (isSupported) {
      print("chat: startPressed: ${encoder.name} supported");
    } else {
      throw ("chat: startPressed: ${encoder.name} not supported");
    }

    // Call cloud function start_activity
    final HttpsCallable startActivity = FirebaseFunctions.instance.httpsCallable('start_activity');
    HttpsCallableResult result;
    try {
      print("chat: startPressed: calling startActivity");
      print("chat: startPressed: _activity: $_activity");
      print("chat: startPressed: language: ${widget.profile.lang}");
      result = await startActivity.call(<String, dynamic>{
        'name': _activity?.name ?? 'unstructured',
        'type': _activity?.type ?? 'unstructured',
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
    print("chat: startPressed: startActivity result: message ${result.data['message']}");
    print("chat: startPressed: startActivity result: detail ${result.data['detail']}");

    // Listen to the transcript provisioned by the start_activity call
    await _initTranscriptListener(result.data['detail']['transcript_id']);

    // Show the user we're ready
    setState(() {
      serverStatus = ServerStatus.ready;
      callStatus = CallStatus.inCall;
      micStatus = MicStatus.muted;
    });
    print("chat: startPressed: [END]");
    return null;
  }

  /// Terminate the Chat session.
  Future<String?> stopPressed() async {
    print("stopPressed [START]");
    await record.stop();
    await audioPlayer.stop();
    setState(() {
      callStatus = CallStatus.idle;
      _isLoading = false;
      _isRecording = false;
    });
    await feedbackAfterCall();
    print("stopPressed [END]");
    return null;
  }

  Future<void> _ensureAudioCacheExists() async {
    final Directory audioCacheDir = await _audioCacheDir();
    print("chat: _ensureAudioCacheExists: audioCacheDir: $audioCacheDir");
    if (!await audioCacheDir.exists()) {
      print("chat: _ensureAudioCacheExists: creating audio cache dir");
      await audioCacheDir.create(recursive: true);
      print(
          "chat: _ensureAudioCacheExists: created audio cache dir: $audioCacheDir exists: ${await audioCacheDir.exists()}");
    } else {
      print("chat: _ensureAudioCacheExists: audio cache dir: $audioCacheDir already exists");
    }
  }

  Future<void> _clearCachedAudio() async {
    final Directory audioCacheDir = await _audioCacheDir();
    print("chat: _clearCachedAudio: audioCacheDir: $audioCacheDir");
    if (!await audioCacheDir.exists()) {
      print("chat: _clearCachedAudio: audio cache dir does not exist, returning");
      return;
    }
    print("chat: _clearCachedAudio: clearing audio cache dir");
    await audioCacheDir.delete(recursive: true);
    print("chat: _clearCachedAudio: cleared audio cache dir");
  }

  /// Download the audio from GCS, if it doesn't exist locally, and play it.
  Future<void> _playAudioFromMessage(Message msg) async {
    print("chat: _playAstAudio: [START]");
    File astAudio = await _downloadAudio(msg.audio);
    await audioPlayer.play(DeviceFileSource(astAudio.path));
    msg.played = true;
    setState(() {
      _isLoading = false;
    });
    print("chat: _playAstAudio: [START]");
  }

  // TODO debug this following
  /// Download the audio from GCS and return the file.
  Future<File> _downloadAudio(Audio? audio) async {
    if (audio == null) {
      throw ("chat: _downloadAudio: audio is null");
    }
    final Directory audioCacheDir = await _audioCacheDir();
    final String audioName = audio.path.split('/').last;
    final File audioFile = File('${audioCacheDir.path}${_transcript.id}/$audioName');
    if (await audioFile.exists()) {
      print("chat: _downloadAudio: audio file already exists: $audioFile");
      return audioFile;
    }
    print("chat: _downloadAudio: downloading $audioName to $audioFile");
    if (storage.bucket != audio.bucket) {
      throw ("chat: _downloadAudio: storage.bucket != audio.bucket: ${storage.bucket} != ${audio.bucket}");
    }
    final Reference audioRef = storage.ref().child(audio.path);
    print("chat: _downloadAudio: audioRef: $audioRef");
    await audioRef.writeToFile(audioFile);
    print("chat: _downloadAudio: downloaded $audioName to $audioFile");
    return audioFile;
  }

  /// Get the next available audio file path for the user.
  Future<File> _nextUsrAudio(String transcriptId) async {
    final Directory audioCacheDir = await _audioCacheDir();
    final Directory transcriptCacheDir = Directory('${audioCacheDir.path}/$transcriptId');
    if (!await transcriptCacheDir.exists()) {
      print("chat: _nextUsrAudio: creating transcript cache dir");
      await transcriptCacheDir.create(recursive: true);
    } else {
      print("chat: _nextUsrAudio: transcript cache dir exists");
    }
    final List<FileSystemEntity> files = transcriptCacheDir.listSync(recursive: false, followLinks: false);
    final int nextIndex = files.length;
    final String nextPath = '${transcriptCacheDir.path}/$nextIndex-USR.$extension';
    print("chat: _nextUsrAudio: nextPath: $nextPath");
    return File(nextPath);
  }

  /// Acquire audio permissions and record audio to file.
  Future<String?> chatPressed() async {
    print("chat: chatPressed: [START]");
    final File audioPath = await _nextUsrAudio(_transcript.id);
    print("chat: audioPath: ${audioPath.path}");
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

    print("chat: startMicrophoneRec [END]");
    setState(() {
      micStatus = MicStatus.on;
      _isRecording = true;
    });
    return null;
  }

  /// Stop the audio recording and flush to file.
  Future<void> chatReleased() async {
    print("chat: chatReleased: [START]");
    _recordingTimer.cancel();
    bool isRecording = await record.isRecording();
    if (!isRecording) {
      print("WARNING chat: chatReleased: Is not recording, returning...");
      return;
    }
    print("chat: chatReleased: stopping recording...");
    String? path = await record.stop();
    print("chat: chatReleased: stopped recording, path: $path");
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
    await _uploadAudio(_transcript.id, audioFile.path);
    print("chat: chatReleased: [END]");
  }

  Future<void> _uploadAudio(String transcriptId, String path) async {
    final File audioFile = File(path);
    final String audioName = audioFile.path.split('/').last;
    print("chat: _uploadAudio: audioName: $audioName");
    final Reference audioRef = storage.ref().child('audio/${widget.profile.uid}/$transcriptId/$audioName');
    print("chat: _uploadAudio: audioRef: $audioRef");
    print("chat: _uploadAudio: uploading $audioName to $audioRef");
    final UploadTask uploadTask = audioRef.putFile(audioFile);
    final TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
    print("chat: _uploadAudio: taskSnapshot: $taskSnapshot");
  }

  @override
  Widget build(BuildContext context) {
    final Widget topStatusBar = _topStatusBar(context);
    final Chat middleChatBox = Chat(messages: _transcript.messages);
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
              : _activitySelector(context),
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

  Widget _activitySelector(BuildContext context) {
    List<String> activityNames = _activities.map((a) => a.name).toSet().toList();
    print("chat: _activitySelector: activityNames: $activityNames");
    print("chat: _activitySelector: _activity: ${_activity?.title}");
    return DropdownButton<String>(
      value: _activity?.name,
      icon: const Icon(Icons.arrow_downward),
      iconSize: 24,
      elevation: 16,
      style: Theme.of(context).textTheme.headlineSmall,
      underline: Container(
        height: 2,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      onChanged: (String? newValue) {
        print("chat: _activitySelector: onChanged: newValue: $newValue");
        print("chat: _activitySelector: onChanged: _activities: ${_activities.map((a) => a.name).toList()}");
        print("chat: _activitySelector: onChanged: _activity: ${_activity?.title}");
        setState(() {
          _activity = _activities.firstWhere((a) => a.name == newValue);
        });
      },
      items: activityNames.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, style: Theme.of(context).textTheme.headlineSmall),
        );
      }).toList(),
    );
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
    print("feedbackPressed [START]");
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
    print("feedbackPressed [END]");
  }

  Future<void> _sendFeedback(String body) async {
    print("Sending feedback: $body");
    DocumentReference transcriptRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.profile.uid)
        .collection('transcripts')
        .doc(_transcript.id);
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
