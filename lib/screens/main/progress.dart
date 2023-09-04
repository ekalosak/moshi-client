import 'package:flutter/material.dart';

import 'package:moshi/types.dart';
import 'package:moshi/screens/main/transcripts.dart';

class ProgressScreen extends StatefulWidget {
  final Profile profile;
  final Map<String, dynamic> languages;
  final int index;
  ProgressScreen({required this.profile, required this.languages, required this.index});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late Widget body;

  @override
  void initState() {
    super.initState();
    body = _buildBody();
  }

  Widget _buildBody() {
    switch (widget.index) {
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
        return TranscriptScreen(profile: widget.profile, languages: widget.languages);
      default:
        throw ("ERROR: invalid index");
    }
  }

  @override
  Widget build(BuildContext context) {
    // this is the body of a scaffold, do not create another scaffold
    // it needs a segmented button to switch between vocab, report, and transcripts
    Widget body = _buildBody();
    return Padding(
      padding: EdgeInsets.all(16),
      child: body,
    );
  }
}
