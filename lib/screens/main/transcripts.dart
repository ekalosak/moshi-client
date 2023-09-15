import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:moshi/types.dart';
import 'package:moshi/utils/audio.dart';
import 'package:moshi/widgets/chat.dart';

class TranscriptScreen extends StatefulWidget {
  final Profile profile;
  final Map<String, dynamic> languages;

  TranscriptScreen({required this.profile, required this.languages});

  @override
  State<StatefulWidget> createState() {
    return _TranscriptScreenState();
  }
}

class _TranscriptScreenState extends State<TranscriptScreen> {
  late StreamSubscription _transcriptListener;
  List<Transcript>? _transcripts; // transcripts for this user // TODO filter by date. show only the last 30 days?
  late AudioPlayer audioPlayer;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    // listen for transcript documents with this user's uid in the uid field.
    // the transcript documents have their own unique document id.
    _transcriptListener = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.profile.uid)
        .collection('transcripts')
        .orderBy('created_at', descending: false)
        .limitToLast(16)
        .snapshots()
        .listen((event) {
      if (event.size > 0) {
        // print("TranscriptScreen._transcriptListener: event.size: ${event.size}");
        final List<Transcript> ts = [];
        for (var doc in event.docs) {
          // print("TranscriptScreen._transcriptListener: doc.id: ${doc.id}");
          final Transcript t;
          try {
            t = Transcript.fromDocumentSnapshot(doc);
          } on NullDataError {
            // print("TranscriptScreen._transcriptListener: NullDataError: ${doc.id}");
            // print(doc.data());
            continue;
          }
          ts.add(t);
        }
        if (ts.isNotEmpty) {
          _addTranscripts(ts);
        }
      } else {
        setState(() {
          _transcripts = [];
        });
      }
    });
  }

  @override
  void dispose() {
    // print("TranscriptScreen.dispose");
    _transcriptListener.cancel();
    _transcripts?.clear();
    audioPlayer.dispose();
    super.dispose();
  }

  void _addTranscripts(List<Transcript> ts) {
    // print("_addTranscripts");
    List<Transcript> transcripts = _transcripts ?? [];
    for (var t in ts) {
      // add transcript only if the tid doesn't match any existing transcript and if it has non-sys messages
      if (!transcripts.any((element) => element.id == t.id) && t.hasNonSysMessages()) {
        transcripts.add(t);
      }
    }
    transcripts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    setState(() {
      _transcripts = transcripts;
    });
  }

  /// Build the list of transcripts to display.
  Widget _buildTranscriptList() {
    // print("_buildTranscriptList");
    List<Transcript> transcripts = _transcripts!;
    itemBuilder(BuildContext context, int index) {
      Transcript t = transcripts[index];
      String title =
          "${widget.languages[t.language]['country']['flag']} ${widget.languages[t.language]['language']['name']}";
      String date = t.createdAt.toDate().toString().substring(0, 16); // NOTE drops seconds and smaller
      int nm = t.messages.where((element) => element.role != Role.sys).length;
      String subtitle = "${t.summary ?? '$nm messages'}\n$date";
      return ListTile(
        title: Text(title,
            style: TextStyle(
              fontFamily: Theme.of(context).textTheme.headlineMedium?.fontFamily,
              fontSize: Theme.of(context).textTheme.headlineMedium?.fontSize,
            )),
        subtitle: Text(subtitle),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _chatScaffold(transcripts[index]),
            ),
          );
        },
      );
    }

    return (_transcripts != null && _transcripts!.isNotEmpty)
        ? ListView.builder(itemBuilder: itemBuilder, itemCount: transcripts.length)
        : Text("No transcripts yet. Click 'Chat' in the menu to get started.");
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
    // print("TranscriptScreen.build");
    if (_transcripts == null) {
      return Center(child: CircularProgressIndicator());
    } else {
      return _buildTranscriptList();
    }
  }

  Scaffold _chatScaffold(Transcript transcript) {
    // print(transcript.id);
    // print("_chatScaffold: transcript.id: ${transcript.id}");
    List<Message> msgs = [];
    for (var msg in transcript.messages) {
      if (msg.role != Role.sys) {
        msgs.add(msg);
      }
    }
    // print("_chatScaffold: summary: ${transcript.summary}");
    String title = transcript.summary ?? transcript.createdAt.toDate().toString().substring(0, 16);
    return Scaffold(
      appBar: AppBar(
          title: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall,
      )),
      body: Chat(messages: msgs, onLongPress: _playAudio),
    );
  }
}
