import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';

enum Role {
  usr,
  ast,
  sys,
}

class NullDataError implements Exception {
  final String message;
  NullDataError(this.message);
}

class Activity {
  String id;
  String title;
  String type;
  String name;
  String? language;
  List<Map<String, dynamic>>? goals;
  String? userPrompt;
  int? level;

  Activity(
      {required this.id,
      required this.title,
      required this.type,
      required this.name,
      this.language,
      this.userPrompt,
      this.goals,
      this.level});

  factory Activity.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) {
      throw NullDataError("Activity.fromDocumentSnapshot: data is null: ${snapshot.id}");
    }
    print('Activity.data: $data');
    // TODO parse goals, requires Goals class {title: string, criteria: list[{body: string, points: int > 0}]}
    List<Map<String, dynamic>> goals = [];
    String? name;
    if (data['type'] == 'lesson') {
      name = snapshot['config']['topic'];
    } else if (data['type'] == 'unstructured') {
      name = 'unstructured';
    } else {
      throw Exception("Activity.fromDocumentSnapshot: unknown activity type: ${snapshot.id}");
    }
    String? userPrompt = data.containsKey('user_prompt') ? snapshot['user_prompt'] : null;
    int? level = data.containsKey('level') ? snapshot['level'] : null;
    final Activity act = Activity(
        id: snapshot.id,
        language: snapshot['language'],
        title: snapshot['title'],
        type: snapshot['type'],
        name: name!,
        goals: goals,
        userPrompt: userPrompt,
        level: level);
    return act;
  }
}

class Transcript {
  String id;
  List<Message> messages;
  String language;
  Timestamp createdAt;
  String activityId;
  String? summary;

  Transcript(
      {required this.id,
      required this.messages,
      required this.language,
      required this.createdAt,
      required this.activityId,
      this.summary});

  factory Transcript.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) {
      throw NullDataError("Transcript.fromDocumentSnapshot: data is null: ${snapshot.id}");
    }
    List<Message> msgs = [];
    for (var msg in snapshot['messages'].reversed) {
      Message message = Message.fromMap(msg);
      msgs.add(message);
    }
    String? summary = data.containsKey('summary') ? snapshot['summary'] : null;
    return Transcript(
        id: snapshot.id,
        messages: msgs,
        language: snapshot['language'],
        createdAt: snapshot['created_at'],
        activityId: snapshot['activity_id'],
        summary: summary);
  }

  bool hasNonSysMessages() {
    for (var msg in messages) {
      if (msg.role != Role.sys) {
        return true;
      }
    }
    return false;
  }
}

class Audio {
  String bucket;
  String path;
  Audio(this.bucket, this.path);
  factory Audio.fromMap(Map<String, dynamic> map) {
    return Audio(map['bucket'], map['path']);
  }
}

class Message {
  Role role;
  String msg;
  Audio? audio;
  Timestamp? createdAt;
  String? translation;
  // Message(this.role, this.msg, this.audio, this.createdAt, this.translation);
  Message(this.role, this.msg, {this.audio, this.createdAt, this.translation});

  /// Raises:
  /// - an exception if the string is not a valid Role;
  /// - an exception if the string is not a valid Message;
  /// - an exception if the keys 'role' or 'content' are missing.
  factory Message.fromMap(Map<String, dynamic> map) {
    Role role = Role.values.firstWhere((e) => e.toString() == 'Role.${map["role"]}');
    String msg = map['body'];
    Audio audio = Audio.fromMap(map['audio']);
    Timestamp createdAt = map['created_at'];
    String? translation = (map['translation'] == '') ? null : map['translation'];
    return Message(role, msg, audio: audio, createdAt: createdAt, translation: translation);
  }
}

enum DCMsg { transcript, status, ping }

/// Profile represents the user's profile document from Firestore.
class Profile {
  String primaryLang;
  String lang;
  String name;
  String uid;
  int level;
  Profile({required this.uid, required this.lang, required this.name, this.primaryLang = 'en-US', this.level = 1});
}

class Config {
  List<String> supportedLangs;
  Config({required this.supportedLangs});
}

class FeedbackMsg {
  String uid;
  String body;
  String type;
  String tid;
  Timestamp timestamp = Timestamp.now();
  FeedbackMsg({required this.uid, required this.body, required this.type, required this.tid});
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'body': body,
      'type': type,
      'tid': tid,
      'timestamp': timestamp,
    };
  }
}
