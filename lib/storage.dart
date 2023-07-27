import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Profile represents the user's profile document from Firestore.
class Profile {
  String primaryLang;
  String lang;
  String name;
  String uid;
  Profile({required this.uid, required this.lang, required this.name, this.primaryLang = 'en'});
}

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

/// Update the user's profile document in Firestore.
// Require string uid; optional string lang, name, primaryLang.
Future<String?> updateProfile({required String uid, String? lang, String? name, String? primaryLang}) async {
  String? err;
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
