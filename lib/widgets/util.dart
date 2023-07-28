import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import 'package:moshi_client/storage.dart';
import 'package:moshi_client/types.dart';

/// Ensure the user is authorized to view the page.
Widget authorized(BuildContext context, Widget widg) {
  User? user_ = FirebaseAuth.instance.currentUser;
  if (user_ == null) {
    context.go('/a');
  }
  return widg;
}

/// This wrapper function returns a widget that has access to the user's profile and the supported languages.
/// While loading, it returns a CircularProgressIndicator.
/// If loading fails, it shows a SnackBar.
/// If loading succeeds, it returns the widget returned by makeWidget.
/// Function makeWidget has signature: Widget Function(BuildContext context, Profile profile, List<String> supportedLangs)
Widget withProfileAndConfig(Function makeWidget) {
  return StreamBuilder<DocumentSnapshot>(
      stream: supportedLangsStream(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> slSnap) {
        return StreamBuilder<DocumentSnapshot>(
          stream: profileStream(FirebaseAuth.instance.currentUser!),
          builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> pSnap) {
            if (pSnap.connectionState == ConnectionState.waiting || slSnap.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (pSnap.hasError) {
              print("withProfileAndConfig: ERROR: profile snapshot: ${pSnap.error.toString()}");
            } else if (slSnap.hasError) {
              print("withProfileAndConfig: ERROR: supported_langs snapshot: ${slSnap.error.toString()}");
            } else {
              List<String> supportedLangs = slSnap.data!['langs'].cast<String>();
              Profile profile = Profile(
                uid: pSnap.data!.id,
                lang: pSnap.data!['lang'],
                name: pSnap.data!['name'],
                primaryLang: pSnap.data!['primary_lang'],
              );
              return makeWidget(context, profile, supportedLangs);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Couldn't connect to Moshi servers. Please check your internet connection.")),
            );
            return Container();
          },
        );
      });
}

Widget withConfig(Function makeWidget) {
  return StreamBuilder<DocumentSnapshot>(
    stream: supportedLangsStream(),
    builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> slSnap) {
      if (slSnap.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      } else if (slSnap.hasError) {
        print("withConfig: ERROR: supported_langs snapshot: ${slSnap.error.toString()}");
        // add callback to show snackbar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Couldn't connect to Moshi servers. Please check your internet connection.")),
          );
        });
        return Container();
      } else {
        List<String> supportedLangs = slSnap.data!['langs'].cast<String>();
        return makeWidget(context, supportedLangs);
      }
    },
  );
}
