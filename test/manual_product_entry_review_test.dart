// 단계 8 — ManualProductEntry.review 입력→저장 흐름 회귀 가드.
// manual_supplement_input_screen 의 _save() 가 [UserProductReview.sanitize]
// 결과를 ManualProductEntry.review 에 넣는 패턴을 모델 차원에서 검증.
// 위젯 마운트 없이 콜 사이트 로직을 미러링 — 본 프로젝트는 widget test
// 인프라가 없어 본 모델 통합 테스트가 최소·실용 가드.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:alyak/core/data/models/product_model.dart';
import 'package:alyak/core/data/models/user_product_review.dart';
import 'package:alyak/features/family/models/family_member.dart';

ManualProductEntry _entry({
  String? review,
  String? imagePath,
  String? userPhotoPath,
  DateTime? endedAt,
}) =>
    ManualProductEntry(
      id: 'm_1',
      name: '직접 입력 영양제',
      brand: '브랜드A',
      category: '비타민D',
      dailyDose: 1,
      packageSize: 60,
      imagePath: imagePath,
      userPhotoPath: userPhotoPath,
      ingredients: const {'vitamin_d_iu': 1000},
      startedAt: DateTime(2026, 5, 9),
      endedAt: endedAt,
      review: review,
      intakeTiming: IntakeTiming.morningAfter,
    );

/// 화면 _save() 가 사용자가 입력한 raw 텍스트를 [UserProductReview.sanitize]
/// 결과로 변환해 ManualProductEntry.review 에 넣는 패턴.
String? _reviewFromInput(String raw) {
  final cleaned = UserProductReview.sanitize(raw);
  return cleaned.isEmpty ? null : cleaned;
}

void main() {
  group('단계 8 — review 입력 sanitize 통합', () {
    test('일반 입력 → 양 끝 trim 후 그대로 저장', () {
      final entry = _entry(review: _reviewFromInput('  흡수 잘 됨  '));
      expect(entry.review, '흡수 잘 됨');
    });

    test('HTML/스크립트 태그 입력 → 태그만 제거 / 평문 본문 보존', () {
      final entry = _entry(
          review: _reviewFromInput('<script>alert(1)</script> 좋아요'));
      expect(entry.review, 'alert(1) 좋아요');
    });

    test('200자 초과 → kMaxReviewLength 로 cap', () {
      final raw = 'a' * 250;
      final entry = _entry(review: _reviewFromInput(raw));
      expect(entry.review!.length, UserProductReview.kMaxReviewLength);
    });

    test('빈 입력 / 공백만 → null 저장 (후기 없음 의미)', () {
      expect(_entry(review: _reviewFromInput('')).review, isNull);
      expect(_entry(review: _reviewFromInput('   ')).review, isNull);
      expect(_entry(review: _reviewFromInput('<br/>')).review, isNull,
          reason: '태그만 들어온 입력은 sanitize 후 빈 문자열 → null');
    });
  });

  group('단계 8 — 편집 패턴 (review 만 변경, 나머지 필드 보존)', () {
    test('imagePath / userPhotoPath / endedAt / ingredients 보존', () {
      final original = _entry(
        review: '예전 후기',
        imagePath: '/data/manual/m1_old.jpg',
        userPhotoPath: '/data/manual/m1_share.jpg',
        endedAt: DateTime(2026, 6, 1),
      );

      // 화면 _save() 의 명시적 생성자 패턴 — review 만 새 입력으로 교체,
      // 다른 V1.x 예정 필드는 _editing 에서 그대로 전달.
      final updated = ManualProductEntry(
        id: original.id,
        name: original.name,
        brand: original.brand,
        category: original.category,
        dailyDose: original.dailyDose,
        packageSize: original.packageSize,
        priceKrw: original.priceKrw,
        imagePath: original.imagePath,
        userPhotoPath: original.userPhotoPath,
        ingredients: original.ingredients,
        startedAt: original.startedAt,
        endedAt: original.endedAt,
        review: _reviewFromInput('새 후기'),
        intakeTiming: original.intakeTiming,
        dosePerIntake: original.dosePerIntake,
        intakesPerDay: original.intakesPerDay,
        intakeNote: original.intakeNote,
      );

      expect(updated.review, '새 후기');
      expect(updated.imagePath, '/data/manual/m1_old.jpg');
      expect(updated.userPhotoPath, '/data/manual/m1_share.jpg');
      expect(updated.endedAt, DateTime(2026, 6, 1));
      expect(updated.ingredients, original.ingredients);
      expect(updated.startedAt, original.startedAt);
    });

    test('편집 시 review 비우기 → null 로 갱신', () {
      final original = _entry(review: '예전 후기');
      final updated = ManualProductEntry(
        id: original.id,
        name: original.name,
        brand: original.brand,
        category: original.category,
        dailyDose: original.dailyDose,
        packageSize: original.packageSize,
        imagePath: original.imagePath,
        userPhotoPath: original.userPhotoPath,
        ingredients: original.ingredients,
        startedAt: original.startedAt,
        endedAt: original.endedAt,
        review: _reviewFromInput(''),
        intakeTiming: original.intakeTiming,
        dosePerIntake: original.dosePerIntake,
        intakesPerDay: original.intakesPerDay,
        intakeNote: original.intakeNote,
      );

      expect(updated.review, isNull);
    });
  });

  group('단계 8 — review JSON 영속성', () {
    test('sanitize 적용된 review 가 round-trip 통과', () {
      final entry = _entry(
        review: _reviewFromInput('  <b>좋아요</b>  '),
      );
      final restored = ManualProductEntry.fromJson(
        jsonDecode(jsonEncode(entry.toJson())) as Map<String, dynamic>,
      );
      expect(restored.review, '좋아요');
    });

    test('review = null 도 round-trip 보존', () {
      final entry = _entry(review: null);
      final restored = ManualProductEntry.fromJson(
        jsonDecode(jsonEncode(entry.toJson())) as Map<String, dynamic>,
      );
      expect(restored.review, isNull);
    });
  });
}
