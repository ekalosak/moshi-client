import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:moshi_client/services/auth.dart';

/// Profile represents the user's profile document from Firestore.
/// It has these attributes:
/// - lang: the language code for the user's learning language
/// - name: the user's preferred name
class Profile {
  final String lang;
  final String name;
  Profile({required this.lang, required this.name});
}

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State {
  final TextEditingController nameCont = TextEditingController();
  final TextEditingController langCont = TextEditingController();
  late AuthService authService;
  String? err;

  @override
  void initState() {
    super.initState();
    setState(() {
      authService = Provider.of<AuthService>(context, listen: false);
    });
  }

  @override
  void dispose() {
    nameCont.dispose();
    langCont.dispose();
    super.dispose();
  }

  /// Get the user's profile document from Firestore.
  Future<Profile?> _getProfile(String uid) async {
    print("getting profile: uid: $uid");
    DocumentReference<Map<String, dynamic>> documentReference =
        FirebaseFirestore.instance.collection('profiles').doc(uid);
    print("got profile ref");
    DocumentSnapshot<Map<String, dynamic>> documentSnapshot = await documentReference.get();
    if (!documentSnapshot.exists) {
      print("snapshot doesn't exist");
      return null;
    } else {
      String name = authService.currentUser!.displayName ?? 'MissingName';
      Map<String, dynamic> data = documentSnapshot.data()!;
      return Profile(lang: data['lang'], name: name);
    }
  }

  /// Update the user's profile document in Firestore.
  Future<void> _updateProfile(String uid, Profile profile) async {
    DocumentReference<Map<String, dynamic>> documentReference =
        FirebaseFirestore.instance.collection('profiles').doc(uid);
    await FirebaseAuth.instance.currentUser!.updateDisplayName(profile.name);
    await documentReference.set({
      'lang': profile.lang,
      // 'name': profile.name,
    });
  }

  /// Get the supported language codes from Firestore.
  Future<List<String>> _getSupportedLangs() async {
    DocumentReference<Map<String, dynamic>> documentReference =
        FirebaseFirestore.instance.collection('config').doc('supported_langs');
    DocumentSnapshot<Map<String, dynamic>> documentSnapshot = await documentReference.get();
    Map<String, dynamic> data = documentSnapshot.data()!;
    return data['langs'].cast<String>();
  }

  /// Build the profile form.
  /// If the user's profile document exists, populate the text fields with the profile data.
  /// Otherwise, leave the text fields blank.
  /// Listen to changes to the text fields - if the user changes the text, show the save button.
  ///
  Widget _profileForm(String uid) {
    String? err;
    print("profile: _profileForm");
    return FutureBuilder(
      future: _getProfile(uid),
      builder: (BuildContext context, AsyncSnapshot<Profile?> snapshot) {
        print("profile: _profileForm: snapshot: $snapshot");
        if (snapshot.hasData) {
          Profile? profile = snapshot.data;
          nameCont.text = profile!.name;
          langCont.text = profile.lang;
        } else if (snapshot.hasError) {
          err = "I had trouble finding your file, sorry about that.";
          print("profile: _profileForm: snapshot.hasError: ${snapshot.error.toString()}");
        } else if (snapshot.connectionState == ConnectionState.done) {
          print("profile: _profileForm: snapshot.connectionState == ConnectionState.done");
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else {
          print("unhandled case");
        }
        // if err show it to user
        if (err != null) {
          WidgetsBinding.instance!.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(err!)),
            );
          });
        }
        return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: nameCont,
                  decoration: InputDecoration(
                    labelText: 'Name',
                  ),
                  onChanged: (String text) {
                    setState(() {});
                  },
                ),
                TextField(
                  controller: langCont,
                  decoration: InputDecoration(
                    labelText: 'Language',
                  ),
                  onChanged: (String text) {
                    setState(() {});
                  },
                ),
                // only show the FAB if there is any text in the text fields
                if (nameCont.text.isNotEmpty || langCont.text.isNotEmpty)
                  FloatingActionButton.extended(
                    heroTag: "save_profile",
                    label: Text('Save'),
                    icon: Icon(Icons.save),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    onPressed: () async {
                      Profile profile = Profile(name: nameCont.text, lang: langCont.text);
                      await _updateProfile(uid, profile);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Profile saved!")),
                      );
                    },
                  ),
              ],
            ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print("profile: build");
    // final User user = authService.currentUser!;
    final User user = FirebaseAuth.instance.currentUser!;
    print("screens/profile: build: user: $user");
    return Padding(padding: EdgeInsets.all(16.0), child: _profileForm(user.uid));
  }
}
