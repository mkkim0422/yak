import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Diagonal-stripe placeholder for product images. Mirrors `ProductPhoto`.
class ProductPhoto extends StatelessWidget {
  final double size;
  final String label;
  final bool verified;

  const ProductPhoto({
    super.key,
    this.size = 56,
    this.label = '제품',
    this.verified = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _StripePainter(),
            child: SizedBox(width: size, height: size),
          ),
          Positioned.fill(
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: AppTypography.micro.copyWith(
                    fontSize: 9,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ),
          ),
          if (verified)
            const Positioned(
              top: 4,
              right: 4,
              child: _VerifiedTick(),
            ),
        ],
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = AppColors.surfaceMuted;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), base);

    final stripe = Paint()..color = const Color(0xFFEAEDF1);
    const step = 16.0;
    for (double i = -size.height; i < size.width + size.height; i += step) {
      final path = Path()
        ..moveTo(i, 0)
        ..lineTo(i + 8, 0)
        ..lineTo(i + 8 + size.height, size.height)
        ..lineTo(i + size.height, size.height)
        ..close();
      canvas.drawPath(path, stripe);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VerifiedTick extends StatelessWidget {
  const _VerifiedTick();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: const Text(
        '✓',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}
