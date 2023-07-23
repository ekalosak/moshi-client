/// Chat box with messages, looks like an SMS messenger app.
import 'package:flutter/material.dart';
import 'package:moshi_client/types.dart';

import 'painters.dart';

const int boxIconRatio = 14;
const double lipOffset = 16;
const double lipHeight = 12;
const double boxOffset = 12;
const double boxCornerRad = 6;
const double boxTextPadding = 10;
const double betweenBoxPadding = 4;

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
  Widget _msg(Message msg, Color textColor) {
    final Text msgText = Text(
      msg.msg,
      style: TextStyle(color: textColor),
    );
    return Flexible(
      flex: boxIconRatio,
      child: Padding(
          padding: EdgeInsets.only(top: betweenBoxPadding),
          child: Align(
            alignment: (msg.role == Role.ast) ? Alignment.centerLeft : Alignment.centerRight,
            child: Padding(
              padding: (msg.role == Role.ast) ? EdgeInsets.only(right: boxOffset) : EdgeInsets.only(left: boxOffset),
              child: RoundedBox(boxColor: boxColor, padding: boxTextPadding, child: msgText),
            ),
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget icon = _ico(msg.role);
    final Widget msgBox = _msg(msg, Theme.of(context).colorScheme.onSurface);
    final Widget row = Row(
      children: [
        (msg.role == Role.ast) ? icon : msgBox,
        (msg.role == Role.ast) ? msgBox : icon,
      ],
    );
    return row;
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
    final Color iconColor = Theme.of(context).colorScheme.primary;
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

/// Draws a rouded box under a widget
class RoundedBox extends StatelessWidget {
  final Widget child;
  final double padding;
  final double cornerRadius;
  final Color boxColor;

  RoundedBox({
    required this.child,
    required this.boxColor,
    this.padding = 8.0,
    this.cornerRadius = boxCornerRad,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RoundedBoxPainter(
        padding: padding,
        cornerRadius: cornerRadius,
        boxColor: boxColor,
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: child,
      ),
    );
  }
}

class _RoundedBoxPainter extends CustomPainter {
  final double padding;
  final double cornerRadius;
  final Color boxColor;

  _RoundedBoxPainter({
    required this.padding,
    required this.cornerRadius,
    required this.boxColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = boxColor;
    final rect = Rect.fromLTRB(
      0,
      0,
      size.width,
      size.height,
    );
    final rRect = RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius));
    canvas.drawRRect(rRect, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
