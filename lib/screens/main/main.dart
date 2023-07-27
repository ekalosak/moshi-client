import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:moshi_client/storage.dart';
import 'package:moshi_client/util.dart';
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
    User? user_ = FirebaseAuth.instance.currentUser;
    if (user_ == null) {
      context.go('/a');
    }
    User user = user_!;
    final Stream<DocumentSnapshot> profileStream =
        FirebaseFirestore.instance.collection('profiles').doc(user.uid).snapshots(includeMetadataChanges: true);
    final Stream<DocumentSnapshot> supportedLangsStream =
        FirebaseFirestore.instance.collection('config').doc('supported_langs').snapshots();
    return StreamBuilder<DocumentSnapshot>(
        stream: supportedLangsStream,
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> slSnap) {
          return StreamBuilder<DocumentSnapshot>(
            stream: profileStream,
            builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> pSnap) {
              return _buildMainScreen(context, pSnap, slSnap);
            },
          );
        });
  }

  // Inside the StreamBuilder, we have access to the profile snapshot and the supported_langs snapshot.
  // If either snapshot is loading, we show a loading indicator.
  // If either snapshot has an error, we show an error message.
  // Otherwise, we show the main screen.
  Widget _buildMainScreen(
      BuildContext context, AsyncSnapshot<DocumentSnapshot> pSnap, AsyncSnapshot<DocumentSnapshot> slSnap) {
    print("_buildMainScreen: pSnap: ${pSnap.connectionState}, slSnap: ${slSnap.connectionState}");
    if (pSnap.connectionState == ConnectionState.waiting || slSnap.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    } else if (pSnap.hasError) {
      print("_buildMainScreen: ERROR: profile snapshot: ${pSnap.error.toString()}");
    } else if (slSnap.hasError) {
      print("_buildMainScreen: ERROR: supported_langs snapshot: ${slSnap.error.toString()}");
    } else {
      List<String> supportedLangs = slSnap.data!['langs'].cast<String>();
      Profile profile = Profile(
        uid: pSnap.data!.id,
        lang: pSnap.data!['lang'],
        name: pSnap.data!['name'],
        primaryLang: pSnap.data!['primary_lang'],
      );
      TextButton flagButton = _flagButton(profile, supportedLangs);
      Drawer menuDrawer = _makeDrawer();
      return _buildScaffold(menuDrawer, flagButton);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Couldn't connect to Moshi servers. Please check your internet connection.")),
    );
    return Container();
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
