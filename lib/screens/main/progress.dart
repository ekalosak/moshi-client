import 'package:flutter/material.dart';

import 'package:moshi_client/types.dart';
import 'package:moshi_client/screens/main/transcripts.dart';

class ProgressScreen extends StatefulWidget {
  final Profile profile;
  ProgressScreen({required this.profile});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late Widget body;

  @override
  void initState() {
    super.initState();
    body = TranscriptScreen(profile: widget.profile);
  }

  SegmentedButton _pageSelector() {
    return SegmentedButton(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: 0,
          icon: Icon(Icons.book),
          label: Text('Vocabulary'),
        ),
        ButtonSegment(
          value: 1,
          icon: Icon(Icons.trending_up),
          label: Text('Streak'),
        ),
        ButtonSegment(
          value: 0,
          icon: Icon(Icons.all_inbox_rounded),
          label: Text('Transcripts'),
        ),
      ],
      selected: <int>{0},
      onSelectionChanged: (p0) {
        print('SegmentedButton.onSelectionChanged: $p0');
        setState(() {
          switch (p0) {
            case 0:
              print("TODO");
              // body = VocabScreen(profile: widget.profile);
              break;
            case 1:
              print("TODO");
              // body = StreakScreen(profile: widget.profile);
              break;
            case 2:
              body = TranscriptScreen(profile: widget.profile);
              break;
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // this is the body of a scaffold, do not create another scaffold
    // it needs a segmented button to switch between vocab, streak, and transcripts
    return Padding(
        padding: EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Flexible(flex: 1, child: _pageSelector()),
          Flexible(flex: 9, child: body),
        ]));
  }
}
