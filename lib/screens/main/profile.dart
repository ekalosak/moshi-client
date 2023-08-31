import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:moshi/types.dart';
import 'package:moshi/util.dart';

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
        padding: EdgeInsets.all(48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _nameField(),
            _languageDropdown(),
            SizedBox(height: 48.0),
            _saveButton(),
          ],
        ));
  }

  DropdownButtonFormField<String> _languageDropdown() {
    return DropdownButtonFormField<String>(
      menuMaxHeight: 300.0,
      decoration: InputDecoration(
        labelText: "Native language",
        labelStyle: TextStyle(
          fontSize: Theme.of(context).textTheme.headlineMedium?.fontSize,
          fontFamily: Theme.of(context).textTheme.headlineMedium?.fontFamily,
        ),
      ),
      value: widget.profile.primaryLang,
      items: widget.supportedLangs.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            "${getLangEmoji(value)} ${value.toUpperCase()}",
            style: TextStyle(
              fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
              fontFamily: Theme.of(context).textTheme.headlineMedium?.fontFamily,
            ),
          ),
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
      label: Text(
        'Save',
        style: TextStyle(
          fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
          fontFamily: Theme.of(context).textTheme.headlineSmall?.fontFamily,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      icon: Icon(
        Icons.save,
        color: Theme.of(context).colorScheme.onPrimary,
        size: Theme.of(context).textTheme.headlineSmall?.fontSize,
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      onPressed: () async {
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
        labelStyle: TextStyle(
          fontSize: Theme.of(context).textTheme.headlineMedium?.fontSize,
          fontFamily: Theme.of(context).textTheme.headlineMedium?.fontFamily,
        ),
      ),
      style: TextStyle(
        fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
        fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
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
