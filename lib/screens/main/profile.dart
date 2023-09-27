import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:moshi/types.dart';

class ProfileScreen extends StatefulWidget {
  final Profile profile;
  final Map<String, dynamic> languages;
  ProfileScreen({required this.profile, required this.languages});
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

  String getLangRepr(String lang) {
    String flag = widget.languages[lang]['country']['flag'];
    String name = widget.languages[lang]['language']['alt_full_name'];
    return "$flag $name";
  }

  DropdownButtonFormField<String> _languageDropdown() {
    List<String> languages = widget.languages.keys.toList();
    languages.sort(
        (a, b) => widget.languages[a]['language']['full_name'].compareTo(widget.languages[b]['language']['full_name']));
    return DropdownButtonFormField<String>(
      menuMaxHeight: 300.0,
      decoration: InputDecoration(
        labelText: "Native Language",
        labelStyle: TextStyle(
          fontSize: Theme.of(context).textTheme.headlineMedium?.fontSize,
          fontFamily: Theme.of(context).textTheme.headlineMedium?.fontFamily,
        ),
      ),
      value: widget.profile.primaryLang,
      items: languages.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            getLangRepr(value),
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
          nativeLang: primaryLang,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar((err == null)
              ? SnackBar(
                  content: Text("✅ Profile saved!",
                      style: TextStyle(
                        fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                        fontFamily: Theme.of(context).textTheme.headlineMedium?.fontFamily,
                        color: Theme.of(context).colorScheme.onPrimary,
                      )),
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
        fontFamily: Theme.of(context).textTheme.headlineMedium?.fontFamily,
      ),
    );
  }
}

/// Update the user's profile document in Firestore.
// Require string uid; optional string lang, name, primaryLang.
Future<String?> updateProfile({required String uid, String? targetLang, String? name, String? nativeLang}) async {
  String? err;
  // print("updateProfile: uid: $uid, targetLanguage: $targetLang, name: $name, nativeLanguage: $nativeLang");
  DocumentReference<Map<String, dynamic>> documentReference = FirebaseFirestore.instance.collection('users').doc(uid);
  try {
    // construct a map of the fields to update
    Map<String, dynamic> data = {};
    if (targetLang != null) {
      data['language'] = targetLang;
    }
    if (name != null) {
      data['name'] = name;
    }
    if (nativeLang != null) {
      data['native_language'] = nativeLang;
    }
    await documentReference.update(data);
  } catch (e) {
    // print("Unknown error");
    // print(e);
    err = 'An error occurred: $e';
  }
  return err;
}
