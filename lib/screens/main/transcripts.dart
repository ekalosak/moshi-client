import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:moshi_client/types.dart';
import 'package:moshi_client/widgets/chat.dart';

class Transcript {
  String tid;
  String uid;
  List<Message> messages;
  String language;
  Timestamp timestamp;
  String activityType;

  Transcript(
      {required this.tid,
      required this.uid,
      required this.messages,
      required this.language,
      required this.timestamp,
      required this.activityType});

  factory Transcript.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    List<Message> msgs = [];
    for (var msg in snapshot['messages'].reversed) {
      Message message = Message.fromMap(msg);
      msgs.add(message);
    }
    return Transcript(
        tid: snapshot.id,
        uid: snapshot['uid'],
        messages: msgs,
        // language: snapshot['language'],  // this may be missing
        language: 'en', // TODO remove this when language is in the transcript document
        timestamp: snapshot['timestamp'],
        activityType: snapshot['activity_type']);
  }

  bool hasNonSysMessages() {
    for (var msg in messages) {
      if (msg.role != Role.sys) {
        return true;
      }
    }
    return false;
  }
}

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
        .collection('transcripts')
        .where('uid', isEqualTo: widget.profile.uid)
        .snapshots()
        .listen((event) {
      final List<Transcript> ts = [];
      for (var doc in event.docs) {
        ts.add(Transcript.fromDocumentSnapshot(doc));
      }
      if (ts.isNotEmpty) {
        if (mounted) {
          _addTranscripts(ts);
        }
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
    setState(() {
      _transcripts ??= [];
      for (var t in ts) {
        if (!_transcripts!.contains(t) && t.hasNonSysMessages()) {
          _transcripts!.add(t);
        }
      }
      _transcripts!.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  Widget _buildTranscriptList() {
    print("_buildTranscriptList");
    List<Transcript> transcripts = _transcripts!;
    itemBuilder(BuildContext context, int index) {
      return ListTile(
        // TODO summary of transcript instead of timestamp for title, put date in subtitle (only up to minute, no seconds)
        title: Text(transcripts[index].timestamp.toDate().toString()),
        subtitle: Text(transcripts[index].tid),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _chatScaffold(transcripts[index].messages),
            ),
          );
        },
      );
    }

    return ListView.builder(itemBuilder: itemBuilder, itemCount: transcripts.length);
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

  Scaffold _chatScaffold(List<Message> messages) {
    List<Message> msgs = [];
    for (var msg in messages) {
      if (msg.role != Role.sys) {
        msgs.add(msg);
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("Transcript"),
      ),
      body: Chat(messages: msgs),
    );
  }
}
