// 단계 8 — UserProductReviewRepository 회귀 가드.
// SecureStorage 호출은 storage 인터페이스 주입으로 격리. V1 정책: productId
// 당 후기 1개 고정(덮어쓰기). 모델 자체는 List를 지원하지만 길이가 항상
// 0 또는 1 이도록 repository가 강제.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:alyak/core/data/models/user_product_keys.dart';
import 'package:alyak/core/data/models/user_product_review.dart';
import 'package:alyak/core/data/user_product_review_repository.dart';

class _FakeStorage implements UserProductReviewStorage {
  final Map<String, String> _meta = {};
  String? _index;

  @override
  Future<String?> readMeta(String productId) async =>
      _meta[UserProductKeys.reviewsFor(productId)];

  @override
  Future<void> writeMeta(String productId, String json) async {
    _meta[UserProductKeys.reviewsFor(productId)] = json;
  }

  @override
  Future<void> deleteMeta(String productId) async {
    _meta.remove(UserProductKeys.reviewsFor(productId));
  }

  @override
  Future<List<String>> readIndex() async {
    final raw = _index;
    if (raw == null || raw.isEmpty) return const [];
    try {
      final parsed = jsonDecode(raw);
      if (parsed is! List) return const [];
      return parsed.whereType<String>().toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<void> writeIndex(List<String> productIds) async {
    _index = jsonEncode(productIds);
  }

  @override
  Future<void> deleteIndex() async {
    _index = null;
  }

  void seedMetaRaw(String productId, String raw) {
    _meta[UserProductKeys.reviewsFor(productId)] = raw;
  }

  String? rawMeta(String productId) =>
      _meta[UserProductKeys.reviewsFor(productId)];
}

void main() {
  late _FakeStorage storage;
  late UserProductReviewRepository repo;

  setUp(() {
    storage = _FakeStorage();
    repo = UserProductReviewRepository(storage: storage);
  });

  group('save', () {
    test('처음 저장 → 후기 1건 + 인덱스 등록', () async {
      final review = await repo.save(
        productId: 'centrum_man',
        text: '흡수가 잘 됨',
      );

      expect(review, isNotNull);
      expect(review!.review, '흡수가 잘 됨');
      expect(review.id.startsWith('upr_'), isTrue);

      final got = await repo.getFor('centrum_man');
      expect(got?.review, '흡수가 잘 됨');

      final index = await repo.indexedProductIds();
      expect(index, ['centrum_man']);
    });

    test('덮어쓰기 — 동일 productId 두 번 저장하면 최신만 남음', () async {
      await repo.save(productId: 'centrum_man', text: '첫 번째 후기');
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await repo.save(productId: 'centrum_man', text: '두 번째 후기');

      final got = await repo.getFor('centrum_man');
      expect(got?.review, '두 번째 후기');

      // 저장된 JSON list 길이가 항상 1 — V1 정책 락.
      final raw = storage.rawMeta('centrum_man')!;
      final parsed = jsonDecode(raw) as List;
      expect(parsed.length, 1,
          reason: '덮어쓰기 후에도 list 길이는 1을 유지해야 함');

      // 인덱스도 1회만.
      expect(await repo.indexedProductIds(), ['centrum_man']);
    });

    test('sanitize 적용 — HTML 태그 제거 / trim / 200자 cap', () async {
      final raw = '  <script>alert(1)</script> 좋아요  ';
      await repo.save(productId: 'centrum_man', text: raw);

      final got = await repo.getFor('centrum_man');
      expect(got?.review, 'alert(1) 좋아요',
          reason: '<script> 태그는 제거되고 alert(1) 텍스트와 양 끝 공백 제거 후 본문만 남음');
      expect(got!.review.length, lessThanOrEqualTo(200));
    });

    test('200자 초과 — 자동 cap', () async {
      final raw = 'a' * 250;
      await repo.save(productId: 'centrum_man', text: raw);

      final got = await repo.getFor('centrum_man');
      expect(got!.review.length, UserProductReview.kMaxReviewLength);
    });

    test('빈 입력 / 공백만 — clear 와 동일', () async {
      await repo.save(productId: 'centrum_man', text: '먼저 저장');
      final result = await repo.save(productId: 'centrum_man', text: '   ');

      expect(result, isNull);
      expect(await repo.getFor('centrum_man'), isNull);
      expect(await repo.indexedProductIds(), isEmpty,
          reason: '후기가 비면 인덱스에서도 제거');
    });

    test('서로 다른 productId 격리', () async {
      await repo.save(productId: 'centrum_man', text: '맨 후기');
      await repo.save(productId: 'centrum_woman', text: '우먼 후기');

      expect((await repo.getFor('centrum_man'))!.review, '맨 후기');
      expect((await repo.getFor('centrum_woman'))!.review, '우먼 후기');
      expect((await repo.indexedProductIds()).toSet(),
          {'centrum_man', 'centrum_woman'});
    });
  });

  group('clear', () {
    test('clear — 메타·인덱스 모두 비움', () async {
      await repo.save(productId: 'centrum_man', text: '후기');
      await repo.clear('centrum_man');

      expect(await repo.getFor('centrum_man'), isNull);
      expect(await repo.indexedProductIds(), isEmpty);
    });

    test('clear — 다른 productId 후기는 영향 없음', () async {
      await repo.save(productId: 'centrum_man', text: '맨');
      await repo.save(productId: 'centrum_woman', text: '우먼');

      await repo.clear('centrum_man');

      expect(await repo.getFor('centrum_man'), isNull);
      expect((await repo.getFor('centrum_woman'))!.review, '우먼');
      expect(await repo.indexedProductIds(), ['centrum_woman']);
    });
  });

  group('legacy / corruption tolerance', () {
    test('깨진 JSON 메타 → 빈 결과', () async {
      storage.seedMetaRaw('centrum_man', 'not-json');
      expect(await repo.getFor('centrum_man'), isNull);
    });

    test('legacy 누적 list (length>1) → 가장 최신만 반환', () async {
      // V1.x에서 누적 정책으로 전환되더라도 V1 UI가 1개만 다루도록.
      final list = [
        {
          'id': 'upr_old',
          'product_id': 'centrum_man',
          'review': '오래된 후기',
          'registered_at': '2025-01-01T10:00:00.000',
          'share_consent': false,
        },
        {
          'id': 'upr_new',
          'product_id': 'centrum_man',
          'review': '최근 후기',
          'registered_at': '2026-05-09T10:00:00.000',
        }
      ];
      storage.seedMetaRaw('centrum_man', jsonEncode(list));

      final got = await repo.getFor('centrum_man');
      expect(got?.review, '최근 후기');
      expect(got?.shareConsent, false,
          reason: 'share_consent 누락 legacy → false 폴백');
    });
  });

  test('UserProductKeys 형태 — V1.x Supabase 마이그레이션 키 락', () {
    expect(UserProductKeys.reviewsFor('centrum_man'),
        'cloud.user_product_reviews.centrum_man');
    expect(UserProductKeys.reviewsIndex,
        'cloud.user_product_reviews.index');
  });
}
