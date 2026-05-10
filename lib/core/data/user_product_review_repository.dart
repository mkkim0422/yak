import 'dart:convert';

import '../security/secure_storage.dart';
import 'models/user_product_keys.dart';
import 'models/user_product_review.dart';

/// 큐레이션 [Product] (250 DB 항목)에 사용자가 작성한 단일 후기를 관리.
/// V1 정책: productId 당 후기 1개 고정(덮어쓰기). 모델([UserProductReview])
/// 자체는 List를 지원하지만 V1.x 누적 정책으로 전환할 때 UI만 교체하면
/// 되도록 저장 구조는 `List<UserProductReview>` JSON 그대로 유지 — 길이가
/// 항상 0 또는 1.
///
/// V1엔 SecureStorage 단일 백엔드, V1.x 단계 10에서 Supabase로 마이그레이션
/// 시 [UserProductReviewStorage] 구현체만 교체.
class UserProductReviewRepository {
  UserProductReviewRepository({UserProductReviewStorage? storage})
      : _storage = storage ?? const _SecureStorageBackend();

  final UserProductReviewStorage _storage;

  /// productId 후기 1건. 없으면 null.
  Future<UserProductReview?> getFor(String productId) async {
    final raw = await _storage.readMeta(productId);
    final items = UserProductReview.decodeList(raw);
    if (items.isEmpty) return null;
    // 길이가 1을 초과하는 legacy/누적 데이터가 들어와도 가장 최신 것을 반환.
    items.sort((a, b) => a.registeredAt.compareTo(b.registeredAt));
    return items.last;
  }

  /// productId 후기를 저장(덮어쓰기). [text]는 호출 측에서 sanitize 후 전달
  /// 권장 — 본 함수도 한 번 더 [UserProductReview.sanitize]를 거침. 결과가
  /// 빈 문자열이면 [clear]와 동일 동작.
  Future<UserProductReview?> save({
    required String productId,
    required String text,
  }) async {
    final cleaned = UserProductReview.sanitize(text);
    if (cleaned.isEmpty) {
      await clear(productId);
      return null;
    }
    final ts = DateTime.now();
    final review = UserProductReview(
      id: 'upr_${ts.microsecondsSinceEpoch}',
      productId: productId,
      review: cleaned,
      registeredAt: ts,
    );
    await _storage.writeMeta(
      productId,
      UserProductReview.encodeList([review]),
    );
    await _addToIndex(productId);
    return review;
  }

  /// productId 후기 삭제 — 메타·인덱스에서 제거.
  Future<void> clear(String productId) async {
    await _storage.deleteMeta(productId);
    await _removeFromIndex(productId);
  }

  /// 후기를 가진 productId 목록 (V1.x 단계 10 마이그레이션 / "내가 쓴 후기"
  /// 화면에서 사용 예정).
  Future<List<String>> indexedProductIds() => _storage.readIndex();

  Future<void> _addToIndex(String productId) async {
    final ids = await _storage.readIndex();
    if (ids.contains(productId)) return;
    await _storage.writeIndex([...ids, productId]);
  }

  Future<void> _removeFromIndex(String productId) async {
    final ids = await _storage.readIndex();
    if (!ids.contains(productId)) return;
    final next = ids.where((id) => id != productId).toList(growable: false);
    if (next.isEmpty) {
      await _storage.deleteIndex();
    } else {
      await _storage.writeIndex(next);
    }
  }
}

/// SecureStorage / 클라우드 백엔드를 추상화. V1엔 [_SecureStorageBackend]
/// 단일 구현, V1.x에서 Supabase 백엔드 추가.
abstract class UserProductReviewStorage {
  Future<String?> readMeta(String productId);
  Future<void> writeMeta(String productId, String json);
  Future<void> deleteMeta(String productId);
  Future<List<String>> readIndex();
  Future<void> writeIndex(List<String> productIds);
  Future<void> deleteIndex();
}

class _SecureStorageBackend implements UserProductReviewStorage {
  const _SecureStorageBackend();

  @override
  Future<String?> readMeta(String productId) =>
      SecureStorage.read(UserProductKeys.reviewsFor(productId));

  @override
  Future<void> writeMeta(String productId, String json) =>
      SecureStorage.write(UserProductKeys.reviewsFor(productId), json);

  @override
  Future<void> deleteMeta(String productId) =>
      SecureStorage.delete(UserProductKeys.reviewsFor(productId));

  @override
  Future<List<String>> readIndex() async {
    final raw = await SecureStorage.read(UserProductKeys.reviewsIndex);
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
  Future<void> writeIndex(List<String> productIds) =>
      SecureStorage.write(UserProductKeys.reviewsIndex, jsonEncode(productIds));

  @override
  Future<void> deleteIndex() =>
      SecureStorage.delete(UserProductKeys.reviewsIndex);
}
