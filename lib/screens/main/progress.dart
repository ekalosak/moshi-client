import 'package:flutter/material.dart';

import 'package:moshi_client/types.dart';

class ProgressScreen extends StatelessWidget {
  final Profile profile;
  ProgressScreen({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(height: 16),
      Flexible(
        flex: 1,
        child: Text('Welcome, ${profile.name}!'),
      ),
      Flexible(
        flex: 9,
        child: Container(),
      ),
    ]);
  }
}
