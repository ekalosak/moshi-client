import 'package:flutter/material.dart';

class TrianglePainter extends CustomPainter {
  final bool pointRight;
  TrianglePainter({required this.pointRight});
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.fill;

    Path path = Path();
    if (pointRight) {
      path.moveTo(size.width, size.height / 2);
      path.lineTo(0, size.height);  // TODO arcTo for pretty chat lip
      path.lineTo(0, 0);
    } else {
      path.moveTo(0, size.height / 2);
      path.lineTo(size.width, size.height);  // TODO arcTo for pretty chat lip
      path.lineTo(size.width, 0);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class RectanglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.fill;

    Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
