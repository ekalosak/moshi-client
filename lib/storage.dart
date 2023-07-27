import 'package:cloud_firestore/cloud_firestore.dart';

/// Profile represents the user's profile document from Firestore.
class Profile {
  String lang;
  String name;
  Profile({required this.lang, required this.name});
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
    return Profile(lang: data['lang'], name: data['name']);
  }
}

/// Update the user's profile document in Firestore.
Future<String?> updateProfile(String uid, Profile profile) async {
  String? err;
  DocumentReference<Map<String, dynamic>> documentReference =
      FirebaseFirestore.instance.collection('profiles').doc(uid);
  try {
    await documentReference.set({
      'lang': profile.lang,
      'name': profile.name,
    });
  } catch (e) {
    print("Unknown error");
    print(e);
    err = 'An error occurred. Please try again later.';
  }
  return err;
}
