import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Draws a minimal pill-with-heart logo. Used for splash and as a
/// runtime fallback before real PNG assets are wired.
class AppIconPainter extends CustomPainter {
  const AppIconPainter({this.pillColor = AppColors.primary, this.heartColor});

  final Color pillColor;
  final Color? heartColor;

  @override
  void paint(Canvas canvas, Size size) {
    final shorter = size.shortestSide;
    final pillWidth = shorter * 0.75;
    final pillHeight = shorter * 0.42;
    final center = Offset(size.width / 2, size.height / 2);
    final pillRect = Rect.fromCenter(
      center: center,
      width: pillWidth,
      height: pillHeight,
    );

    final pillPaint = Paint()..color = pillColor;
    final pillRRect = RRect.fromRectAndRadius(
      pillRect,
      Radius.circular(pillHeight / 2),
    );
    canvas.drawRRect(pillRRect, pillPaint);

    final dividerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.4;
    canvas.drawLine(
      Offset(center.dx - pillWidth * 0.25, center.dy - pillHeight * 0.4),
      Offset(center.dx - pillWidth * 0.25, center.dy + pillHeight * 0.4),
      dividerPaint,
    );

    final heartCenter = Offset(center.dx + pillWidth * 0.12, center.dy);
    _drawHeart(
      canvas,
      heartCenter,
      shorter * 0.18,
      heartColor ?? Colors.white,
    );
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Color color) {
    final path = Path();
    final w = size;
    final h = size * 0.9;
    final left = center.dx - w / 2;
    final top = center.dy - h / 2;

    path.moveTo(center.dx, top + h);
    path.cubicTo(
      left - w * 0.1,
      top + h * 0.55,
      left + w * 0.1,
      top - h * 0.15,
      center.dx,
      top + h * 0.3,
    );
    path.cubicTo(
      left + w * 0.9,
      top - h * 0.15,
      left + w * 1.1,
      top + h * 0.55,
      center.dx,
      top + h,
    );
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant AppIconPainter oldDelegate) {
    return oldDelegate.pillColor != pillColor ||
        oldDelegate.heartColor != heartColor;
  }
}

/// Convenience widget that paints [AppIconPainter] at any size.
class AppIcon extends StatelessWidget {
  const AppIcon({super.key, this.size = 96, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: AppIconPainter(pillColor: color ?? AppColors.primary),
      ),
    );
  }
}
