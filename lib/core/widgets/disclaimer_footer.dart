import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Centered grey footer with the short medical disclaimer.
/// Used at the bottom of every primary surface — home / member detail /
/// recommendation / product detail.
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
        '본 앱은 의료 행위가 아니며 일반 영양 정보를 제공해요.\n'
        '정확한 복용은 제품 라벨과 의사·약사 지시를 우선하세요.',
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

/// Compact disclaimer for product-detail and category pages — single line
/// reminder that the 250-DB info is verified label data, not a clinician's
/// recommendation.
class ProductInfoDisclaimer extends StatelessWidget {
  const ProductInfoDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        '표시된 정보는 제품 라벨 기반이며, 의학적 진단을 대체하지 않아요. '
        '복용 전 의사·약사와 상담하세요.',
        textAlign: TextAlign.center,
        style: AppTypography.caption.copyWith(
          fontSize: 11,
          color: AppColors.muted,
          height: 1.5,
        ),
      ),
    );
  }
}
