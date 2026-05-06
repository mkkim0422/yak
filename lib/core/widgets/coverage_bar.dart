import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Horizontal % bar coloured by status. Mirrors `CoverageBar` JSX.
class CoverageBar extends StatelessWidget {
  final double percent; // 0..100+
  final HealthStatus status;
  final double height;

  const CoverageBar({
    super.key,
    required this.percent,
    required this.status,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final pct = percent.clamp(0, 100) / 100;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: height,
        color: AppColors.surfaceMuted,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: pct.toDouble(),
            child: Container(color: status.border),
          ),
        ),
      ),
    );
  }
}
