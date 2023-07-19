import 'package:flutter/material.dart';
import 'package:flutter_audio_capture:flutter_audio_capture.dart';

class ACScreen extends StatefulWidget {
  @override
  _ACScreenState createState() => _ACScreenState();
}

class _ACScreenState extends State<ACScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void buttonClicked() {
    print('clicked');
  }

  @override
  Widget build(BuildContext context) {
    print("screens/main/webrtc build start");
    final authService = Provider.of<AuthService>(context, listen: false);
    return Container(
      child: Center(
        child: ElevatedButton(
          onPressed: buttonClicked,
          child: const Text('start'),
        )
      ),
    );
  }
}
