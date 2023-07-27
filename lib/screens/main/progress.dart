import 'package:flutter/material.dart';
import 'package:moshi_client/widgets/util.dart';
import 'package:moshi_client/types.dart';

class ProgressScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return authorized(context, withProfileAndConfig(_buildPage));
  }

  Widget _buildPage(BuildContext context, Profile profile, List<String> supportedLangs) {
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
