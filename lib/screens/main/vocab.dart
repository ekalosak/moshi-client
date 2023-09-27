// This screen displays the user's vocabulary.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:moshi/widgets/vocab.dart';
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
  final Map<String, Vocab> _vocab = {};

  /// From the Transcripts, extract the vocab from each message and add it to the _vocab map.
  void _extractVocab() {
    for (Transcript t in _transcripts) {
      for (Message m in t.messages) {
        if (m.role == Role.usr) {
          if (m.vocab == null) {
            continue;
          }
          for (Vocab v in m.vocab!.values) {
            // print("vocab: $v");
            if (!_vocab.containsKey(v.term)) {
              _vocab[v.term] = v;
            }
          }
        }
      }
    }
  }

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
      _extractVocab();
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
    // print("BUILDING VOCAB SCREEN");
    // print("vocab: $_vocab");
    Vocabulary vocab = Vocabulary(_vocab);
    return Padding(
      padding: EdgeInsets.all(16),
      child: Flex(
        direction: Axis.vertical,
        children: [
          Flexible(
            child: vocab,
          ),
        ],
      ),
    );
  }
}
