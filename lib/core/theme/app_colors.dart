import 'package:flutter/material.dart';

/// Color tokens mirroring `design/tokens.jsx`.
/// Toss-style — blue primary on a clean grey/white surface palette.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF3182F6);
  static const Color primarySoft = Color(0xFFEAF2FE);
  static const Color primaryInk = Color(0xFF1B64DA);

  // Surfaces
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF2F4F7);
  static const Color divider = Color(0xFFEEF0F3);
  static const Color hairline = Color(0xFFE5E8EC);

  // Text
  static const Color ink = Color(0xFF1F2937);
  static const Color ink2 = Color(0xFF4B5563);
  static const Color muted = Color(0xFF6B7280);
  static const Color faint = Color(0xFF9CA3AF);
  static const Color ghost = Color(0xFFC7CCD3);

  // Status — green (sufficient)
  static const Color okBorder = Color(0xFF10B981);
  static const Color okBg = Color(0xFFE8F5E9);
  static const Color okInk = Color(0xFF0E8C68);

  // Status — yellow (1-2 deficits)
  static const Color warnBorder = Color(0xFFF59E0B);
  static const Color warnBg = Color(0xFFFFF8E1);
  static const Color warnInk = Color(0xFFB07000);

  // Status — orange/red (3+ deficits)
  static const Color alertBorder = Color(0xFFEF4444);
  static const Color alertBg = Color(0xFFFFF3E0);
  static const Color alertInk = Color(0xFFC03030);

  // Pill
  static const Color pillBg = Color(0xFFF2F4F7);
  static const Color pillInk = Color(0xFF374151);

  // Legacy aliases — keep so existing screens still compile.
  // (Will be migrated screen-by-screen.)
  static const Color primaryLight = primarySoft;
  static const Color secondary = Color(0xFFFF8C69);
  static const Color textPrimary = ink;
  static const Color textSecondary = muted;
  static const Color success = okBorder;
  static const Color successLight = okBg;
  static const Color warning = warnBorder;
  static const Color warningLight = warnBg;
  static const Color attention = alertBorder;
  static const Color attentionLight = alertBg;
  static const Color error = alertBorder;

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

/// Status used by the family/nutrient surface system.
enum HealthStatus { ok, warn, alert }

extension HealthStatusPalette on HealthStatus {
  Color get border => switch (this) {
        HealthStatus.ok => AppColors.okBorder,
        HealthStatus.warn => AppColors.warnBorder,
        HealthStatus.alert => AppColors.alertBorder,
      };

  Color get bg => switch (this) {
        HealthStatus.ok => AppColors.okBg,
        HealthStatus.warn => AppColors.warnBg,
        HealthStatus.alert => AppColors.alertBg,
      };

  Color get ink => switch (this) {
        HealthStatus.ok => AppColors.okInk,
        HealthStatus.warn => AppColors.warnInk,
        HealthStatus.alert => AppColors.alertInk,
      };

  String get emoji => switch (this) {
        HealthStatus.ok => '✅',
        HealthStatus.warn => '⚠️',
        HealthStatus.alert => '🟠',
      };

  String get shortLabel => switch (this) {
        HealthStatus.ok => '충분',
        HealthStatus.warn => '부족',
        HealthStatus.alert => '많이 부족',
      };
}

HealthStatus statusFromDeficitCount(int count) {
  if (count == 0) return HealthStatus.ok;
  if (count <= 2) return HealthStatus.warn;
  return HealthStatus.alert;
}
