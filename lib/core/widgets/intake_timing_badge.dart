import 'package:flutter/material.dart';

import '../data/models/product_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// 영양제별 권장 복용 시점을 사용자 친화 한 줄로 노출하는 톤다운 뱃지.
/// IntakeTiming의 8 분기를 [IntakeTimingX.badgeText]로 라벨링하고,
/// AppColors.primarySoft 배경 + caption 폰트로 렌더.
class IntakeTimingBadge extends StatelessWidget {
  final IntakeTiming timing;
  const IntakeTimingBadge({super.key, required this.timing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.r8),
      ),
      child: Text(
        timing.badgeText,
        style: AppTypography.caption.copyWith(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryInk,
        ),
      ),
    );
  }
}
