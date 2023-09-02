import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:moshi/types.dart';
import 'package:moshi/widgets/chat.dart';

class TranscriptScreen extends StatefulWidget {
  final Profile profile;

  TranscriptScreen({required this.profile});

  @override
  State<StatefulWidget> createState() {
    return _TranscriptScreenState();
  }
}

class _TranscriptScreenState extends State<TranscriptScreen> {
  late StreamSubscription _transcriptListener;
  List<Transcript>? _transcripts; // transcripts for this user // TODO filter by date. show only the last 30 days?

  @override
  void initState() {
    super.initState();
    // listen for transcript documents with this user's uid in the uid field.
    // the transcript documents have their own unique document id.
    _transcriptListener = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.profile.uid)
        .collection('transcripts')
        .orderBy("timestamp", descending: true)
        .limitToLast(16)
        .snapshots()
        .listen((event) {
      if (event.size > 0) {
        final List<Transcript> ts = [];
        for (var doc in event.docs) {
          final Transcript t;
          try {
            t = Transcript.fromDocumentSnapshot(doc);
          } on NullDataError {
            continue;
          }
          ts.add(t);
        }
        if (ts.isNotEmpty) {
          if (mounted) {
            _addTranscripts(ts);
          }
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
    _transcriptListener.cancel();
    _transcripts?.clear();
    super.dispose();
  }

  void _addTranscripts(List<Transcript> ts) {
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
    print("_buildTranscriptList");
    List<Transcript> transcripts = _transcripts!;
    itemBuilder(BuildContext context, int index) {
      Transcript t = transcripts[index];
      // String emoji = util.getLangEmoji(t.language);
      String emoji = t.language;
      String date = t.createdAt.toDate().toString().substring(0, 16); // NOTE drops seconds and smaller
      String title = "$emoji $date";
      int nm = t.messages.where((element) => element.role != Role.sys).length;
      String subtitle = t.summary ?? '$nm messages';
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

  @override
  Widget build(BuildContext context) {
    print("TranscriptScreen.build");
    if (_transcripts == null) {
      return Center(child: CircularProgressIndicator());
    } else {
      return _buildTranscriptList();
    }
  }

  Scaffold _chatScaffold(Transcript transcript) {
    List<Message> msgs = [];
    for (var msg in transcript.messages) {
      if (msg.role != Role.sys) {
        msgs.add(msg);
      }
    }
    return Scaffold(
      appBar: AppBar(
          title: Text(
        transcript.createdAt.toDate().toString().substring(0, 16),
        style: Theme.of(context).textTheme.headlineMedium,
      )
          // style: TextStyle(
          //   color: Theme.of(context).colorScheme.secondary,
          //   fontFamily: Theme.of(context).textTheme.headlineMedium?.fontFamily,
          //   fontSize: Theme.of(context).textTheme.headlineMedium?.fontSize,
          // )),
          ),
      body: Chat(messages: msgs),
    );
  }
}
