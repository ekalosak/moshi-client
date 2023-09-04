import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:moshi/screens/switch.dart';

class MakeProfileScreen extends StatefulWidget {
  final User user;
  MakeProfileScreen({required this.user});
  @override
  _MakeProfileScreenState createState() => _MakeProfileScreenState();
}

class _MakeProfileScreenState extends State<MakeProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  late Stream<DocumentSnapshot> _languageStream;
  Map<String, dynamic> languages = {};
  bool isLoading = false;
  String? firstLang;
  String? secondLang;

  @override
  void initState() {
    super.initState();
    _languageStream = FirebaseFirestore.instance.collection('config').doc('languages').snapshots();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String getLangEmoji(String lang) {
    try {
      return languages[lang]['country']['flag'];
    } catch (e) {
      print(e);
      return '';
    }
  }

  String getLangName(String lang) {
    try {
      return languages[lang]['language']['full_name'];
    } catch (e) {
      print(e);
      return '';
    }
  }

  String langString(String lang) {
    return "${getLangEmoji(lang)} ${getLangName(lang)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
        'Set up your profile',
        style: Theme.of(context).textTheme.displaySmall,
      )),
      body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text("You can change these later."),
            StreamBuilder(
              stream: _languageStream,
              builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  throw ("make_profile languages snapshot: ${snapshot.error.toString()}");
                } else {
                  // The doc is a map from e.g. "en-US" to the details about the language (name, emoji, etc.); Convert the doc into a map.
                  try {
                    languages = snapshot.data!.data() as Map<String, dynamic>;
                  } catch (e) {
                    return Text("Eric forgot to initialize the database.");
                  }
                  return _makeUserForm();
                }
              },
            ),
          ])),
    );
  }

  Widget _makeUserForm() {
    List<String> languageCodes = languages.keys.toList();
    // sort the language codes
    languageCodes.sort((a, b) => getLangName(a).compareTo(getLangName(b)));
    print("make_profile languageCodes.length: ${languageCodes.length}");
    print("make_profile unique languageCodes.length: ${languageCodes.toSet().toList().length}");
    // int rand1 = Random().nextInt(languageCodes.length);
    int rand2 = Random().nextInt(languageCodes.length);
    firstLang = firstLang ?? "en-US";
    secondLang = secondLang ?? languageCodes[rand2];
    return Stack(
      children: [
        if (isLoading) CircularProgressIndicator(),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onBackground,
                fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize,
                fontFamily: Theme.of(context).textTheme.headlineSmall!.fontFamily,
              ),
              decoration: InputDecoration(
                labelText: 'What should Moshi call you?',
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize,
                  fontFamily: Theme.of(context).textTheme.headlineSmall!.fontFamily,
                ),
              ),
            ),
            _firstDropdown(languageCodes),
            _secondDropdown(languageCodes),
            Container(height: 16.0),
            _makeProfileButton(),
          ]
              .map((e) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: e,
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _makeProfileButton() {
    return FloatingActionButton.extended(
      heroTag: "save_profile",
      label: Text(
        'Save',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: Theme.of(context).textTheme.headlineSmall!.fontSize,
          fontFamily: Theme.of(context).textTheme.headlineSmall!.fontFamily,
        ),
      ),
      icon: Icon(
        Icons.person_add,
        size: Theme.of(context).textTheme.headlineSmall!.fontSize,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
      backgroundColor: (isLoading) ? Colors.grey : Theme.of(context).colorScheme.primary,
      onPressed: () async {
        if (isLoading) {
          return;
        }
        String? err = await _createUser();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
              (err == null) ? SnackBar(content: Text("✅ Profile created!")) : SnackBar(content: Text("❌ $err")));
        });
        if (err == null) {
          if (mounted) {
            Navigator.of(context)
                .pushAndRemoveUntil(MaterialPageRoute(builder: (context) => SwitchScreen()), (route) => false);
          }
        }
      },
    );
  }

  Widget _firstDropdown(List<String> supportedLangs) {
    return DropdownButtonFormField<String>(
      menuMaxHeight: 300.0,
      decoration: InputDecoration(
        labelText: "Native language",
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: Theme.of(context).textTheme.headlineSmall!.fontSize,
          fontFamily: Theme.of(context).textTheme.headlineSmall!.fontFamily,
        ),
      ),
      value: firstLang,
      items: supportedLangs.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            langString(value),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onBackground,
              fontSize: Theme.of(context).textTheme.bodyMedium!.fontSize,
              fontFamily: Theme.of(context).textTheme.headlineSmall!.fontFamily,
            ),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          firstLang = newValue;
        });
      },
    );
  }

  Widget _secondDropdown(List<String> supportedLangs) {
    return DropdownButtonFormField<String>(
      menuMaxHeight: 300.0,
      decoration: InputDecoration(
        labelText: "Target language",
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: Theme.of(context).textTheme.headlineSmall!.fontSize,
          fontFamily: Theme.of(context).textTheme.headlineSmall!.fontFamily,
        ),
      ),
      value: secondLang,
      items: supportedLangs.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            langString(value),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onBackground,
              fontSize: Theme.of(context).textTheme.bodyMedium!.fontSize,
              fontFamily: Theme.of(context).textTheme.headlineSmall!.fontFamily,
            ),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          secondLang = newValue;
        });
      },
    );
  }

  // Validate the input and create a new profile for the user in Firestore.
  Future<String?> _createUser() async {
    String? err;
    String name = _nameController.text;
    if (name == '') {
      return "Please provide a name Moshi can call you.";
    } else if (firstLang == null || secondLang == null) {
      return "Please select your native language and the language you're learning.";
    }
    setState(() {
      isLoading = true;
    });
    err = await _createUserFirestore(widget.user.uid, name, firstLang!, secondLang!);
    setState(() {
      isLoading = false;
    });
    return err;
  }
}

// Create a new profile for the user in Firestore.
Future<String?> _createUserFirestore(String uid, String name, String lang1, String lang2) async {
  String? err;
  print("make_profile: CALLING FUNCTION CREATE USER");
  try {
    final result = await FirebaseFunctions.instance
        .httpsCallable('create_user')
        .call({'uid': uid, 'name': name, 'language': lang2, 'native_language': lang1});
    print("make_profile: CALLED FUNCTION CREATE USER");
    print("make_profile: FUNCTION RESULT: ${result.data}");
    // This userDoc get updates the local cache of the user's profile. If we don't do this, the user's profile will be empty and the wrapper will redirect to the make_profile page again.
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    print("make_profile: userDoc.data(): ${userDoc.data()}");
  } catch (e) {
    print("ERROR CALLING FUNCTION CREATE USER");
    print(e);
    if (e is FirebaseFunctionsException) {
      print(e.message);
      if (e.code != 'already-exists') {
        // Pass because it doesn't matter, the main page will load as long as there's a user.
        err = e.message;
      }
    }
  }
  return err;
}
