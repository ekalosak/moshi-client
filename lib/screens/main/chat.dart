import 'package:flutter/material.dart';
import 'package:record/record.dart';

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

class _ChatScreenState extends State<ChatScreen> {
  bool isRecording = false;
  bool hasPermissions = false;
  // final record = AudioRecorder();  // NOTE v5
  final record = Record();
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.all(8.0),
            ),
            child: Text(
              hasPermissions ? 'Audio access established' : 'Get microphone',
              style: TextStyle(fontSize: 18.0),
            ),
            onPressed: hasPermissions ? null : getPermissions,
          ),
          GestureDetector(
            onTapDown: (_) {
              startRecording(context);
            },
            onTapUp: (_) {
              stopRecording(context);
            },
            onTapCancel: () {
              stopRecording(context);
            },
            child: Center(
              child: Container(
                width: 100.0,
                height: 50.0,
                color: isRecording ? Colors.yellow : Colors.white,
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
          ),
        ],
      ),
    );
  }
}
