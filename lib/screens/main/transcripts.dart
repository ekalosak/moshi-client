import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:moshi/types.dart';
import 'package:moshi/util.dart' as util;
import 'package:moshi/widgets/chat.dart';

class NullDataError implements Exception {
  final String message;
  NullDataError(this.message);
}

class Transcript {
  String tid;
  String uid;
  List<Message> messages;
  String language;
  Timestamp timestamp;
  String activityType;
  String? summary;

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
    Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) {
      throw NullDataError("Transcript.fromDocumentSnapshot: snapshot.data() is null");
    }
    String language = (data.containsKey('language')) ? snapshot['language'] : '';
    return Transcript(
        tid: snapshot.id,
        uid: snapshot['uid'],
        messages: msgs,
        language: language,
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
      // Title is flag emoji + date + time to the minute
      Transcript t = transcripts[index];
      String emoji = util.getLangEmoji(t.language);
      // Format the date to drop seconds and smaller
      String date = t.timestamp.toDate().toString().substring(0, 16);
      String title = "$emoji $date";
      int nm = t.messages.where((element) => element.role != Role.sys).length;
      String subtitle = t.summary ?? '$nm messages';
      return ListTile(
        // TODO summary of transcript instead of timestamp for title, put date in subtitle (only up to minute, no seconds)
        title: Text(title),
        subtitle: Text(subtitle),
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
