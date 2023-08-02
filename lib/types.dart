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

  factory Message.fromMap(Map<String, dynamic> map) {
    print("Message.fromMap: $map");
    // get the role from the String map['role']
    Role role = Role.values.firstWhere((e) => e.toString() == 'Role.${map["role"]}');
    // check that content is in the map keys; if it isn't, print the map
    String msg = map['content'];
    print("role: $role");
    print("msg: $msg");
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
