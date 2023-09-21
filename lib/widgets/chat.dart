/// Chat box with messages, looks like an SMS messenger app.
import 'dart:math';
import 'package:flutter/material.dart';
import 'painters.dart';

import 'package:moshi/types.dart';

const int boxIconRatio = 14;
const double lipOffset = 16;
const double lipHeight = 12;
const double boxOffset = 12;
const double boxCornerRad = 6;
const double boxTextPadding = 10;
const double betweenBoxPadding = 4;

String _closeIcon() {
  /// random food emoji
  int rand = Random().nextInt(5);
  switch (rand) {
    case 0:
      return '🍕';
    case 1:
      return '🥗';
    case 2:
      return '🍱';
    case 3:
      return '🍙';
    case 4:
      return '🍰';
    default:
      return '🦴';
  }
}

class Chat extends StatefulWidget {
  final List<Message> messages;
  final Future<void> Function(Audio)? onLongPress;
  Chat({required this.messages, this.onLongPress});
  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  @override
  Widget build(BuildContext context) {
    final Color boxColor = Theme.of(context).colorScheme.surface;
    final Color iconColor = Theme.of(context).colorScheme.secondary;
    try {
      widget.messages.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    } catch (e) {
      print("chat widget caught exception sorting messages");
      print(e);
    }
    return ListView.builder(
      reverse: true,
      shrinkWrap: true,
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      itemCount: widget.messages.length,
      itemBuilder: (BuildContext context, int index) {
        return MsgBox(widget.messages[index], boxColor, iconColor, onLongPress: widget.onLongPress);
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

/// Draws a message box with a triangle lip on one side.
/// On press, show a popup with the translation.
class MsgBox extends StatelessWidget {
  final Message msg;
  final Color boxColor;
  final Color iconColor;
  final Future<void> Function(Audio)? onLongPress;
  MsgBox(this.msg, this.boxColor, this.iconColor, {this.onLongPress});

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

  /// Build the text box, including the text and underneath the filled rounded rectangle, for the message.
  /// On tap, show the translation.
  Widget _msg(Message msg, BuildContext context) {
    final Text msgText = Text(
      msg.msg,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
        fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
      ),
    );
    return Flexible(
      flex: boxIconRatio,
      child: Padding(
          padding: EdgeInsets.only(top: betweenBoxPadding),
          child: Align(
            alignment: (msg.role == Role.ast) ? Alignment.centerLeft : Alignment.centerRight,
            child: Padding(
              padding: (msg.role == Role.ast) ? EdgeInsets.only(right: boxOffset) : EdgeInsets.only(left: boxOffset),
              child: GestureDetector(
                onTap: () {
                  if (msg.translation != null) {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            scrollable: true,
                            title: Text("Translation",
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                    )),
                            content: Text(msg.translation!,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    )),
                            actions: [
                              TextButton(
                                child: Text(_closeIcon()),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('⏳ No translation available yet.'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                onLongPress: () async {
                  print("onLongPress: $onLongPress");
                  msg.audio != null ? await onLongPress?.call(msg.audio!) : print("No audio");
                },
                child: RoundedBox(boxColor: boxColor, padding: boxTextPadding, child: msgText),
              ),
            ),
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget icon = _ico(msg.role);
    final Widget msgBox = _msg(msg, context);
    final Widget row = Row(
      children: [
        (msg.role == Role.ast) ? icon : msgBox,
        (msg.role == Role.ast) ? msgBox : icon,
      ],
    );
    return row;
  }
}
