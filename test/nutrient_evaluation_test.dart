// 4단계 평가 + 라벨 + 단위 단순화 + 숫자 포맷 회귀 가드.
//
// 모토: 30-40대 엄마가 1초에 이해해야 한다 — 임계값/표현 변경 시 바로
// 깨지도록 강하게 고정.

import 'package:flutter_test/flutter_test.dart';

import 'package:alyak/core/data/nutrient_evaluation.dart';

void main() {
  group('evaluateNutrient — 4단계 분기', () {
    test('UL 초과 → excessive (UL 우선; 권장량 충분 + UL 초과여도 excessive)',
        () {
      final r = evaluateNutrient(
        amount: 5000,
        recommended: 700,
        upperLimit: 3000,
      );
      expect(r.status, NutrientStatus.excessive);
      expect(r.excess, 2000);
      expect(r.deficit, isNull);
    });

    test('권장량 90% 이상 + UL 이내 → sufficient', () {
      final r = evaluateNutrient(
        amount: 13.5,
        recommended: 14,
        upperLimit: 45,
      );
      expect(r.status, NutrientStatus.sufficient);
      expect(r.deficit, isNull);
      expect(r.excess, isNull);
    });

    test('권장량 정확히 90% → sufficient (마진 경계 포함)', () {
      final r = evaluateNutrient(
        amount: 9.0,
        recommended: 10.0,
        upperLimit: null,
      );
      expect(r.status, NutrientStatus.sufficient);
    });

    test('권장량 89.99% → insufficient (마진 미달)', () {
      final r = evaluateNutrient(
        amount: 8.99,
        recommended: 10.0,
        upperLimit: null,
      );
      expect(r.status, NutrientStatus.insufficient);
      expect(r.deficit, closeTo(1.01, 0.001));
    });

    test('권장량 미달 → insufficient + deficit 정확', () {
      final r = evaluateNutrient(
        amount: 100,
        recommended: 550,
        upperLimit: null,
      );
      expect(r.status, NutrientStatus.insufficient);
      expect(r.deficit, 450);
      expect(r.excess, isNull);
    });

    test('권장량 정보 없음 → unknown', () {
      final r = evaluateNutrient(
        amount: 100,
        recommended: null,
        upperLimit: null,
      );
      expect(r.status, NutrientStatus.unknown);
      expect(r.deficit, isNull);
      expect(r.excess, isNull);
    });

    test('권장량 0 → unknown (0/마이너스 방어)', () {
      final r = evaluateNutrient(
        amount: 100,
        recommended: 0,
        upperLimit: null,
      );
      expect(r.status, NutrientStatus.unknown);
    });

    test('UL 정보 없음 + 권장량 충분 → sufficient (UL null 허용)', () {
      final r = evaluateNutrient(
        amount: 9999,
        recommended: 100,
        upperLimit: null,
      );
      expect(r.status, NutrientStatus.sufficient);
    });
  });

  group('statusLabelFor — 사용자 친화 라벨', () {
    test('sufficient → "✅ 충분해요"', () {
      final r = evaluateNutrient(
        amount: 14,
        recommended: 14,
        upperLimit: 45,
      );
      expect(statusLabelFor(r, 'mg'), '✅ 충분해요');
    });

    test('insufficient → "⚠️ 450 mg 부족해요" (정수)', () {
      final r = evaluateNutrient(
        amount: 100,
        recommended: 550,
        upperLimit: null,
      );
      expect(statusLabelFor(r, 'mg'), '⚠️ 450 mg 부족해요');
    });

    test('excessive → "⚠️ 60 mg 많아요"', () {
      final r = evaluateNutrient(
        amount: 100,
        recommended: 14,
        upperLimit: 40,
      );
      expect(statusLabelFor(r, 'mg'), '⚠️ 60 mg 많아요');
    });

    test('unknown → "ℹ️ 정보 없음"', () {
      final r = evaluateNutrient(
        amount: 100,
        recommended: null,
        upperLimit: null,
      );
      expect(statusLabelFor(r, 'mg'), 'ℹ️ 정보 없음');
    });

    test('단위 단순화 — "mg α-TE" → "mg" (비타민E)', () {
      final r = evaluateNutrient(
        amount: 1,
        recommended: 12,
        upperLimit: 540,
      );
      expect(statusLabelFor(r, 'mg α-TE'), '⚠️ 11 mg 부족해요');
    });

    test('단위 단순화 — "mcg RAE" → "mcg" (비타민A)', () {
      final r = evaluateNutrient(
        amount: 100,
        recommended: 700,
        upperLimit: 3000,
      );
      expect(statusLabelFor(r, 'mcg RAE'), '⚠️ 600 mcg 부족해요');
    });

    test('단위 단순화 — "mg NE" → "mg" (나이아신)', () {
      final r = evaluateNutrient(
        amount: 5,
        recommended: 14,
        upperLimit: 35,
      );
      expect(statusLabelFor(r, 'mg NE'), '⚠️ 9 mg 부족해요');
    });

    test('단위 단순화 — "mcg DFE" → "mcg" (엽산)', () {
      final r = evaluateNutrient(
        amount: 100,
        recommended: 400,
        upperLimit: 1000,
      );
      expect(statusLabelFor(r, 'mcg DFE'), '⚠️ 300 mcg 부족해요');
    });
  });

  group('simplifyUnit — 영양학 표기 → 일반 단위', () {
    test('α-TE 제거', () {
      expect(simplifyUnit('mg α-TE'), 'mg');
    });

    test('RAE 제거', () {
      expect(simplifyUnit('mcg RAE'), 'mcg');
    });

    test('NE 제거', () {
      expect(simplifyUnit('mg NE'), 'mg');
    });

    test('DFE 제거', () {
      expect(simplifyUnit('mcg DFE'), 'mcg');
    });

    test('일반 단위 그대로 — mg / mcg / IU / g / 억CFU', () {
      expect(simplifyUnit('mg'), 'mg');
      expect(simplifyUnit('mcg'), 'mcg');
      expect(simplifyUnit('IU'), 'IU');
      expect(simplifyUnit('g'), 'g');
      expect(simplifyUnit('억CFU'), '억CFU');
    });
  });

  group('formatAmount — 숫자 포맷', () {
    test('정수면 정수로', () {
      expect(formatAmount(5.0), '5');
      expect(formatAmount(100.0), '100');
    });

    test('100 이상 소수 → 정수 반올림', () {
      expect(formatAmount(123.4), '123');
      expect(formatAmount(450.7), '451');
    });

    test('10 이상 100 미만 → 1자리', () {
      expect(formatAmount(13.5), '13.5');
      expect(formatAmount(99.99), '100.0');
    });

    test('10 미만 → 2자리', () {
      expect(formatAmount(1.01), '1.01');
      expect(formatAmount(0.85), '0.85');
    });
  });

  group('실제 페르소나 시뮬레이션', () {
    test('철분 13.5 / 권장 14 / UL 45 — 마진 살아서 충분', () {
      final r = evaluateNutrient(
        amount: 13.5,
        recommended: 14,
        upperLimit: 45,
      );
      expect(statusLabelFor(r, 'mg'), '✅ 충분해요');
    });

    test('비타민B6 40 mg / 권장 1.4 mg / UL 100 — 권장량 28배지만 UL 이내 = 충분', () {
      final r = evaluateNutrient(
        amount: 40,
        recommended: 1.4,
        upperLimit: 100,
      );
      expect(r.status, NutrientStatus.sufficient,
          reason: '권장량 X28이라도 UL 이내면 sufficient — % 표시 X로 충격 없음');
    });

    test('비타민B6 200 mg / UL 100 — 100 mg 많아요', () {
      final r = evaluateNutrient(
        amount: 200,
        recommended: 1.4,
        upperLimit: 100,
      );
      expect(statusLabelFor(r, 'mg'), '⚠️ 100 mg 많아요');
    });

    test('비타민D 정보 없음 영양소 (manganese 등) → 정보 없음', () {
      final r = evaluateNutrient(
        amount: 5,
        recommended: null,
        upperLimit: null,
      );
      expect(statusLabelFor(r, 'mg'), 'ℹ️ 정보 없음');
    });

    test('칼슘 200 mg / 권장 700 mg → 500 mg 부족', () {
      final r = evaluateNutrient(
        amount: 200,
        recommended: 700,
        upperLimit: 2500,
      );
      expect(statusLabelFor(r, 'mg'), '⚠️ 500 mg 부족해요');
    });
  });
}
