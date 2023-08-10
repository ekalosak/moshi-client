import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:moshi_client/types.dart';
import 'package:moshi_client/util.dart';
import 'package:moshi_client/screens/auth/make_profile.dart';
import 'info.dart';
import 'profile.dart';
import 'progress.dart';
import 'settings.dart';
import 'webrtc.dart';

class MainScreen extends StatefulWidget {
  // make MainScreen take User user as a param
  final User user;
  MainScreen({required this.user});
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Profile? profile;
  int _index = 2;
  int _progressIndex = 2;
  List<String> supportedLangs = [];
  late StreamSubscription _profileListener;
  late StreamSubscription _supportedLangsListener;

  @override
  void initState() {
    super.initState();
    _profileListener = FirebaseFirestore.instance
        .collection('profiles')
        .doc(widget.user.uid)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        print("Profile exists and is not empty: $snapshot");
        setState(() {
          profile = Profile(
            uid: snapshot.id,
            lang: snapshot['lang'],
            name: snapshot['name'],
            primaryLang: snapshot['primary_lang'],
          );
        });
      } else {
        print("Profile doesn't exist or is empty.");
        print("snapshot: $snapshot");
        Navigator.pushAndRemoveUntil(
            context, MaterialPageRoute(builder: (context) => MakeProfileScreen(user: widget.user)), (route) => false);
      }
    });
    _supportedLangsListener = FirebaseFirestore.instance
        .collection('config')
        .doc('supported_langs')
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        print("Supported langs exist and aren't empty: $snapshot");
        setState(() {
          supportedLangs = snapshot['langs'].cast<String>();
        });
      } else {
        // TODO show an error page. this is a fatal error.
        throw Exception("Supported languages don't exist or is empty.");
      }
    });
  }

  @override
  void dispose() {
    _profileListener.cancel();
    _supportedLangsListener.cancel();
    super.dispose();
  }

  // TODO show a loading screen, not just a spinner
  @override
  Widget build(BuildContext context) {
    print("MainScreen.build");
    print("profile: $profile");
    print("supportedLangs: $supportedLangs");
    if (profile == null || supportedLangs.isEmpty) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return _buildScaffold(profile!, supportedLangs);
    }
  }

  Widget _buildScaffold(Profile pro, List<String> slans) {
    TextButton flagButton = _flagButton(pro, supportedLangs);
    Drawer menuDrawer = _drawer();
    Widget body = _body(pro, slans, _index);
    Widget? bottomNavigationBar = _bottomNavigationBar(_index);
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForIndex(_index)),
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
      body: body,
      bottomNavigationBar: bottomNavigationBar,
    );
  }

  Widget _body(Profile pro, List<String> slans, int index) {
    switch (index) {
      case 0:
        return WebRTCScreen(profile: pro);
      case 1:
        return InfoScreen(profile: pro);
      case 2:
        return ProfileScreen(profile: pro, supportedLangs: slans);
      case 3:
        return ProgressScreen(profile: pro, index: _progressIndex);
      case 4:
        return SettingsScreen();
      default:
        throw ("ERROR: invalid index");
    }
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

  void _changeIndex(int index) {
    setState(() {
      _index = index;
    });
  }

  void _changeProgressIndex(int index) {
    setState(() {
      _progressIndex = index;
    });
  }

  /// Returns a Drawer with links to the other screens (the hamburger menu).
  Drawer _drawer() {
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
              _changeIndex(0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Info'),
            onTap: () {
              _changeIndex(1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Profile'),
            onTap: () {
              _changeIndex(2);
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Progress'),
            onTap: () {
              _changeIndex(3);
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Settings'),
            onTap: () {
              _changeIndex(4);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  String _titleForIndex(int index) {
    switch (index) {
      case 0:
        return "Chat";
      case 1:
        return "Info";
      case 2:
        return "Profile";
      case 3:
        switch (_progressIndex) {
          case 0:
            return "Vocabulary";
          case 1:
            return "Streak";
          case 2:
            return "Transcripts";
          default:
            throw ("ERROR: invalid progress index");
        }
      case 4:
        return "Settings";
      default:
        throw ("ERROR: invalid index");
    }
  }

  Widget? _bottomNavigationBar(int index) {
    if (_index != 2) {
      return null;
    }
    return BottomNavigationBar(
      currentIndex: _progressIndex,
      onTap: _changeProgressIndex,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.book),
          label: 'Vocabulary',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.trending_up),
          label: 'Streak',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_rounded),
          label: 'Transcripts',
        ),
      ],
    );
  }
}
