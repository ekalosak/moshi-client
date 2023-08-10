import 'package:flutter/material.dart';

import 'package:moshi/types.dart';
import 'package:moshi/screens/main/transcripts.dart';

class ProgressScreen extends StatefulWidget {
  final Profile profile;
  final int index;
  ProgressScreen({required this.profile, required this.index});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late Widget body;

  @override
  void initState() {
    super.initState();
    // body = TranscriptScreen(profile: widget.profile);
    body = _buildBody(widget.profile, widget.index);
  }

  Widget _buildBody(Profile pro, int index) {
    switch (index) {
      case 0:
        return Align(
          alignment: Alignment.topCenter,
          child: Text("Under construction..."),
        );
      case 1:
        return Align(
          alignment: Alignment.topCenter,
          child: Text("Under construction..."),
        );
      case 2:
        return TranscriptScreen(profile: pro);
      default:
        throw ("ERROR: invalid index");
    }
  }

  @override
  Widget build(BuildContext context) {
    // this is the body of a scaffold, do not create another scaffold
    // it needs a segmented button to switch between vocab, streak, and transcripts
    Widget body = _buildBody(widget.profile, widget.index);
    return Padding(
      padding: EdgeInsets.all(16),
      child: body,
    );
  }
}
