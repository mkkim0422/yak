import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF4CAF82);
  static const Color primaryLight = Color(0xFFE8F5EE);
  static const Color secondary = Color(0xFFFF8C69);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

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
