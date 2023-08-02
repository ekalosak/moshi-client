import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:moshi_client/types.dart';
import 'package:moshi_client/util.dart';

class ProfileScreen extends StatefulWidget {
  final Profile profile;
  final List<String> supportedLangs;
  ProfileScreen({required this.profile, required this.supportedLangs});
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController nameCont = TextEditingController();
  late String primaryLang;

  @override
  void initState() {
    primaryLang = widget.profile.primaryLang;
    nameCont.text = widget.profile.name;
    super.initState();
  }

  @override
  void dispose() {
    nameCont.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _nameField(),
            _languageDropdown(),
            SizedBox(height: 16.0),
            _saveButton(),
          ],
        ));
  }

  DropdownButtonFormField<String> _languageDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: "Native language"),
      value: widget.profile.primaryLang,
      items: widget.supportedLangs.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text("${getLangEmoji(value)} ${value.toUpperCase()}"),
        );
      }).toList(),
      onChanged: (String? newValue) {
        primaryLang = newValue!;
      },
    );
  }

  FloatingActionButton _saveButton() {
    return FloatingActionButton.extended(
      heroTag: "save_profile",
      label: Text('Save'),
      icon: Icon(Icons.save),
      backgroundColor: Theme.of(context).colorScheme.primary,
      onPressed: () async {
        print("uid: ${widget.profile.uid}");
        print("name: ${nameCont.text}");
        print("primaryLang: $primaryLang");
        String? err = await updateProfile(
          uid: widget.profile.uid,
          name: nameCont.text,
          primaryLang: primaryLang,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar((err == null)
              ? SnackBar(
                  content: Text("✅ Profile saved!"),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                )
              : SnackBar(
                  content: Text("❌ Error saving profile, please try again."),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ));
        });
      },
    );
  }

  TextField _nameField() {
    return TextField(
      controller: nameCont,
      decoration: InputDecoration(
        labelText: 'Name',
      ),
    );
  }
}

/// Update the user's profile document in Firestore.
// Require string uid; optional string lang, name, primaryLang.
Future<String?> updateProfile({required String uid, String? lang, String? name, String? primaryLang}) async {
  String? err;
  print("updateProfile: uid: $uid, lang: $lang, name: $name, primaryLang: $primaryLang");
  DocumentReference<Map<String, dynamic>> documentReference =
      FirebaseFirestore.instance.collection('profiles').doc(uid);
  try {
    // construct a map of the fields to update
    Map<String, dynamic> data = {};
    if (lang != null) {
      data['lang'] = lang;
    }
    if (name != null) {
      data['name'] = name;
    }
    if (primaryLang != null) {
      data['primary_lang'] = primaryLang;
    }
    await documentReference.update(data);
  } catch (e) {
    print("Unknown error");
    print(e);
    err = 'An error occurred. Please try again later.';
  }
  return err;
}
