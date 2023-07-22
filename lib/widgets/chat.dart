/// Chat box with messages, looks like an SMS messenger app.
import 'package:flutter/material.dart';
import 'package:moshi_client/types.dart';

import 'painters.dart';

const int boxIconRatio = 14;
const double lipOffset = 25;
const double lipHeight = 20;
const double boxOffset = 12;
const double boxCornerRad = 12;

class MsgBox extends StatelessWidget {
  final Message msg;
  final Color boxColor;
  MsgBox(this.msg, this.boxColor);

  Widget _ico(Role role) {
    return Expanded(
      flex: 1,
      child: (role == Role.ast) ? Icon(Icons.bubble_chart) : Icon(Icons.person),
    );
  }

  Widget _msg(Message msg) {
    return Expanded(
      flex: boxIconRatio,
      child: Stack(children: [
        Align(
            alignment: (msg.role == Role.ast)
                ? Alignment(-1, -0.2)
                : Alignment(1, -0.2),
            child: CustomPaint(
              size: Size(lipOffset, lipHeight),
              painter: (msg.role == Role.ast)
                  ? TrianglePainter(pointRight: false, color: boxColor)
                  : TrianglePainter(pointRight: true, color: boxColor),
            )),
        Align(
          alignment: (msg.role != Role.ast)
              ? Alignment.centerLeft
              : Alignment.centerRight,
          child: LayoutBuilder(builder: (context, constraints) {
            return Padding(
              padding: (msg.role == Role.ast)
                  ? EdgeInsets.only(left: lipOffset, right: boxOffset)
                  : EdgeInsets.only(right: lipOffset, left: boxOffset),
              child: Center(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(boxCornerRad),
                      child: Container(
                        width: constraints.maxWidth - lipOffset,
                        height: constraints.maxHeight - boxOffset,
                        color: boxColor,
                      ),
                    ),
                    Align(
                      alignment: (msg.role == Role.ast)
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Container(
                          margin: const EdgeInsets.all(16.0),
                          child: Text(msg.msg)),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          (msg.role == Role.ast) ? _ico(msg.role) : _msg(msg),
          (msg.role == Role.ast) ? _msg(msg) : _ico(msg.role),
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
    final Color boxColor = Theme.of(context).colorScheme.surface;
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
                    child: MsgBox(widget.messages[index], boxColor),
                  );
                })),
      ],
    );
  }
}
