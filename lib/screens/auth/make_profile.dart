import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:moshi_client/util.dart';
import 'package:moshi_client/widgets/util.dart';
import 'package:moshi_client/screens/home.dart';

// Create a new profile for the user in Firestore.
Future<String?> _createProfileFirestore(String uid, String name, String lang1, String lang2) async {
  print("_createProfileFirestore");
  String? err;
  DocumentReference<Map<String, dynamic>> documentReference =
      FirebaseFirestore.instance.collection('profiles').doc(uid);
  Map<String, dynamic> data = {
    'name': name,
    'lang': lang1,
    'primary_lang': lang2,
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

class MakeProfileScreen extends StatefulWidget {
  final User user;
  MakeProfileScreen({required this.user});
  @override
  _MakeProfileScreenState createState() => _MakeProfileScreenState();
}

class _MakeProfileScreenState extends State<MakeProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  bool isLoading = false;
  List<String>? supportedLangs;
  String? firstLang;
  String? secondLang;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  // Validate the input and create a new profile for the user in Firestore.
  Future<String?> _createProfile() async {
    String? err;
    String name = nameController.text;
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

  @override
  Widget build(BuildContext context) {
    return authorized(context, withConfig(_buildScaffold));
  }

  Widget _buildScaffold(BuildContext context, List<String> supportedLangs) {
    firstLang = firstLang ?? supportedLangs[0];
    secondLang = secondLang ?? supportedLangs[0];
    return Scaffold(
      appBar: AppBar(title: Text('Set up your profile')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Stack(
          children: [
            if (isLoading) CircularProgressIndicator(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'What should Moshi call you?',
                  ),
                ),
                _firstDropdown(supportedLangs),
                _secondDropdown(supportedLangs),
                _makeProfileButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _makeProfileButton() {
    return FloatingActionButton.extended(
      heroTag: "save_profile",
      label: Text('Save'),
      icon: Icon(Icons.person_add),
      backgroundColor: Theme.of(context).colorScheme.primary,
      onPressed: () async {
        String? err = await _createProfile();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err ?? "Profile created!")),
          );
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
}
