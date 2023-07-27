import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:moshi_client/storage.dart';
import 'package:moshi_client/util.dart';
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
  int _currentIndex = 2;
  final List<Widget> _screens = [];
  Profile? _profile;

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
    User? user_ = FirebaseAuth.instance.currentUser;
    if (user_ == null) {
      context.go('/a');
    }
    User user = user_!;
    Drawer menuDrawer = _makeDrawer();
    return FutureBuilder(
        future: Future.wait([getProfile(user.uid), getSupportedLangs()]),
        builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print("screens/main: error: ${snapshot.error.toString()}");
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Couldn't connect to Moshi servers. Please check your internet connection.")),
              );
            });
            return Container();
          } else {
            Profile profile = _profile ?? snapshot.data![0];
            List<String> supportedLangs = snapshot.data![1];
            TextButton flagButton = _flagButton(profile, supportedLangs);
            return _buildScaffold(menuDrawer, flagButton);
          }
        });
  }

  Scaffold _buildScaffold(Drawer menuDrawer, TextButton flagButton) {
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
                    Profile newProfile = Profile(uid: profile.uid, lang: lang, name: profile.name);
                    String? err = await updateProfile(uid: profile.uid, lang: lang);
                    if (err == null) {
                      setState(() {
                        _profile = newProfile;
                      });
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
                        // getLangEmoji(lang),
                        "${lang.toUpperCase()} ${getLangEmoji(lang)}",
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
