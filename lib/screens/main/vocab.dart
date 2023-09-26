// This screen displays the user's vocabulary.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:moshi/types.dart';

class VocabScreen extends StatefulWidget {
  final Profile profile;
  VocabScreen({required this.profile});
  @override
  State<VocabScreen> createState() => _VocabScreenState();
}

class _VocabScreenState extends State<VocabScreen> {
  late StreamSubscription _transcriptListener;
  final List<Transcript> _transcripts = [];

  @override
  void initState() {
    super.initState();
    _transcriptListener = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.profile.uid)
        .collection('transcripts')
        .orderBy('created_at', descending: false)
        .limitToLast(16)
        .snapshots()
        .listen((event) {
      if (event.size > 0) {
        for (var doc in event.docs) {
          final Transcript t;
          try {
            t = Transcript.fromDocumentSnapshot(doc);
          } on NullDataError {
            continue;
          }
          _transcripts.add(t);
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _transcriptListener.cancel();
    _transcripts.clear();
  }

  @override
  Widget build(BuildContext context) {
    Widget body = Text("TODO");
    return Padding(
      padding: EdgeInsets.all(16),
      child: body,
    );
  }
}
