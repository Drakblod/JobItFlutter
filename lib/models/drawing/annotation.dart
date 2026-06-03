import 'dart:math';
import 'package:flutter/material.dart';

abstract class Annotation {
  final Color color;
  final double strokeWidth;

  Annotation({
    required this.color,
    this.strokeWidth = 5.0,
  });

  void draw(Canvas canvas, Size size);
}

class LineAnnotation extends Annotation {
  final Offset start;
  final Offset end;
  final bool isArrow;

  LineAnnotation({
    required this.start,
    required this.end,
    this.isArrow = false,
    required super.color,
    super.strokeWidth,
  });

  @override
  void draw(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(start, end, paint);

    if (isArrow) {
      final double arrowSize = 20.0;
      final double angle = atan2(end.dy - start.dy, end.dx - start.dx);

      final Offset arrowPoint1 = Offset(
        end.dx - arrowSize * cos(angle - pi / 6),
        end.dy - arrowSize * sin(angle - pi / 6),
      );

      final Offset arrowPoint2 = Offset(
        end.dx - arrowSize * cos(angle + pi / 6),
        end.dy - arrowSize * sin(angle + pi / 6),
      );

      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
        ..lineTo(arrowPoint2.dx, arrowPoint2.dy)
        ..close();

      canvas.drawPath(path, fillPaint);
    }
  }
}

class CircleAnnotation extends Annotation {
  final Offset center;
  final double radius;

  CircleAnnotation({
    required this.center,
    required this.radius,
    required super.color,
    super.strokeWidth,
  });

  @override
  void draw(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, paint);
  }
}

class TextAnnotation extends Annotation {
  final Offset position;
  final String text;

  TextAnnotation({
    required this.position,
    required this.text,
    required super.color,
  });

  @override
  void draw(Canvas canvas, Size size) {
    if (text.isEmpty) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 22.0,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black.withOpacity(0.4),
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, position);
  }
}
