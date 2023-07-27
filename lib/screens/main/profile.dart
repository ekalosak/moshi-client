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
  String? err;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    nameCont.dispose();
    langCont.dispose();
    super.dispose();
  }

  // /// Get the supported languages from Firestore.
  Future<List<String>> _getSupportedLangs() async {
    DocumentReference<Map<String, dynamic>> documentReference =
        FirebaseFirestore.instance.collection('config').doc('supported_langs');
    DocumentSnapshot<Map<String, dynamic>> documentSnapshot = await documentReference.get();
    Map<String, dynamic> data = documentSnapshot.data()!;
    return data['langs'].cast<String>();
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
      Map<String, dynamic> data = documentSnapshot.data()!;
      return Profile(lang: data['lang'], name: data['name']);
    }
  }

  /// Update the user's profile document in Firestore.
  Future<String?> _updateProfile(String uid, Profile profile) async {
    String? err;
    DocumentReference<Map<String, dynamic>> documentReference =
        FirebaseFirestore.instance.collection('profiles').doc(uid);
    try {
      await documentReference.set({
        'lang': profile.lang,
        'name': profile.name,
      });
    } catch (e) {
      print("Unknown error");
      print(e);
      err = 'An error occurred. Please try again later.';
    }
    return err;
  }

  /// Build the profile form.
  /// If the user's profile document exists, populate the text fields with the profile data.
  /// Otherwise, leave the text fields blank.
  /// Listen to changes to the text fields - if the user changes the text, show the save button.
  ///
  Widget _profileForm(String uid) {
    String? err;
    List<String> langs = [];
    print("profile: _profileForm");
    return FutureBuilder(
      future: Future.wait([_getProfile(uid), _getSupportedLangs()]),
      builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
        print("profile: _profileForm: snapshot: $snapshot");
        if (snapshot.hasError) {
          err = "I had trouble finding your file, sorry about that.";
          print("profile: _profileForm: snapshot.hasError: ${snapshot.error.toString()}");
        } else if (snapshot.hasData) {
          Profile? profile = snapshot.data![0];
          langs = snapshot.data![1];
          print("langs: $langs");
          nameCont.text = profile!.name;
          langCont.text = profile.lang;
        } else if (snapshot.connectionState == ConnectionState.done) {
          print("profile: _profileForm: snapshot.connectionState == ConnectionState.done");
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else {
          err = "I had trouble finding your file, sorry about that.";
          print("unhandled case");
        }
        // if err show it to user
        if (err != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
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
                    print("name changed: $text");
                    // setState(() {});
                  },
                ),
                // Language dropdown from supported languages
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Language',
                  ),
                  value: "ja",
                  items: langs.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    print("lang changed: $newValue");
                  },
                ),
                // only show the FAB if there is any text in the text fields
                SizedBox(height: 16.0),
                if (nameCont.text.isNotEmpty || langCont.text.isNotEmpty)
                  FloatingActionButton.extended(
                    heroTag: "save_profile",
                    label: Text('Save'),
                    icon: Icon(Icons.save),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    onPressed: () async {
                      Profile profile = Profile(name: nameCont.text, lang: langCont.text);
                      // err = await _updateProfile(uid, profile) ?? "Profile saved!";
                      err = await _updateProfile(uid, profile);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(err ?? "Profile saved!")),
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
    print("screens/profile: build");
    final User user = FirebaseAuth.instance.currentUser!;
    print("screens/profile: build: user: $user");
    return Padding(padding: EdgeInsets.all(16.0), child: _profileForm(user.uid));
  }
}
