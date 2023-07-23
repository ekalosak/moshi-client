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

  // Build the icon and textbox lip (triangle) for the message box.
  Widget _ico(Role role) {
    Icon icon = (role == Role.ast) ? Icon(Icons.bubble_chart, color: iconColor) : Icon(Icons.person, color: iconColor);
    return Flexible(
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
            alignment: (msg.role == Role.ast) ? Alignment(-0.2, -0.2) : Alignment(0.2, -0.2),
            child: icon,
          )
        ]));
  }

  // Build the text box, including the text and underneath the filled rounded rectangle, for the message.
  Widget _msg(Message msg, double height) {
    return Flexible(
      flex: boxIconRatio,
      child: Align(
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
                      height: height,
                      color: boxColor,
                    ),
                  ),
                  Align(
                    alignment: (msg.role == Role.ast) ? Alignment.topLeft : Alignment.topRight,
                    child: Container(margin: const EdgeInsets.all(8.0), child: Text(msg.msg)),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  double _calculateTextHeight(String text) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: double.infinity);
    return textPainter.height;
  }

  @override
  Widget build(BuildContext context) {
    final double height = _calculateTextHeight(msg.msg);
    print("height: $height");
    final Widget icon = _ico(msg.role);
    final Widget msgBox = _msg(msg, height);
    final Widget row = Row(
      children: [
        (msg.role == Role.ast) ? icon : msgBox,
        (msg.role == Role.ast) ? msgBox : icon,
      ],
    );
    return SizedBox(
      height: height,
      child: row,
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
    final Color iconColor = Theme.of(context).colorScheme.onSurface;
    return ListView.builder(
      reverse: true,
      shrinkWrap: true,
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      itemCount: widget.messages.length,
      itemBuilder: (BuildContext context, int index) {
        return MsgBox(widget.messages[index], boxColor, iconColor);
      },
    );
  }
}
