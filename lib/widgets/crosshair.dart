import 'package:flutter/material.dart';

class CrossHairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.clipRect(rect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black
      ..strokeWidth = 1;

    Offset p1 = Offset(rect.width / 2, 0);
    Offset p2 = Offset(rect.width / 2, rect.height);
    canvas.drawLine(p1, p2, paint);
    p1 = Offset(0, rect.height / 2);
    p2 = Offset(rect.width, rect.height / 2);
    canvas.drawLine(p1, p2, paint);
  }

  @override
  bool shouldRepaint(CrossHairPainter other) => false;
}
