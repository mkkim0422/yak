import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography mirrors `design/tokens.jsx` + section header sizes from the JSX
/// screens. Pretendard family is referenced; system fallbacks handle missing
/// font assets.
class AppTypography {
  AppTypography._();

  static const String family = 'Pretendard';

  static const TextStyle display = TextStyle(
    fontFamily: family,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    letterSpacing: -0.6,
    height: 1.3,
  );

  static const TextStyle heading1 = TextStyle(
    fontFamily: family,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    letterSpacing: -0.55,
    height: 1.3,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: family,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: -0.4,
    height: 1.35,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: family,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: -0.34,
    height: 1.35,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: -0.3,
    height: 1.4,
  );

  static const TextStyle title = TextStyle(
    fontFamily: family,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: -0.15,
    height: 1.4,
  );

  static const TextStyle body1 = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
    height: 1.5,
  );

  static const TextStyle body2 = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.ink2,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: family,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
    height: 1.4,
  );

  static const TextStyle micro = TextStyle(
    fontFamily: family,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
    height: 1.4,
  );
}
