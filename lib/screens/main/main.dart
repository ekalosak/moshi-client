import 'package:flutter/material.dart';

import 'package:moshi_client/storage.dart';
import 'package:moshi_client/util.dart';
import 'package:moshi_client/widgets/util.dart';
import 'profile.dart';
import 'progress.dart';
// import 'transcripts.dart';
// import 'news.dart';  // updates, news, etc.
// import 'feedback.dart';
import 'settings.dart';
import 'webrtc.dart';

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
      WebRTCScreen(),
      ProfileScreen(),
      ProgressScreen(),
      // TranscriptsScreen(),
      SettingsScreen(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return authorized(context, withProfileAndConfig(_buildScaffold));
  }

  /// Returns a Scaffold with a hamburger menu, a flag button, and a body.
  Scaffold _buildScaffold(BuildContext context, Profile profile, List<String> supportedLangs) {
    TextButton flagButton = _flagButton(profile, supportedLangs);
    Drawer menuDrawer = _makeDrawer();
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
        actions: [flagButton],
      ),
      drawer: menuDrawer,
      body: _screens[_currentIndex],
    );
  }

  /// Returns a TextButton that shows the user's language and opens a modal bottom sheet to change it.
  TextButton _flagButton(Profile profile, List<String> supportedLangs) {
    return TextButton(
      child: Text(getLangEmoji(profile.lang)),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return GridView.builder(
              itemCount: supportedLangs.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemBuilder: (BuildContext context, int index) {
                String lang = supportedLangs[index];
                return GestureDetector(
                  onTap: () async {
                    String? err = await updateProfile(uid: profile.uid, lang: lang);
                    if (err == null) {
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    } else {
                      print("ERROR: $err");
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Whoops! Couldn't update your language. Please try again later.")),
                        );
                      });
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Center(
                      child: Text(
                        getLangEmoji(lang),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 24.0,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Returns a Drawer with links to the other screens (the hamburger menu).
  Drawer _makeDrawer() {
    return Drawer(
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
            title: Text('Profile'),
            onTap: () {
              setState(() {
                _currentIndex = 1;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Progress'),
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
  }
}
