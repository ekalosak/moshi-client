import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:moshi_client/storage.dart';
import 'package:moshi_client/types.dart';
import 'package:moshi_client/widgets/util.dart';
import 'package:moshi_client/widgets/langdropdown.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController nameCont = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    nameCont.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return authorized(context, withProfileAndConfig(_profileForm));
  }

  Widget _profileForm(BuildContext context, Profile pro, List<String> slans) {
    final User user = FirebaseAuth.instance.currentUser!;
    final String uid = user.uid;
    if (nameCont.text == "") {
      nameCont.text = pro.name;
    }
    return Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _nameField(pro),
            languageDropdown(slans, lang: pro.primaryLang),
            SizedBox(height: 16.0),
            _saveButton(uid, pro),
          ],
        ));
  }

  FloatingActionButton _saveButton(String uid, Profile pro) {
    return FloatingActionButton.extended(
      heroTag: "save_profile",
      label: Text('Save'),
      icon: Icon(Icons.save),
      backgroundColor: Theme.of(context).colorScheme.primary,
      onPressed: () async {
        String? err = await updateProfile(uid: uid, name: nameCont.text, primaryLang: pro.primaryLang);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err ?? "Profile saved!")),
          );
        });
      },
    );
  }

  TextField _nameField(Profile pro) {
    return TextField(
      controller: nameCont,
      decoration: InputDecoration(
        labelText: 'Name',
      ),
    );
  }
}
