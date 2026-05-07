import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Centered grey footer with the medical disclaimer (KDRIs 2025 grounded).
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
        '본 앱은 의료 행위가 아니며,\n'
        '의사·약사의 전문 진단을 대체하지 않습니다.\n'
        '추천은 2025 한국인 영양소 섭취기준(KDRIs) 기반 일반 정보입니다.',
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

/// Stronger inline disclaimer for the recommendation surfaces. Renders as a
/// soft-tinted info card with a 2-line body specifically calling out the
/// KDRIs scope (no smoking/drinking/sleep/stress branching) and steering
/// users toward a clinician for personal cases.
class KdrisRecommendationDisclaimer extends StatelessWidget {
  const KdrisRecommendationDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ℹ️', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '추천은 2025 한국인 영양소 섭취기준(KDRIs)을 기준으로 한 일반 '
              '정보입니다. 흡연·음주·수면·스트레스 등 KDRIs에 별도 권장이 '
              '없는 항목은 일반 권장량을 적용합니다. 개인 건강 상태에 맞는 '
              '결정은 의사·약사와 상담하세요.',
              style: AppTypography.caption.copyWith(
                fontSize: 11.5,
                color: AppColors.ink2,
                height: 1.5,
              ),
            ),
          ),
        ],
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
        '표시된 정보는 라벨·KDRIs 2025 기반이며, 의학적 진단을 대체하지 '
        '않습니다. 복용 결정 전 의사·약사와 상담하세요.',
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
