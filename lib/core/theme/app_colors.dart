import 'package:flutter/material.dart';

/// Color tokens — teal primary, amber for "보충 필요", green for "검증된 정보"
/// only. Red is reserved for true clinical danger (drug interaction warnings)
/// and is therefore intentionally absent from the everyday palette.
///
/// Token names are kept stable across the codebase (`alertBorder`, `okInk`
/// etc.) — they now point to the new palette so existing callers see the new
/// look without per-file refactors.
class AppColors {
  AppColors._();

  // ── Brand: Teal (recovery + trust) ─────────────────────────
  static const Color primary = Color(0xFF00ACC1);
  static const Color primarySoft = Color(0xFFE0F7FA);
  static const Color primaryInk = Color(0xFF00838F);

  // ── Surfaces ──────────────────────────────────────────────
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF0F2F5);
  static const Color divider = Color(0xFFEEF0F3);
  static const Color hairline = Color(0xFFE0E0E0);

  // ── Text ──────────────────────────────────────────────────
  static const Color ink = Color(0xFF1A1A1A);
  static const Color ink2 = Color(0xFF333333);
  static const Color muted = Color(0xFF666666);
  static const Color faint = Color(0xFF999999);
  static const Color ghost = Color(0xFFC7CCD3);

  // ── Status: green = sufficient / 검증된 정보 ───────────────
  static const Color okBorder = Color(0xFF4CAF50);
  static const Color okBg = Color(0xFFE8F5E9);
  static const Color okInk = Color(0xFF2E7D32);

  // ── Status: amber = 주의 / 보충 필요 ────────────────────────
  // Both "1-2개 부족" and "3개+ 부족" now share this palette. Tone is amber,
  // not orange-red, so the message reads as "주의" rather than "위험".
  static const Color warnBorder = Color(0xFFFF9800);
  static const Color warnBg = Color(0xFFFFF3E0);
  static const Color warnInk = Color(0xFFE65100);

  /// Reserved for *true* clinical danger (e.g. drug interaction warnings,
  /// admin destructive actions). Do not use for "보충 필요" or other
  /// nutrient-deficit messaging.
  static const Color danger = Color(0xFFD32F2F);
  static const Color dangerBg = Color(0xFFFFEBEE);

  // ── Misc ──────────────────────────────────────────────────
  static const Color pillBg = Color(0xFFF0F2F5);
  static const Color pillInk = Color(0xFF374151);

  // ── Legacy aliases for callers that haven't been migrated ──
  // These all point at the new palette so the existing tree picks up the
  // teal/amber look automatically. Red `alertBorder/Ink` now resolves to
  // amber so old "🟠 많이 부족" style banners are softened.
  static const Color primaryLight = primarySoft;
  static const Color secondary = primaryInk;
  static const Color textPrimary = ink;
  static const Color textSecondary = muted;
  static const Color success = okBorder;
  static const Color successLight = okBg;
  static const Color warning = warnBorder;
  static const Color warningLight = warnBg;
  static const Color attention = warnBorder;
  static const Color attentionLight = warnBg;
  static const Color error = danger;

  /// Was red. Now resolves to amber so banners using this token soften
  /// without per-file edits. True danger uses `AppColors.danger`.
  static const Color alertBorder = warnBorder;
  static const Color alertBg = warnBg;
  static const Color alertInk = warnInk;

  static const List<Color> familyMemberColors = [
    Color(0xFFFF6B9D),
    Color(0xFF4FACFE),
    Color(0xFF43E97B),
    Color(0xFFFA8231),
    Color(0xFFA29BFE),
    Color(0xFFFD79A8),
  ];

  static Color forFamilyMember(int index) {
    return familyMemberColors[index % familyMemberColors.length];
  }
}

/// Status used by the family/nutrient surface system. After the persona
/// review we collapsed "alert" semantics into "warn" — both render in amber
/// now, with softened copy ("보충 필요" instead of "많이 부족").
enum HealthStatus { ok, warn, alert }

extension HealthStatusPalette on HealthStatus {
  Color get border => switch (this) {
        HealthStatus.ok => AppColors.okBorder,
        HealthStatus.warn => AppColors.warnBorder,
        HealthStatus.alert => AppColors.warnBorder,
      };

  Color get bg => switch (this) {
        HealthStatus.ok => AppColors.okBg,
        HealthStatus.warn => AppColors.warnBg,
        HealthStatus.alert => AppColors.warnBg,
      };

  Color get ink => switch (this) {
        HealthStatus.ok => AppColors.okInk,
        HealthStatus.warn => AppColors.warnInk,
        HealthStatus.alert => AppColors.warnInk,
      };

  String get emoji => switch (this) {
        HealthStatus.ok => '✅',
        HealthStatus.warn => '🟡',
        HealthStatus.alert => '🟡',
      };

  String get shortLabel => switch (this) {
        HealthStatus.ok => '잘 챙기는 중',
        HealthStatus.warn => '보충 필요',
        HealthStatus.alert => '보충 필요',
      };
}

HealthStatus statusFromDeficitCount(int count) {
  if (count == 0) return HealthStatus.ok;
  if (count <= 2) return HealthStatus.warn;
  return HealthStatus.alert;
}
