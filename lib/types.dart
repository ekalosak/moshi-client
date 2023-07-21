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

enum DCMsg {
  transcript,
  status,
  ping
}