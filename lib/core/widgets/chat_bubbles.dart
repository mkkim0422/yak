import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';

/// Bot message bubble (white, left, optional brand mark).
class BotBubble extends StatelessWidget {
  final String text;
  final bool withMark;
  final EdgeInsetsGeometry margin;

  const BotBubble({
    super.key,
    required this.text,
    this.withMark = false,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.max,
        children: [
          if (withMark) ...[
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const _AlyakMark(size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  boxShadow: AppShadows.card,
                ),
                child: Text(
                  text,
                  style: AppTypography.body1.copyWith(fontSize: 15, height: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 0),
        ],
      ),
    );
  }
}

/// User reply bubble (blue, right).
class UserBubble extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry margin;

  const UserBubble({
    super.key,
    required this.text,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: AppTypography.family,
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlyakMark extends StatelessWidget {
  final double size;
  const _AlyakMark({this.size = 18});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AlyakMarkPainter()),
    );
  }
}

class _AlyakMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pillRect = Rect.fromLTWH(
      size.width * 0.07,
      size.height * 0.21,
      size.width * 0.85,
      size.height * 0.58,
    );
    final pill = RRect.fromRectAndRadius(
        pillRect, Radius.circular(size.height * 0.5));
    canvas.drawRRect(pill, Paint()..color = AppColors.primary);

    final leftRect = Rect.fromLTWH(
      size.width * 0.07,
      size.height * 0.21,
      size.width * 0.42,
      size.height * 0.58,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(leftRect, Radius.circular(size.height * 0.5)),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );

    canvas.drawCircle(
      Offset(size.width * 0.32, size.height * 0.5),
      size.height * 0.06,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Public mark — used outside chat too.
class AlyakBrandMark extends StatelessWidget {
  final double size;
  const AlyakBrandMark({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) => _AlyakMark(size: size);
}
