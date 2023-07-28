import 'package:flutter/material.dart';

import 'package:moshi_client/storage.dart';
import 'package:moshi_client/types.dart';
import 'package:moshi_client/util.dart';

class ProfileScreen extends StatefulWidget {
  Profile profile;
  List<String> supportedLangs;
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
        String? err = await updateProfile(
          uid: widget.profile.uid,
          name: nameCont.text,
          primaryLang: widget.profile.primaryLang,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err ?? "Profile saved!")),
          );
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
