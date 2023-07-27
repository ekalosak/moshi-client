import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:moshi_client/storage.dart';
import 'package:moshi_client/util.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController nameCont = TextEditingController();
  Profile? profile;
  List<String>? supportedLangs;
  bool showSave = false;

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
    print("screens/profile: build");
    final User user = FirebaseAuth.instance.currentUser!;
    print("screens/profile: build: user: $user");
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: _futureProfileForm(user.uid),
    );
  }

  Widget _futureProfileForm(String uid) {
    return FutureBuilder(
        future: Future.wait([getProfile(uid), getSupportedLangs()]),
        builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
          print("_profileForm: snapshot: $snapshot");
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            print("profile: _profileForm: snapshot.hasError: ${snapshot.error.toString()}");
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("I had trouble finding your file, sorry about that.")),
              );
            });
            return Container();
          } else {
            print("profile: _profileForm: snapshot.data: ${snapshot.data}");
            profile = snapshot.data![0];
            supportedLangs = snapshot.data![1];
            return _profileForm(uid);
          }
        });
  }

  Widget _profileForm(String uid) {
    Profile pro = profile!;
    List<String> slans = supportedLangs!;
    print("_profileForm: uid: $uid");
    print("_profileForm: slans: $slans");
    print("_profileForm: profile: ${pro.name}, ${pro.lang}");
    if (nameCont.text == "") {
      nameCont.text = pro.name;
    }
    if (!slans.contains(pro.lang)) {
      print("ERROR: original profile language not in supported langs");
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
              },
            ),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Native language',
              ),
              value: pro.primaryLang,
              items: slans.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text("${getLangEmoji(value)} ${value.toUpperCase()}"),
                );
              }).toList(),
              onChanged: (String? newValue) {
                print("lang changed: $newValue");
                pro.primaryLang = newValue!;
              },
            ),
            SizedBox(height: 16.0),
            FloatingActionButton.extended(
              heroTag: "save_profile",
              label: Text('Save'),
              icon: Icon(Icons.save),
              backgroundColor: Theme.of(context).colorScheme.primary,
              onPressed: () async {
                Profile currentProfile =
                    Profile(uid: uid, name: nameCont.text, lang: pro.lang, primaryLang: pro.primaryLang);
                String? err = await updateProfile(uid: uid, name: nameCont.text, primaryLang: pro.primaryLang);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err ?? "Profile saved!")),
                  );
                });
                if (err == null) {
                  setState(() {
                    profile = currentProfile;
                  });
                }
              },
            ),
          ],
        ));
  }
}
