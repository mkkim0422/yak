// V1.x 활성화 예정 모델/필드의 직렬화·legacy 호환 회귀 가드.
// V1엔 UI 노출이 없으나 fromJson은 `assets/data/products.json`이 아닌
// SecureStorage에 누적된 user data에 대해 호출되므로 legacy/누락 키
// 호환은 출시 전 보장되어야 함.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:alyak/core/data/models/product_model.dart';
import 'package:alyak/core/data/models/user_product_keys.dart';
import 'package:alyak/core/data/models/user_product_photo.dart';
import 'package:alyak/core/data/models/user_product_review.dart';
import 'package:alyak/features/family/models/family_member.dart';

ManualProductEntry _baseManual() => ManualProductEntry(
      id: 'm_1',
      name: '직접 입력 비타민',
      brand: '브랜드A',
      category: '비타민D',
      dailyDose: 1,
      packageSize: 60,
      ingredients: const {'vitamin_d_iu': 1000},
      startedAt: DateTime(2026, 5, 9),
      intakeTiming: IntakeTiming.morningAfter,
    );

void main() {
  group('ManualProductEntry — V1.x 신규 필드 round-trip', () {
    test('userPhotoPath / endedAt / review 모두 보존', () {
      final entry = _baseManual().copyWith(
        userPhotoPath: '/data/manual/m_1_share.jpg',
        endedAt: DateTime(2026, 6, 1),
        review: '좋아요. 흡수 잘 됨.',
      );
      final restored = ManualProductEntry.fromJson(
        jsonDecode(jsonEncode(entry.toJson())) as Map<String, dynamic>,
      );
      expect(restored.userPhotoPath, '/data/manual/m_1_share.jpg');
      expect(restored.endedAt, DateTime(2026, 6, 1));
      expect(restored.review, '좋아요. 흡수 잘 됨.');
    });

    test('imagePath와 userPhotoPath는 독립적으로 저장', () {
      final entry = _baseManual().copyWith(
        imagePath: '/data/manual/m_1_private.jpg',
        userPhotoPath: '/data/manual/m_1_shared.jpg',
      );
      final restored = ManualProductEntry.fromJson(
        jsonDecode(jsonEncode(entry.toJson())) as Map<String, dynamic>,
      );
      expect(restored.imagePath, '/data/manual/m_1_private.jpg');
      expect(restored.userPhotoPath, '/data/manual/m_1_shared.jpg');
    });

    test('legacy entry (V1.x 신규 필드 모두 누락) → null 폴백', () {
      // V1.0 시점에 저장된 옛 manual entry — review/endedAt/userPhotoPath
      // 키가 JSON에 없음.
      final legacy = {
        'id': 'm_legacy',
        'name': '구버전',
        'category': '비타민C',
        'daily_dose': 1,
        'package_size': 30,
        'ingredients': {'vitamin_c_mg': 500},
        'started_at': '2026-05-01T00:00:00.000',
        'intake_timing': 'anyTimeAfterMeal',
        'dose_per_intake': 1,
        'intakes_per_day': 1,
      };
      final restored = ManualProductEntry.fromJson(legacy);
      expect(restored.userPhotoPath, isNull);
      expect(restored.endedAt, isNull);
      expect(restored.review, isNull);
      expect(restored.id, 'm_legacy');
      expect(restored.dailyDose, 1);
    });

    test('endedAt 빈 문자열 → null로 안전 폴백', () {
      final raw = _baseManual().toJson();
      raw['ended_at'] = '';
      final restored = ManualProductEntry.fromJson(raw);
      expect(restored.endedAt, isNull);
    });

    test('endedAt 잘못된 ISO 문자열 → null로 안전 폴백', () {
      final raw = _baseManual().toJson();
      raw['ended_at'] = 'not-a-date';
      final restored = ManualProductEntry.fromJson(raw);
      expect(restored.endedAt, isNull);
    });

    test('copyWith가 신규 필드를 누락 없이 보존', () {
      final entry = _baseManual().copyWith(
        userPhotoPath: '/p.jpg',
        endedAt: DateTime(2026, 6, 1),
        review: '메모',
      );
      final renamed = entry.copyWith(name: '이름 변경');
      expect(renamed.name, '이름 변경');
      expect(renamed.userPhotoPath, '/p.jpg');
      expect(renamed.endedAt, DateTime(2026, 6, 1));
      expect(renamed.review, '메모');
    });

    test('kMaxReviewLength 상수가 200', () {
      expect(ManualProductEntry.kMaxReviewLength, 200);
    });
  });

  group('UserProductPhoto — round-trip / legacy', () {
    test('toJson / fromJson round-trip', () {
      final p = UserProductPhoto(
        id: 'upp_1',
        productId: 'centrum_man',
        photoPath: '/data/products/centrum_man_123.jpg',
        registeredAt: DateTime(2026, 5, 9, 10, 30),
        shareConsent: true,
      );
      final restored = UserProductPhoto.fromJson(
        jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>,
      );
      expect(restored.id, 'upp_1');
      expect(restored.productId, 'centrum_man');
      expect(restored.photoPath, '/data/products/centrum_man_123.jpg');
      expect(restored.registeredAt, DateTime(2026, 5, 9, 10, 30));
      expect(restored.shareConsent, isTrue);
    });

    test('legacy payload (share_consent 누락) → false 폴백', () {
      final legacy = {
        'id': 'upp_old',
        'product_id': 'solgar_d3',
        'photo_path': '/old.jpg',
        'registered_at': '2026-04-01T00:00:00.000',
      };
      final restored = UserProductPhoto.fromJson(legacy);
      expect(restored.shareConsent, isFalse);
      expect(restored.id, 'upp_old');
    });

    test('encodeList / decodeList 라운드트립 + null/빈 입력', () {
      final items = [
        UserProductPhoto(
          id: 'upp_a',
          productId: 'p1',
          photoPath: '/a.jpg',
          registeredAt: DateTime(2026, 5, 1),
        ),
        UserProductPhoto(
          id: 'upp_b',
          productId: 'p1',
          photoPath: '/b.jpg',
          registeredAt: DateTime(2026, 5, 2),
          shareConsent: true,
        ),
      ];
      final encoded = UserProductPhoto.encodeList(items);
      final decoded = UserProductPhoto.decodeList(encoded);
      expect(decoded.length, 2);
      expect(decoded[1].shareConsent, isTrue);

      expect(UserProductPhoto.decodeList(null), isEmpty);
      expect(UserProductPhoto.decodeList(''), isEmpty);
      expect(UserProductPhoto.decodeList('not json'), isEmpty);
    });

    test('decodeList: 잘못된 entry 형태는 무시', () {
      const raw = '[{"id":"ok","product_id":"p","photo_path":"/x.jpg",'
          '"registered_at":"2026-05-09T00:00:00.000"},'
          '"not-an-object",42]';
      final decoded = UserProductPhoto.decodeList(raw);
      expect(decoded.length, 1);
      expect(decoded.first.id, 'ok');
    });

    test('copyWith — photoPath / shareConsent만 변경 가능', () {
      final p = UserProductPhoto(
        id: 'upp_1',
        productId: 'p',
        photoPath: '/old.jpg',
        registeredAt: DateTime(2026, 5, 9),
      );
      final updated = p.copyWith(photoPath: '/new.jpg', shareConsent: true);
      expect(updated.id, 'upp_1');
      expect(updated.productId, 'p');
      expect(updated.photoPath, '/new.jpg');
      expect(updated.shareConsent, isTrue);
      expect(updated.registeredAt, DateTime(2026, 5, 9));
    });
  });

  group('UserProductReview — round-trip / legacy / sanitize', () {
    test('toJson / fromJson round-trip', () {
      final r = UserProductReview(
        id: 'upr_1',
        productId: 'centrum_man',
        review: '아침 식후 한 정. 부담 없음.',
        registeredAt: DateTime(2026, 5, 9),
        shareConsent: false,
      );
      final restored = UserProductReview.fromJson(
        jsonDecode(jsonEncode(r.toJson())) as Map<String, dynamic>,
      );
      expect(restored.review, '아침 식후 한 정. 부담 없음.');
      expect(restored.shareConsent, isFalse);
    });

    test('legacy payload (share_consent 누락) → false 폴백', () {
      final legacy = {
        'id': 'upr_old',
        'product_id': 'p',
        'review': '구버전 후기',
        'registered_at': '2026-04-01T00:00:00.000',
      };
      final restored = UserProductReview.fromJson(legacy);
      expect(restored.shareConsent, isFalse);
      expect(restored.review, '구버전 후기');
    });

    test('sanitize — trim + HTML 태그 제거 + 200자 cap', () {
      expect(UserProductReview.sanitize('  hello  '), 'hello');
      expect(
        UserProductReview.sanitize('좋아요<script>alert(1)</script>'),
        '좋아요alert(1)',
      );
      final long = '가' * 250;
      final sanitized = UserProductReview.sanitize(long);
      expect(sanitized.length, 200);
    });

    test('kMaxReviewLength 상수가 200', () {
      expect(UserProductReview.kMaxReviewLength, 200);
    });

    test('encodeList / decodeList', () {
      final items = [
        UserProductReview(
          id: 'r1',
          productId: 'p',
          review: '메모1',
          registeredAt: DateTime(2026, 5, 1),
        ),
      ];
      final round = UserProductReview.decodeList(
        UserProductReview.encodeList(items),
      );
      expect(round.length, 1);
      expect(round.first.review, '메모1');
    });
  });

  group('UserProductKeys — SecureStorage 스키마', () {
    test('photosFor / reviewsFor — productId가 키에 그대로 포함', () {
      expect(UserProductKeys.photosFor('centrum_man'),
          'cloud.user_product_photos.centrum_man');
      expect(UserProductKeys.reviewsFor('solgar_d3'),
          'cloud.user_product_reviews.solgar_d3');
    });

    test('인덱스 키는 안정 상수', () {
      expect(UserProductKeys.photosIndex,
          'cloud.user_product_photos.index');
      expect(UserProductKeys.reviewsIndex,
          'cloud.user_product_reviews.index');
    });
  });
}
