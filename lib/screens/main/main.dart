import 'package:flutter/material.dart';

import '../../services/auth.dart';
import 'chat.dart';
import 'progress.dart';
import 'settings.dart';

class MainScreen extends StatefulWidget {
  final AuthService authService;

  MainScreen({required this.authService});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1;
  late AuthService _authService;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _authService = widget.authService;
    _screens.addAll([
      SettingsScreen(authService: _authService),
      ChatScreen(),
      ProgressScreen(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}
