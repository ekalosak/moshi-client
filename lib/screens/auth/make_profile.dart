import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:moshi/util.dart';
import 'package:moshi/screens/home.dart';

class MakeProfileScreen extends StatefulWidget {
  final User user;
  MakeProfileScreen({required this.user});
  @override
  _MakeProfileScreenState createState() => _MakeProfileScreenState();
}

class _MakeProfileScreenState extends State<MakeProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  late Stream<DocumentSnapshot> _supportedLangsStream;
  List<String> supportedLangs = [];
  bool isLoading = false;
  String? firstLang;
  String? secondLang;

  @override
  void initState() {
    super.initState();
    _supportedLangsStream = FirebaseFirestore.instance.collection('config').doc('supported_langs').snapshots();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Set up your profile')),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: StreamBuilder(
            stream: _supportedLangsStream,
            builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                throw ("ERROR make_profile supported_langs snapshot: ${snapshot.error.toString()}");
              } else {
                supportedLangs = snapshot.data!['langs'].cast<String>();
                return _makeProfileForm();
              }
            },
          ),
        ));
  }

  Widget _makeProfileForm() {
    firstLang = firstLang ?? supportedLangs[0];
    secondLang = secondLang ?? supportedLangs[0];
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
              ),
            ),
            _firstDropdown(supportedLangs),
            _secondDropdown(supportedLangs),
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
      label: Text('Save'),
      icon: Icon(Icons.person_add),
      backgroundColor: (isLoading) ? Colors.grey : Theme.of(context).colorScheme.primary,
      onPressed: () async {
        if (isLoading) {
          return;
        }
        String? err = await _createProfile();
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
      decoration: InputDecoration(
        labelText: "Native language",
      ),
      value: firstLang,
      items: supportedLangs.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text("${getLangEmoji(value)} ${value.toUpperCase()}"),
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
      decoration: InputDecoration(
        labelText: "Target language",
      ),
      value: secondLang,
      items: supportedLangs.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text("${getLangEmoji(value)} ${value.toUpperCase()}"),
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
  Future<String?> _createProfile() async {
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
