import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography mirrors `design/tokens.jsx` + section header sizes from the JSX
/// screens. Pretendard is the design-source family; when it isn't bundled,
/// `fallback` lets Flutter pick the platform's native Korean UI font
/// (Apple SD Gothic Neo on iOS, Noto Sans CJK KR on Android) so weights and
/// hangul shapes render the way the design assumes.
class AppTypography {
  AppTypography._();

  static const String family = 'Pretendard';

  static const List<String> fallback = <String>[
    'Pretendard Variable',
    'Apple SD Gothic Neo',
    'Noto Sans KR',
    'Noto Sans CJK KR',
    'Malgun Gothic',
  ];

  static const TextStyle display = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    letterSpacing: -0.6,
    height: 1.3,
  );

  static const TextStyle heading1 = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    letterSpacing: -0.55,
    height: 1.3,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: -0.4,
    height: 1.35,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: -0.34,
    height: 1.35,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: -0.3,
    height: 1.4,
  );

  static const TextStyle title = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: -0.15,
    height: 1.4,
  );

  static const TextStyle body1 = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
    height: 1.5,
  );

  static const TextStyle body2 = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.ink2,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
    height: 1.4,
  );

  static const TextStyle micro = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
    height: 1.4,
  );
}
