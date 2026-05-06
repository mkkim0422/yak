import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Centered grey footer with the medical disclaimer.
class DisclaimerFooter extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  const DisclaimerFooter({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: const Text(
        '본 앱은 의료 행위가 아니며,\n의사·약사의 전문 진단을 대체하지 않습니다',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          height: 1.55,
          color: AppColors.faint,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
