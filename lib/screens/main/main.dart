import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moshi_client/screens/main/progress.dart';
import 'package:provider/provider.dart';

import 'package:moshi_client/services/auth.dart';
import 'profile.dart';
import 'progress.dart';
import 'transcripts.dart';
import 'settings.dart';
import 'webrtc.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2; // TODO change to 0
  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      WebRTCScreen(),
      ProfileScreen(),
      ProgressScreen(),
      // TranscriptsScreen(),
      SettingsScreen(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser == null) {
      context.go('/');
    }
    Drawer menuDrawer = Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
            ),
            child: Text('Moshi'),
          ),
          ListTile(
            title: Text('Chat'),
            onTap: () {
              setState(() {
                _currentIndex = 0;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Progress'),
            onTap: () {
              setState(() {
                _currentIndex = 1;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Profile'),
            onTap: () {
              setState(() {
                _currentIndex = 2;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Settings'),
            onTap: () {
              setState(() {
                _currentIndex = 3;
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text('Moshi'),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: menuDrawer,
      body: _screens[_currentIndex],
    );
  }
}
