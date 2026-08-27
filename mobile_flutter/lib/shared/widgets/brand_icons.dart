import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Official WhatsApp Brand Icon with speech bubble tail & rotated phone handset
class WhatsAppBrandIcon extends StatelessWidget {
  final double size;
  const WhatsAppBrandIcon({Key? key, this.size = 28}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _WhatsAppPainter(),
    );
  }
}

class _WhatsAppPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Green Background Paint (Official WhatsApp Green #25D366)
    final bgPaint = Paint()
      ..color = const Color(0xFF25D366)
      ..style = PaintingStyle.fill;

    // Speech bubble path (circle + bottom-left tail)
    final center = Offset(w * 0.5, h * 0.46);
    final radius = w * 0.44;

    final bubblePath = Path();
    bubblePath.addOval(Rect.fromCircle(center: center, radius: radius));

    // Tail on bottom-left
    final tailPath = Path();
    tailPath.moveTo(w * 0.20, h * 0.70);
    tailPath.lineTo(w * 0.05, h * 0.94);
    tailPath.lineTo(w * 0.36, h * 0.82);
    tailPath.close();

    bubblePath.addPath(tailPath, Offset.zero);
    canvas.drawPath(bubblePath, bgPaint);

    // White Handset Phone Icon
    final phonePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(w * 0.5, h * 0.44);
    canvas.rotate(-math.pi * 0.08);

    final phone = Path();
    phone.moveTo(-w * 0.16, -h * 0.22);
    phone.cubicTo(-w * 0.26, -h * 0.14, -w * 0.28, 0.0, -w * 0.16, h * 0.16);
    phone.cubicTo(-w * 0.04, h * 0.28, 0.10, h * 0.26, w * 0.18, h * 0.18);
    phone.cubicTo(w * 0.25, h * 0.11, w * 0.22, 0.02, w * 0.12, -h * 0.04);
    phone.cubicTo(w * 0.07, -h * 0.08, w * 0.02, -h * 0.06, -w * 0.02, -h * 0.01);
    phone.cubicTo(-w * 0.07, h * 0.06, -w * 0.12, h * 0.01, -w * 0.14, -h * 0.03);
    phone.cubicTo(-w * 0.17, -h * 0.07, -w * 0.13, -h * 0.12, -w * 0.08, -h * 0.16);
    phone.cubicTo(-w * 0.03, -h * 0.21, -w * 0.09, -h * 0.26, -w * 0.16, -h * 0.22);
    phone.close();

    canvas.drawPath(phone, phonePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Official Telegram Brand Icon with paper plane & wing fold shading
class TelegramBrandIcon extends StatelessWidget {
  final double size;
  const TelegramBrandIcon({Key? key, this.size = 28}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _TelegramPainter(),
    );
  }
}

class _TelegramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Telegram Sky Blue Gradient (#2AABEE to #229ED9)
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF2AABEE), Color(0xFF229ED9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    // Outer Circle
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.5, bgPaint);

    // Paper Airplane Body (White)
    final planePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final planePath = Path();
    // Tip at top right
    planePath.moveTo(w * 0.78, h * 0.24);
    // Tail bottom left
    planePath.lineTo(w * 0.20, h * 0.48);
    // Bottom fold point
    planePath.lineTo(w * 0.40, h * 0.76);
    // Right wing corner
    planePath.lineTo(w * 0.48, h * 0.60);
    // Upper body crease
    planePath.lineTo(w * 0.78, h * 0.24);
    planePath.close();

    canvas.drawPath(planePath, planePaint);

    // Paper Airplane Shadow Fold (Soft shaded wing crease)
    final shadowPaint = Paint()
      ..color = const Color(0xFFB0D6EC)
      ..style = PaintingStyle.fill;

    final shadowPath = Path();
    shadowPath.moveTo(w * 0.40, h * 0.76);
    shadowPath.lineTo(w * 0.48, h * 0.60);
    shadowPath.lineTo(w * 0.40, h * 0.64);
    shadowPath.close();

    canvas.drawPath(shadowPath, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
