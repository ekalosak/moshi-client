import 'package:flutter/material.dart';

import '../../services/auth.dart';
import 'progress.dart';
import 'settings.dart';
// import 'haishinkit.dart';
// import 'chat.dart';
// import 'webrtc.dart';
// import 'micstream.dart';
// import 'soundstream.dart';
// import 'audiocapture.dart';
import 'audiostream.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1;
  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      SettingsScreen(),
      ASScreen(),
      // ACScreen(),
      // MicStreamExampleApp(),
      // WebRTCScreen(),
      // SoundStreamScreen(),
      // ChatScreen(),
      ProgressScreen(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[400],
      appBar: AppBar(
        title: Text('Moshi'),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.transcribe),
            label: 'Chat',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.chat),
          //   label: 'Chat',
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}
