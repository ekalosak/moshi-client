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

  Widget _ico(Role role) {
    return Expanded(
      flex: 1,
      child: (role == Role.ast)
        ? Icon(Icons.bubble_chart)
        : Icon(Icons.person),
    );
  }

  // TODO paint rect and tri for msg, put in container stack
  Widget _msg(Message msg) {
    return Expanded(
      flex: 4,
      child: Align(
        alignment: (msg.role == Role.ast)
          ? Alignment.centerLeft
          : Alignment.centerRight,
        child: Text(msg.msg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          (msg.role == Role.ast)
            ? _ico(msg.role)
            : _msg(msg),
          (msg.role == Role.ast)
            ? _msg(msg)
            : _ico(msg.role),
        ],
      ),
    );
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
            reverse: true,
            padding: const EdgeInsets.all(8),
            itemCount: widget.messages.length,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                height: 64,
                color: Colors.green[100],
                child: MsgBox(
                  widget.messages[
                    widget.messages.length - index - 1
                  ]
                ),
              );
            }
          )
        ),
      ],
    );
  }
}
