import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:moshi/screens/home.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
        'Set up your profile',
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          fontSize: Theme.of(context).textTheme.displaySmall!.fontSize,
          fontFamily: Theme.of(context).textTheme.displaySmall!.fontFamily,
        ),
      )),
      body: Column(children: [
        Flexible(flex: 2, child: Container()),
        Flexible(flex: 2, child: Padding(padding: EdgeInsets.all(16.0), child: Text("You can change these later."))),
        Flexible(
            flex: 8,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: StreamBuilder(
                stream: _languageStream,
                builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                  print("snapshot: ${snapshot.connectionState}");
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    throw ("make_profile languages snapshot: ${snapshot.error.toString()}");
                  } else {
                    // The doc is a map from e.g. "en-US" to the details about the language (name, emoji, etc.); Convert the doc into a map.
                    languages = snapshot.data!.data() as Map<String, dynamic>;
                    return _makeUserForm();
                  }
                },
              ),
            )),
        Flexible(flex: 2, child: Container()),
      ]),
    );
  }

  Widget _makeUserForm() {
    List<String> languageCodes = languages.keys.toList();
    print("make_profile languageCodes.length: ${languageCodes.length}");
    print("make_profile unique languageCodes.length: ${languageCodes.toSet().toList().length}");
    int rand1 = Random().nextInt(languageCodes.length);
    int rand2 = Random().nextInt(languageCodes.length);
    firstLang = firstLang ?? languageCodes[rand1];
    secondLang = secondLang ?? languageCodes[rand2];
    return Stack(
      children: [
        if (isLoading) CircularProgressIndicator(),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'What should Moshi call you?',
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground,
                  fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize,
                  fontFamily: Theme.of(context).textTheme.headlineSmall!.fontFamily,
                ),
              ),
            ),
            _firstDropdown(languageCodes),
            _secondDropdown(languageCodes),
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
                .pushAndRemoveUntil(MaterialPageRoute(builder: (context) => HomeScreen()), (route) => false);
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
          color: Theme.of(context).colorScheme.onBackground,
          fontSize: Theme.of(context).textTheme.headlineSmall!.fontSize,
          fontFamily: Theme.of(context).textTheme.headlineSmall!.fontFamily,
        ),
      ),
      value: firstLang,
      items: supportedLangs.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            "${getLangEmoji(value)} ${value.toUpperCase()}",
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
          color: Theme.of(context).colorScheme.onBackground,
          fontSize: Theme.of(context).textTheme.headlineSmall!.fontSize,
          fontFamily: Theme.of(context).textTheme.headlineSmall!.fontFamily,
        ),
      ),
      value: secondLang,
      items: supportedLangs.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            "${value.toUpperCase()}",
            // "${getLangEmoji(value)} ${value.toUpperCase()}",
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
    err = await _createProfileFirestore(widget.user.uid, name, firstLang!, secondLang!);
    setState(() {
      isLoading = false;
    });
    return err;
  }
}

// Create a new profile for the user in Firestore.
Future<String?> _createProfileFirestore(String uid, String name, String lang1, String lang2) async {
  print("_createProfileFirestore");
  String? err;
  DocumentReference<Map<String, dynamic>> documentReference =
      FirebaseFirestore.instance.collection('profiles').doc(uid);
  Map<String, dynamic> data = {
    'name': name,
    'lang': lang2,
    'primary_lang': lang1,
  };
  try {
    await documentReference.set(data);
  } catch (e) {
    print("Unknown error");
    print(e);
    err = 'An error occurred. Please try again later.';
  }
  return err;
}
