// 4단계 평가 + 쉬운 표현 라벨.
//
// 모토: 30-40대 엄마가 화면을 보고 1초 안에 이해할 수 있어야 한다.
// → "999%" 같은 충격 숫자 X, "40 mg" 같은 단위 단순화, "충분 / 부족 /
//   많음" 단어 명확.
//
// 평가 분기:
//   1. UL 초과    → excessive ("60 mg 많아요")
//   2. 권장량 90% 이상 → sufficient ("충분해요")  ← 10% 마진
//   3. 권장량 90% 미만 → insufficient ("450 mg 부족해요")
//   4. 권장량 정보 X  → unknown ("정보 없음")
//
// 10% 마진: 철분 13.5 mg vs 권장 14 mg 같은 미미한 차이를 "부족"으로
// 표기하지 않습니다. 사용자 직관 = "거의 다 먹었어"가 정상.

library;

enum NutrientStatus {
  /// 권장량 90% 이상이고 UL 이내. 사용자에게 ✅ "충분해요" 표시.
  sufficient,

  /// 권장량 90% 미만. ⚠️ "{차이} 부족해요" 표시.
  insufficient,

  /// UL 초과. ⚠️ "{차이} 많아요" 표시 (빨강).
  excessive,

  /// 권장량 정보 없음 (KDRIs 매트릭스에 없는 영양소). ℹ️ "정보 없음".
  unknown,
}

class NutrientEvaluation {
  /// 4단계 상태.
  final NutrientStatus status;

  /// insufficient일 때만 채워짐 — 권장량 - 섭취량.
  final double? deficit;

  /// excessive일 때만 채워짐 — 섭취량 - UL.
  final double? excess;

  const NutrientEvaluation({
    required this.status,
    this.deficit,
    this.excess,
  });
}

/// 권장량 90% 이상 = 충분으로 처리. 작은 차이를 "부족"으로 표시하지
/// 않기 위한 마진. 출처: V1 사용자 피드백 (철분 13.5/14 = "거의 다").
const double kSufficientMargin = 0.9;

NutrientEvaluation evaluateNutrient({
  required double amount,
  required double? recommended,
  required double? upperLimit,
}) {
  // UL 초과 우선 — 안전 이슈는 부족보다 더 큰 문제.
  if (upperLimit != null && amount > upperLimit) {
    return NutrientEvaluation(
      status: NutrientStatus.excessive,
      excess: amount - upperLimit,
    );
  }

  // 권장량 정보 없음.
  if (recommended == null || recommended <= 0) {
    return const NutrientEvaluation(status: NutrientStatus.unknown);
  }

  // 10% 마진 — 권장량 90% 이상이면 충분.
  if (amount >= recommended * kSufficientMargin) {
    return const NutrientEvaluation(status: NutrientStatus.sufficient);
  }

  return NutrientEvaluation(
    status: NutrientStatus.insufficient,
    deficit: recommended - amount,
  );
}

/// 사용자 친화 라벨 — "충분해요 / 부족해요 / 많아요 / 정보 없음".
/// 단위는 단순화 (α-TE / RAE / NE 등 접미사 제거).
String statusLabelFor(NutrientEvaluation eval, String unit) {
  final simpleUnit = simplifyUnit(unit);
  switch (eval.status) {
    case NutrientStatus.sufficient:
      return '✅ 충분해요';
    case NutrientStatus.insufficient:
      final d = eval.deficit ?? 0;
      return '⚠️ ${formatAmount(d)} $simpleUnit 부족해요';
    case NutrientStatus.excessive:
      final e = eval.excess ?? 0;
      return '⚠️ ${formatAmount(e)} $simpleUnit 많아요';
    case NutrientStatus.unknown:
      return 'ℹ️ 정보 없음';
  }
}

/// 단위 단순화 — 영양학 전문 표기를 일반인 단위로.
///   * mg α-TE → mg (비타민E)
///   * mcg RAE → mcg (비타민A)
///   * mg NE → mg (나이아신)
///   * mcg DFE → mcg (엽산)
///   * IU / mg / mcg / g / 억CFU → 그대로
String simplifyUnit(String unit) {
  return unit
      .replaceAll(' α-TE', '')
      .replaceAll(' RAE', '')
      .replaceAll(' NE', '')
      .replaceAll(' DFE', '')
      .trim();
}

/// 숫자 포맷 — 정수면 정수로, 소수면 1자리. 5.000 → "5", 13.5 → "13.5".
String formatAmount(double amount) {
  if (amount == amount.truncateToDouble()) {
    return amount.toInt().toString();
  }
  if (amount >= 100) return amount.toStringAsFixed(0);
  if (amount >= 10) return amount.toStringAsFixed(1);
  return amount.toStringAsFixed(2);
}

/// 대시보드용 4단계 부드러운 등급 라벨.
///
/// 정확한 mg 양은 product_detail의 [statusLabelFor]에 맡기고, 멤버 대시
/// 보드/현재 점검 화면은 "충격 숫자" 없이 직관 라벨만 노출합니다.
/// PART 9 컨벤션 — 사용자 노출 텍스트에 % 표시 금지.
///
/// 임계값:
///   * pct <  30 → "많이 부족"
///   * pct <  70 → "조금 부족"
///   * pct < 110 → "충분"
///   * pct >= 110 → "넉넉"
String softGradeLabel(int percentage) {
  if (percentage < 30) return '많이 부족';
  if (percentage < 70) return '조금 부족';
  if (percentage < 110) return '충분';
  return '넉넉';
}
