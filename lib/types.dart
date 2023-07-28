import 'dart:core';

enum Role {
  usr,
  ast,
}

class Message {
  Role role;
  String msg;
  Message(this.role, this.msg);
}

enum DCMsg { transcript, status, ping }

/// Profile represents the user's profile document from Firestore.
class Profile {
  String primaryLang;
  String lang;
  String name;
  String uid;
  Profile({required this.uid, required this.lang, required this.name, this.primaryLang = 'en'});
}

class Config {
  List<String> supportedLangs;
  Config({required this.supportedLangs});
}
