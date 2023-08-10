import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:moshi/types.dart';

Stream<DocumentSnapshot> profileStream(User user) {
  return FirebaseFirestore.instance.collection('profiles').doc(user.uid).snapshots(includeMetadataChanges: true);
}

Stream<DocumentSnapshot> supportedLangsStream() {
  return FirebaseFirestore.instance.collection('config').doc('supported_langs').snapshots();
}

/// Get the supported languages from Firestore.
Future<List<String>> getSupportedLangs() async {
  DocumentReference<Map<String, dynamic>> documentReference =
      FirebaseFirestore.instance.collection('config').doc('supported_langs');
  DocumentSnapshot<Map<String, dynamic>> documentSnapshot = await documentReference.get();
  Map<String, dynamic> data = documentSnapshot.data()!;
  return data['langs'].cast<String>();
}

/// Get the user's profile document from Firestore.
Future<Profile?> getProfile(String uid) async {
  DocumentReference<Map<String, dynamic>> documentReference =
      FirebaseFirestore.instance.collection('profiles').doc(uid);
  DocumentSnapshot<Map<String, dynamic>> documentSnapshot = await documentReference.get();
  if (!documentSnapshot.exists) {
    return null;
  } else {
    Map<String, dynamic> data = documentSnapshot.data()!;
    return Profile(uid: uid, lang: data['lang'], name: data['name'], primaryLang: data['primary_lang']);
  }
}
