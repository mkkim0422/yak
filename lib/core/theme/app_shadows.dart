import 'package:flutter/material.dart';

/// Shadow tokens — flat rgba mapping of `design/tokens.jsx`.
class AppShadows {
  AppShadows._();

  // Card: '0 2px 8px rgba(16,24,40,0.04), 0 1px 2px rgba(16,24,40,0.03)'
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A101828), // ~0.04
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x08101828), // ~0.03
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  // Raise: '0 8px 24px rgba(16,24,40,0.08), 0 2px 6px rgba(16,24,40,0.04)'
  static const List<BoxShadow> raise = [
    BoxShadow(
      color: Color(0x14101828), // ~0.08
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0A101828),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  // Popover: '0 12px 32px rgba(16,24,40,0.14), 0 2px 6px rgba(16,24,40,0.06)'
  static const List<BoxShadow> popover = [
    BoxShadow(
      color: Color(0x24101828), // ~0.14
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
    BoxShadow(
      color: Color(0x0F101828),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];
}
