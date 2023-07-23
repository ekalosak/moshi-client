/// Chat box with messages, looks like an SMS messenger app.
import 'package:flutter/material.dart';
import 'package:moshi_client/types.dart';

import 'painters.dart';

const int boxIconRatio = 14;
const double lipOffset = 16;
const double lipHeight = 20;
const double boxOffset = 12;
const double boxCornerRad = 12;

class MsgBox extends StatelessWidget {
  final Message msg;
  final Color boxColor;
  final Color iconColor;
  MsgBox(this.msg, this.boxColor, this.iconColor);

  Widget _ico(Role role) {
    Icon icon = (role == Role.ast) ? Icon(Icons.bubble_chart, color: iconColor) : Icon(Icons.person, color: iconColor);
    return Expanded(
        flex: 2,
        child: Stack(children: [
          Align(
              alignment: (msg.role != Role.ast) ? Alignment(-1, -0.2) : Alignment(1, -0.2),
              child: CustomPaint(
                size: Size(lipOffset, lipHeight),
                painter: (msg.role == Role.ast)
                    ? TrianglePainter(pointRight: false, color: boxColor)
                    : TrianglePainter(pointRight: true, color: boxColor),
              )),
          Align(
            alignment: (msg.role == Role.ast) ? Alignment(-1, -0.2) : Alignment(1, -0.2),
            child: icon,
          )
        ]));
    // return icon;
    // return Expanded(
    //   flex: 1,
    //   child: icon,
    // );
  }

  Widget _msg(Message msg) {
    // return Text(msg.msg);
    return Flexible(
      flex: boxIconRatio,
      child: Stack(children: [
        Align(
          alignment: (msg.role != Role.ast) ? Alignment.centerLeft : Alignment.centerRight,
          child: LayoutBuilder(builder: (context, constraints) {
            return Padding(
              padding: (msg.role == Role.ast) ? EdgeInsets.only(right: boxOffset) : EdgeInsets.only(left: boxOffset),
              child: Center(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(boxCornerRad),
                      child: Container(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight - boxOffset,
                        color: boxColor,
                      ),
                    ),
                    Align(
                      alignment: (msg.role == Role.ast) ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(margin: const EdgeInsets.all(16.0), child: Text(msg.msg)),
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
    final Widget icon = _ico(msg.role);
    final Widget message = _msg(msg);
    final Widget row = Row(
      children: [
        (msg.role == Role.ast) ? icon : message,
        (msg.role == Role.ast) ? message : icon,
      ],
    );
    // Make the row height tall enough so the text doesn't overflow.
    return Container(
      height: 128,
      child: row,
    );
    // return row;
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
    final Color iconColor = Theme.of(context).colorScheme.onSurface;
    return Column(
      children: <Widget>[
        Expanded(
            child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(8),
                itemCount: widget.messages.length,
                itemBuilder: (BuildContext context, int index) {
                  return SizedBox(
                    child: MsgBox(widget.messages[index], boxColor, iconColor),
                  );
                })),
      ],
    );
  }
}
