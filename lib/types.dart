import 'dart:core';

enum Role {
  usr,
  ast,
  sys,
}

class Message {
  Role role;
  String msg;
  Message(this.role, this.msg);

  /// Raises:
  /// - an exception if the string is not a valid Role;
  /// - an exception if the string is not a valid Message;
  /// - an exception if the keys 'role' or 'content' are missing.
  factory Message.fromMap(Map<String, dynamic> map) {
    Role role = Role.values.firstWhere((e) => e.toString() == 'Role.${map["role"]}');
    String msg = map['content'];
    return Message(role, msg);
  }
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
