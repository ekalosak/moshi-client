import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:moshi/types.dart';
import 'package:moshi/screens/auth/make_profile.dart';
import 'package:moshi/screens/switch.dart';
import 'chat.dart';
import 'feed.dart';
import 'profile.dart';
import 'progress.dart';
import 'webrtc.dart';

class WrapperScreen extends StatefulWidget {
  // make WrapperScreen take User user as a param
  final User user;
  WrapperScreen({required this.user});
  @override
  _WrapperScreenState createState() => _WrapperScreenState();
}

// Sidebar indices
const int CHAT_INDEX = 0;
const int HOME_INDEX = 1;
const int PROFILE_INDEX = 2;
const int PROGRESS_INDEX = 3;
const int CHATV2_INDEX = 4;

// Progress page bottom navbar indices
const int PROG_VOCAB_INDEX = 0;
const int PROG_REPORT_INDEX = 1;
const int PROG_TRANSCRIPTS_INDEX = 2;

class _WrapperScreenState extends State<WrapperScreen> {
  Profile? profile;
  // int _index = HOME_INDEX;
  int _index = CHATV2_INDEX;
  int _progressIndex = PROG_TRANSCRIPTS_INDEX;
  Map<String, dynamic> languages = {};
  late StreamSubscription _profileListener;
  late StreamSubscription _supportedLangsListener;

  @override
  void initState() {
    super.initState();
    _profileListener = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        print("wrapper: User profile exists and is not empty.");
        setState(() {
          profile = Profile(
            uid: snapshot.id,
            lang: snapshot['language'],
            name: snapshot['name'],
            primaryLang: snapshot['native_language'],
          );
        });
      } else {
        print("wrapper: User profile doesn't exist or is empty.");
        Navigator.pushAndRemoveUntil(
            context, MaterialPageRoute(builder: (context) => MakeProfileScreen(user: widget.user)), (route) => false);
      }
    });
    _supportedLangsListener = FirebaseFirestore.instance
        .collection('config')
        .doc('languages')
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        print("wrapper: config/languages exists and isn't empty.");
        setState(() {
          languages = snapshot.data() as Map<String, dynamic>;
        });
      } else {
        print("wrapper: config/languages doesn't exist or is empty: ${snapshot.exists} ${snapshot.data()}");
      }
    });
  }

  @override
  void dispose() {
    _profileListener.cancel();
    _supportedLangsListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("wrapper: WrapperScreen.build");
    if (FirebaseAuth.instance.currentUser == null) {
      print("wrapper: FirebaseAuth.instance.currentUser == null");
      Navigator.of(context).pop();
    }
    if (profile == null || languages.isEmpty) {
      print("wrapper: profile == null: ${profile == null}");
      print("wrapper: languages.isEmpty: ${languages.isEmpty}");
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      print("wrapper: profile: ${profile?.name} ${profile?.uid}");
      print("wrapper: languages: ${languages.keys.toList().sublist(0, 5)}...");
      return _buildScaffold(profile!, languages);
    }
  }

  String getLangRepr(String lang) {
    try {
      return languages[lang]['country']['flag'];
    } catch (e) {
      print("wrapper: getLangEmoji: $e");
      return lang;
    }
  }

  Widget _buildScaffold(Profile pro, Map<String, dynamic> languages) {
    TextButton flagButton = _flagButton(pro, languages);
    IconButton profileButton = _profileButton(pro);
    Drawer menuDrawer = _drawer();
    Widget body = _body(pro, languages, _index);
    Widget? bottomNavigationBar = _bottomNavigationBar(_index);
    Text title = Text(
      _titleForIndex(_index),
      style: TextStyle(
        fontFamily: Theme.of(context).textTheme.headlineMedium!.fontFamily,
        fontSize: Theme.of(context).textTheme.headlineMedium!.fontSize,
        color: Theme.of(context).colorScheme.secondary,
      ),
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
        actions: [flagButton, profileButton],
      ),
      drawer: menuDrawer,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: Theme.of(context).colorScheme.background,
    );
  }

  Widget _body(Profile pro, Map<String, dynamic> languages, int index) {
    switch (index) {
      case CHAT_INDEX:
        return WebRTCScreen(profile: pro);
      case HOME_INDEX:
        return FeedScreen(profile: pro);
      case PROFILE_INDEX:
        return ProfileScreen(profile: pro, languages: languages);
      case PROGRESS_INDEX:
        return ProgressScreen(profile: pro, index: _progressIndex);
      case CHATV2_INDEX:
        return ChatScreen(profile: pro, languages: languages);
      default:
        throw ("ERROR: invalid index");
    }
  }

  /// Returns an IconButton that opens the user's profile page.
  IconButton _profileButton(Profile profile) {
    return IconButton(
      icon: Icon(
        Icons.person,
        color: Theme.of(context).colorScheme.primary,
        size: 32.0,
        shadows: [
          Shadow(
            color: Theme.of(context).colorScheme.primary,
            blurRadius: 2.0,
            offset: Offset(1.0, 1.0),
          ),
        ],
      ),
      onPressed: () {
        _changeIndex(PROFILE_INDEX);
      },
    );
  }

  /// Returns a TextButton that shows the user's language and opens a modal bottom sheet to change it.
  TextButton _flagButton(Profile profile, Map<String, dynamic> languages) {
    List<String> sortedLanguages = languages.keys.toList();
    sortedLanguages.sort();
    return TextButton(
      child: Text(
        getLangRepr(profile.lang),
        style: TextStyle(
          fontSize: 32.0,
        ),
      ),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return GridView.builder(
              itemCount: languages.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.0,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemBuilder: (BuildContext context, int index) {
                String lang = sortedLanguages[index];
                return GestureDetector(
                  onTap: () async {
                    String? err = await updateProfile(uid: profile.uid, targetLang: lang);
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
                    child: Text(
                      "${languages[lang]['country']['flag']} ${languages[lang]['country']['ISO-3166-1-alpha-2']}\n${languages[lang]['language']['name']}",
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.left,
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
      title: Text(text,
          style: TextStyle(
            fontFamily: Theme.of(context).textTheme.displayMedium!.fontFamily,
            fontSize: Theme.of(context).textTheme.displayMedium!.fontSize,
          )),
      visualDensity: VisualDensity.standard,
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
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                    ),
                    child: Text(
                      'ChatMoshi',
                      style: Theme.of(context).textTheme.displayLarge!.copyWith(
                            color: Theme.of(context).colorScheme.background,
                          ),
                    ),
                  ),
                  _listTile('Chat', CHAT_INDEX),
                  _listTile('Chat v2', CHATV2_INDEX),
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
                      print("wrapper: log out");
                      await FirebaseAuth.instance.signOut();
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => SwitchScreen()), (route) => false);
                      }
                    },
                    icon: Icon(
                      Icons.logout,
                      color: Theme.of(context).colorScheme.secondary,
                      size: Theme.of(context).textTheme.displayMedium!.fontSize,
                    ),
                    label: Text(
                      'Log out',
                      style: TextStyle(
                        fontFamily: Theme.of(context).textTheme.headlineMedium!.fontFamily,
                        fontSize: Theme.of(context).textTheme.headlineMedium!.fontSize,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
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
      case CHATV2_INDEX:
        return "";
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
      iconSize: 32.0,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.book),
          label: "",
          // label: 'Vocabulary',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: "",
          // label: 'Report Card',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_rounded),
          label: "",
          // label: 'Transcripts',
        ),
      ],
    );
  }
}
