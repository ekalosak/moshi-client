import 'package:flutter/material.dart';
import 'package:moshi_client/types.dart';

// stateful widget TranscriptScreen

class TranscriptScreen extends StatefulWidget {
  Profile profile;

  TranscriptScreen({required this.profile});

  @override
  State<StatefulWidget> createState() {
    return _TranscriptScreenState();
  }
}

class _TranscriptScreenState extends State<TranscriptScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
        // list view

        );
  }
}
