import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Stadium-shaped tag/filter chip.
class AlyakChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final Color? activeColor;

  const AlyakChip({
    super.key,
    required this.label,
    this.active = false,
    this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = active ? (activeColor ?? AppColors.primary) : AppColors.surfaceMuted;
    final fg = active ? Colors.white : AppColors.ink2;
    return Material(
      color: bg,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.family,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
