import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:moshi/types.dart';
import 'package:moshi/util.dart';
import 'package:moshi/screens/auth/make_profile.dart';
import 'info.dart';
import 'profile.dart';
import 'progress.dart';
import 'webrtc.dart';

class MainScreen extends StatefulWidget {
  // make MainScreen take User user as a param
  final User user;
  MainScreen({required this.user});
  @override
  _MainScreenState createState() => _MainScreenState();
}

// Main sidebar indices
const int CHAT_INDEX = 0;
const int HOME_INDEX = 1;
const int PROFILE_INDEX = 2;
const int PROGRESS_INDEX = 3;

// Progress page bottom navbar indices
const int PROG_VOCAB_INDEX = 0;
const int PROG_REPORT_INDEX = 1;
const int PROG_TRANSCRIPTS_INDEX = 2;

class _MainScreenState extends State<MainScreen> {
  Profile? profile;
  int _index = HOME_INDEX;
  int _progressIndex = PROG_TRANSCRIPTS_INDEX;
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
    IconButton profileButton = IconButton(
      icon: Icon(Icons.person),
      onPressed: () {
        _changeIndex(PROFILE_INDEX);
      },
    );
    Drawer menuDrawer = _drawer();
    Widget body = _body(pro, slans, _index);
    Widget? bottomNavigationBar = _bottomNavigationBar(_index);
    Text title = Text(
      _titleForIndex(_index),
      style: Theme.of(context).textTheme.headlineMedium,
    );
    return Scaffold(
      appBar: AppBar(
        title: title,
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
        actions: [profileButton, flagButton],
      ),
      drawer: menuDrawer,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
    );
  }

  Widget _body(Profile pro, List<String> slans, int index) {
    switch (index) {
      case CHAT_INDEX:
        return WebRTCScreen(profile: pro);
      case HOME_INDEX:
        return FeedScreen(profile: pro);
      case PROFILE_INDEX:
        return ProfileScreen(profile: pro, supportedLangs: slans);
      case PROGRESS_INDEX:
        return ProgressScreen(profile: pro, index: _progressIndex);
      default:
        throw ("ERROR: invalid index");
    }
  }

  /// Returns a TextButton that shows the user's language and opens a modal bottom sheet to change it.
  TextButton _flagButton(Profile profile, List<String> supportedLangs) {
    return TextButton(
      child: Text(
        getLangEmoji(profile.lang),
        style: TextStyle(
          fontSize: 36.0,
        ),
      ),
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

  ListTile _listTile(String text, int index) {
    return ListTile(
      title: Text(text),
      onTap: () {
        _changeIndex(index);
        Navigator.pop(context);
      },
    );
  }

  /// Returns a Drawer with links to the other screens (the hamburger menu).
  Drawer _drawer() {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.background,
      child: Column(
        children: [
          Expanded(
              flex: 13,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.background,
                      shape: BoxShape.rectangle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).colorScheme.secondary,
                          Theme.of(context).colorScheme.primary,
                        ],
                      ),
                    ),
                    child: Text(
                      'ChatMoshi',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.background,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _listTile('Chat', CHAT_INDEX),
                  _listTile('Feed', HOME_INDEX),
                  _listTile('Progress', PROGRESS_INDEX),
                ],
              )),
          Expanded(flex: 1, child: Container()),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    icon: Icon(
                      Icons.logout,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    label: Text(
                      'Log out',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 30.0,
                        fontFamily: Theme.of(context).textTheme.bodyMedium!.fontFamily,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      // backgroundColor: Theme.of(context).colorScheme.secondary,
                      backgroundColor: Colors.transparent,
                      textStyle: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 24.0,
                        fontFamily: Theme.of(context).textTheme.bodyMedium!.fontFamily,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    )),
              ),
            ),
          ),
          Expanded(flex: 1, child: Container()),
        ],
      ),
    );
  }

  String _titleForIndex(int index) {
    switch (index) {
      case CHAT_INDEX:
        return "";
      case HOME_INDEX:
        return "";
      case PROFILE_INDEX:
        return "";
      case PROGRESS_INDEX:
        switch (_progressIndex) {
          case PROG_VOCAB_INDEX:
            return "Vocabulary";
          case PROG_REPORT_INDEX:
            return "Report Card";
          case PROG_TRANSCRIPTS_INDEX:
            return "Transcripts";
          default:
            throw ("ERROR: invalid progress index");
        }
      default:
        throw ("ERROR: invalid index");
    }
  }

  Widget? _bottomNavigationBar(int index) {
    if (_index != PROGRESS_INDEX) {
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
          icon: Icon(Icons.bar_chart),
          label: 'Report Card',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_rounded),
          label: 'Transcripts',
        ),
      ],
    );
  }
}
