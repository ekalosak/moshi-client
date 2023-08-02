import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:moshi_client/types.dart';

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
    print("Transcript.fromDocumentSnapshot: $snapshot");
    List<Message> msgs = [];
    for (var msg in snapshot['messages']) {
      print("Transcript.fromDocuSnap msg: $msg");
      Message message = Message.fromMap(msg);
      print("Transcript.fromDocuSnap message: $message");
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
  List<Transcript>? _transcripts;

  @override
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
        setState(() {
          (_transcripts == null) ? _transcripts = ts : _transcripts!.addAll(ts); // Does this add duplicate transcripts?
        });
      }
    });
  }

  Widget _buildTranscriptList() {
    print("_buildTranscriptList");
    print("_transcripts: $_transcripts");
    List<Transcript> transcripts = _transcripts!;
    itemBuilder(BuildContext context, int index) {
      print("itemBuilder.index: $index");
      return ListTile(
        // title: Text(transcripts[index].timestamp), // TODO summary of transcript
        title: Text(transcripts[index].timestamp.toDate().toString()),
        subtitle: Text(transcripts[index].tid),
        onTap: () {
          // TODO open transcript as a Chat
          // use a hero animation to transition from the transcript list to the chat
          print("TODO open transcript as a Chat");
        },
      );
    }

    return ListView.builder(itemBuilder: itemBuilder, itemCount: transcripts.length);
  }

  @override
  Widget build(BuildContext context) {
    print("TranscriptScreen.build");
    return (_transcripts == null) ? Center(child: CircularProgressIndicator()) : _buildTranscriptList();
  }
}
