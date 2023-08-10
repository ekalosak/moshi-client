import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:moshi/storage.dart';
import 'package:moshi/types.dart';
import 'package:moshi/screens/home.dart';

/// Ensure the user is authorized to view the page.
Widget authorized(BuildContext context, Widget widg) {
  User? user_ = FirebaseAuth.instance.currentUser;
  if (user_ == null) {
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => HomeScreen()), (route) => false);
  }
  return widg;
}

Widget withProfile(Function makeWidget) {
  return StreamBuilder<DocumentSnapshot>(
    stream: profileStream(FirebaseAuth.instance.currentUser!),
    builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> pSnap) {
      Profile? profile;
      if (pSnap.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      } else if (pSnap.hasError) {
        print("withProfile: ERROR: profile snapshot: ${pSnap.error.toString()}");
        _snapshotError(context);
        return Container();
      } else {
        if (!pSnap.data!.exists) {
          print("profile doesn't exist");
        } else {
          profile = Profile(
            uid: pSnap.data!.id,
            lang: pSnap.data!['lang'],
            name: pSnap.data!['name'],
            primaryLang: pSnap.data!['primary_lang'],
          );
        }
        return makeWidget(context, profile);
      }
    },
  );
}

Widget withConfig(Function makeWidget) {
  return StreamBuilder<DocumentSnapshot>(
    stream: supportedLangsStream(),
    builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> slSnap) {
      if (slSnap.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      } else if (slSnap.hasError) {
        print("withConfig: ERROR: supported_langs snapshot: ${slSnap.error.toString()}");
        _snapshotError(context);
        return Container();
      } else {
        List<String> supportedLangs = slSnap.data!['langs'].cast<String>();
        return makeWidget(context, supportedLangs);
      }
    },
  );
}

void _snapshotError(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Couldn't connect to Moshi servers. Please check your internet connection.")),
    );
  });
}
