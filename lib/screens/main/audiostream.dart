import 'package:flutter/material.dart';
import 'package:audio_streamer/audio_streamer.dart';
import 'dart:math';

import 'package:flutter/services.dart';

class ASScreen extends StatefulWidget {
  @override
  _ASScreenState createState() => _ASScreenState();
}

class _ASScreenState extends State<ASScreen> {
  // Note that AudioStreamer works as a singleton.
  AudioStreamer streamer = AudioStreamer();
  bool _isRecording = false;
  List<double> _audio = [];

  void onAudio(List<double> buffer) async {
    _audio.addAll(buffer);
    var sampleRate = await streamer.actualSampleRate;
    double secondsRecorded = _audio.length.toDouble() / sampleRate;
    print('Max amp: ${buffer.reduce(max)}');
    print('Min amp: ${buffer.reduce(min)}');
    print('$secondsRecorded seconds recorded.');
    print('-' * 50);
  }

  void handleError(PlatformException error) {
    print(error);
  }

  void start() async {
    print("starting");
    try {
      // start streaming using default sample rate of 44100 Hz
      streamer.start(onAudio, handleError);

      setState(() {
        _isRecording = true;
      });
    } catch (error) {
      print(error);
    }
    print("started");
  }

  void stop() async {
    print("stopping");
    bool stopped = await streamer.stop();
    setState(() {
      _isRecording = stopped;
    });
    print("stopped");
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void buttonClicked() {
    print('clicked');
  }

  @override
  Widget build(BuildContext context) {
    print("screens/main/audiostream build");
    return Container(
      child: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: (_isRecording)
              ? null
              : start,
              child: const Text('start'),
            ),
            ElevatedButton(
              onPressed: (_isRecording)
              ? stop
              : null,
              child: const Text('stop'),
            ),
          ],
        ),
      ),
    );
  }
}
