import 'package:flutter/material.dart';

enum Role {
  usr,
  ast,
}

class Message {
  Role role;
  String msg;
  Message(this.role, this.msg);
}

class MsgBox extends StatelessWidget {
  final Message msg;
  MsgBox(this.msg);

  @override
  Widget build(BuildContext context) {
    return Text('${msg.role}: ${msg.msg}');
  }
}

class Chat extends StatefulWidget {
  final List<Message> messages;
  Chat({required this.messages});
  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {

  @override
  Widget build(BuildContext context) {
    return Column(
      // mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: widget.messages.length,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                height: 64,
                color: Colors.green,
                child: Center(
                  child: MsgBox(widget.messages[index]),
                )
              );
            }
          )
        ),
      ],
    );
  }
}
