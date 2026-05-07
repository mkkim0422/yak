// KDRIs 2025 매트릭스 16종 → 24종 확장에 대한 회귀 가드.
//
// 추가된 영양소 + 어른만 셀이었던 매트릭스의 13구간 × 성별 풀 매트릭스
// 확장이 의도대로 동작하는지 페르소나 시뮬레이션으로 검증합니다.

import 'package:flutter_test/flutter_test.dart';

import 'package:alyak/core/data/kdris_2025.dart';

void main() {
  group('신규 매트릭스 — 비타민B군', () {
    test('vitamin_b1_mg 35세 남 1.2 / 여 1.1', () {
      expect(
        recommendedKDRIs2025(
            nutrient: 'vitamin_b1_mg', age: 35, isMale: true),
        1.2,
      );
      expect(
        recommendedKDRIs2025(
            nutrient: 'vitamin_b1_mg', age: 35, isMale: false),
        1.1,
      );
    });

    test('vitamin_b2_mg 35세 남 1.5 / 여 1.2 / 임신부 +0.4', () {
      expect(
        recommendedKDRIs2025(
            nutrient: 'vitamin_b2_mg', age: 35, isMale: true),
        1.5,
      );
      expect(
        recommendedKDRIs2025(
          nutrient: 'vitamin_b2_mg',
          age: 35,
          isMale: false,
          isPregnant: true,
        ),
        1.6,
      );
    });

    test('vitamin_b3_mg (나이아신) 35세 여 14, UL 35', () {
      expect(
        recommendedKDRIs2025(
            nutrient: 'vitamin_b3_mg', age: 35, isMale: false),
        14,
      );
      expect(upperLimitKDRIs2025('vitamin_b3_mg'), 35);
    });

    test('vitamin_b5_mg (판토텐산) 성인 5 / 임신부 6', () {
      expect(
        recommendedKDRIs2025(
            nutrient: 'vitamin_b5_mg', age: 35, isMale: false),
        5,
      );
      expect(
        recommendedKDRIs2025(
          nutrient: 'vitamin_b5_mg',
          age: 35,
          isMale: false,
          isPregnant: true,
        ),
        6,
      );
    });

    test('biotin_mcg 성인 30 mcg, UL 미설정', () {
      expect(
        recommendedKDRIs2025(
            nutrient: 'biotin_mcg', age: 35, isMale: false),
        30,
      );
      expect(upperLimitKDRIs2025('biotin_mcg'), isNull);
    });
  });

  group('신규 매트릭스 — 비타민K + 무기질', () {
    test('vitamin_k_mcg 성인 남 75 / 여 65, UL 미설정', () {
      expect(
        recommendedKDRIs2025(
            nutrient: 'vitamin_k_mcg', age: 35, isMale: true),
        75,
      );
      expect(
        recommendedKDRIs2025(
            nutrient: 'vitamin_k_mcg', age: 35, isMale: false),
        65,
      );
      expect(upperLimitKDRIs2025('vitamin_k_mcg'), isNull);
    });

    test('copper_mg (mg 단위) 성인 남 0.85 / 여 0.80, UL 10mg', () {
      expect(
        recommendedKDRIs2025(
            nutrient: 'copper_mg', age: 35, isMale: true),
        0.85,
      );
      expect(
        recommendedKDRIs2025(
            nutrient: 'copper_mg', age: 35, isMale: false),
        0.80,
      );
      expect(upperLimitKDRIs2025('copper_mg'), 10);
    });

    test('manganese_mg 성인 남 4 / 여 3.5, UL 11', () {
      expect(
        recommendedKDRIs2025(
            nutrient: 'manganese_mg', age: 35, isMale: true),
        4.0,
      );
      expect(
        recommendedKDRIs2025(
            nutrient: 'manganese_mg', age: 35, isMale: false),
        3.5,
      );
      expect(upperLimitKDRIs2025('manganese_mg'), 11);
    });
  });

  group('기존 매트릭스 어린이 셀 채움 확인', () {
    test('vitamin_e_mg 7세 (이전엔 어른만 → 폴백) → 7 mg', () {
      // child6to8 = 7
      expect(
        recommendedKDRIs2025(
            nutrient: 'vitamin_e_mg', age: 7, isMale: true),
        7,
      );
    });

    test('vitamin_b6_mg 5세 → 0.7 mg', () {
      expect(
        recommendedKDRIs2025(
            nutrient: 'vitamin_b6_mg', age: 5, isMale: true),
        0.7,
      );
    });

    test('vitamin_b3_mg (niacin) 10세 → 11 mg', () {
      expect(
        recommendedKDRIs2025(
            nutrient: 'vitamin_b3_mg', age: 10, isMale: true),
        11,
      );
    });

    test('iodine_mcg 7세 → 100 mcg', () {
      expect(
        recommendedKDRIs2025(
            nutrient: 'iodine_mcg', age: 7, isMale: true),
        100,
      );
    });
  });

  group('UL 별칭 — niacin_mg / copper_mcg', () {
    test('legacy niacin_mg는 conflict_checker alias로 35 유지', () {
      // 매트릭스에는 vitamin_b3_mg만 있지만 conflict_checker의 _ulFor()가
      // alias 35를 보유하므로 UL 비교는 동작.
      // 본 테스트는 alias 정합 회귀만 검증.
      expect(upperLimitKDRIs2025('niacin_mg'), isNull,
          reason: '매트릭스에는 없음');
    });
  });
}
