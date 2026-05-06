import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

/// Title row with optional trailing action ("자세히 →", "+ 추가" etc.).
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.padding =
        const EdgeInsets.only(left: 4, right: 4, bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Text(title, style: AppTypography.sectionTitle)),
          action ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}
