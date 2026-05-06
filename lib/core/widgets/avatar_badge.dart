import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Emoji-on-rounded-square avatar with optional health-status border.
class AvatarBadge extends StatelessWidget {
  final String emoji;
  final HealthStatus? status;
  final double size;

  const AvatarBadge({
    super.key,
    required this.emoji,
    this.status,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final hasStatus = status != null;
    final bg = hasStatus ? status!.bg : AppColors.surfaceMuted;
    final border = hasStatus ? status!.border : AppColors.hairline;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: border, width: 2),
      ),
      child: Text(
        emoji,
        style: TextStyle(fontSize: size * 0.5, height: 1),
      ),
    );
  }
}
