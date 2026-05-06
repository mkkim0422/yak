import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Pill-shaped status badge: ✅ 충분 / ⚠️ 부족 / 🟠 많이 부족.
class StatusPill extends StatelessWidget {
  final HealthStatus status;
  final String? overrideLabel;

  const StatusPill({
    super.key,
    required this.status,
    this.overrideLabel,
  });

  @override
  Widget build(BuildContext context) {
    final label = overrideLabel ??
        '${status.emoji} ${status.shortLabel}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: status.border.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: status.ink,
        ),
      ),
    );
  }
}

/// Dot-only status indicator.
class StatusDot extends StatelessWidget {
  final HealthStatus status;
  final double size;
  const StatusDot({super.key, required this.status, this.size = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: status.border,
        shape: BoxShape.circle,
      ),
    );
  }
}
