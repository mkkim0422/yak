import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

enum AlyakButtonSize { sm, md, lg }

class _Sizing {
  final double height;
  final double fontSize;
  final EdgeInsets padding;
  final double radius;
  const _Sizing(this.height, this.fontSize, this.padding, this.radius);

  static _Sizing of(AlyakButtonSize s) => switch (s) {
        AlyakButtonSize.sm => const _Sizing(
            40,
            14,
            EdgeInsets.symmetric(horizontal: 14),
            AppRadius.r10,
          ),
        AlyakButtonSize.md => const _Sizing(
            48,
            15,
            EdgeInsets.symmetric(horizontal: 16),
            AppRadius.r12,
          ),
        AlyakButtonSize.lg => const _Sizing(
            56,
            16,
            EdgeInsets.symmetric(horizontal: 20),
            AppRadius.r14,
          ),
      };
}

/// Filled primary blue button.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool full;
  final bool disabled;
  final AlyakButtonSize size;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.full = false,
    this.disabled = false,
    this.size = AlyakButtonSize.lg,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final s = _Sizing.of(size);
    final btn = SizedBox(
      width: full ? double.infinity : null,
      height: s.height,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor:
              disabled ? AppColors.ghost : AppColors.primary,
          foregroundColor: Colors.white,
          padding: s.padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(s.radius),
          ),
          textStyle: TextStyle(
            fontFamily: AppTypography.family,
            fontSize: s.fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.15,
          ),
        ),
        onPressed: disabled ? null : onPressed,
        child: icon == null
            ? Text(label)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 6),
                  Text(label),
                ],
              ),
      ),
    );
    return btn;
  }
}

/// Muted-grey secondary button.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool full;
  final AlyakButtonSize size;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.full = false,
    this.size = AlyakButtonSize.lg,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final s = _Sizing.of(size);
    return SizedBox(
      width: full ? double.infinity : null,
      height: s.height,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.surfaceMuted,
          foregroundColor: AppColors.ink,
          padding: s.padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(s.radius),
          ),
          textStyle: TextStyle(
            fontFamily: AppTypography.family,
            fontSize: s.fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.15,
          ),
        ),
        onPressed: onPressed,
        child: icon == null
            ? Text(label)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 6),
                  Text(label),
                ],
              ),
      ),
    );
  }
}

/// Tappable text-only button (links, "+ 추가" etc.).
class AlyakTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  const AlyakTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color ?? AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        textStyle: const TextStyle(
          fontFamily: AppTypography.family,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label),
    );
  }
}

/// Destructive (red) button used for delete confirmations.
class DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool full;
  final AlyakButtonSize size;

  const DangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.full = false,
    this.size = AlyakButtonSize.md,
  });

  @override
  Widget build(BuildContext context) {
    final s = _Sizing.of(size);
    return SizedBox(
      width: full ? double.infinity : null,
      height: s.height,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.alertInk,
          foregroundColor: Colors.white,
          padding: s.padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(s.radius),
          ),
          textStyle: TextStyle(
            fontFamily: AppTypography.family,
            fontSize: s.fontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
