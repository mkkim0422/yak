import 'dart:convert';

/// 큐레이션 [Product] (250 DB 항목)에 사용자가 작성한 후기 메모를 매핑하는
/// 컬렉션 항목.
///
/// **왜 별도 모델인가?**
/// - `Product`는 read-only 250 DB 카탈로그 — 사용자별 데이터 부착 위치가
///   모델 자체에 없음.
/// - `ManualProductEntry.review`는 직접 입력 항목 자체에 한정. 본 컬렉션은
///   큐레이션 제품 후기 전용.
///
/// **저장 위치 (V1.x 활성화 시)**:
///   `cloud.user_product_reviews.{productId}` → JSON 배열 of [UserProductReview]
///   `cloud.user_product_reviews.index`       → JSON 배열 of productIds (전체 순회용)
///
/// V1엔 모델/직렬화만 제공, 실 repository는 V1.x에서 단계 10 Supabase
/// 인터페이스와 함께 활성화. UI 노출 X.
class UserProductReview {
  /// 후기 메모 최대 길이 — UI/검증 측에서도 본 상수 참조.
  static const int kMaxReviewLength = 200;

  /// 본 후기 항목의 안정 식별자 — `upr_{microsecondsSinceEpoch}` 형태.
  final String id;

  /// 큐레이션 Product의 id (`Product.id`).
  final String productId;

  /// 사용자 후기 본문 — 200자 이하, sanitize 후 저장. 입력 측에서 trim,
  /// HTML/script 태그 제거를 거친 평문만 들어옴.
  final String review;

  /// 사용자가 후기를 작성한 시점.
  final DateTime registeredAt;

  /// 사용자가 "다른 사용자에게 공유 동의"를 명시했는지. V1엔 항상 false
  /// (UI 미노출). V1.x 클라우드 도입 시 사용자 토글로 전환.
  final bool shareConsent;

  const UserProductReview({
    required this.id,
    required this.productId,
    required this.review,
    required this.registeredAt,
    this.shareConsent = false,
  });

  /// 입력값 정규화 — 양 끝 공백 제거 + HTML 태그 제거(매우 단순 정규식) +
  /// 길이 cap. UI에서 호출 후 본 함수로 통과한 결과를 [review]에 저장.
  static String sanitize(String raw) {
    var s = raw.trim();
    // 단순 태그 제거: 정규식 한 번. 복잡한 XSS 방어는 V1.x에 라이브러리 도입.
    s = s.replaceAll(RegExp(r'<[^>]*>'), '');
    if (s.length > kMaxReviewLength) {
      s = s.substring(0, kMaxReviewLength);
    }
    return s;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'review': review,
        'registered_at': registeredAt.toIso8601String(),
        'share_consent': shareConsent,
      };

  factory UserProductReview.fromJson(Map<String, dynamic> json) {
    return UserProductReview(
      id: (json['id'] as String?) ?? '',
      productId: (json['product_id'] as String?) ?? '',
      review: (json['review'] as String?) ?? '',
      registeredAt: DateTime.parse(json['registered_at'] as String),
      shareConsent: (json['share_consent'] as bool?) ?? false,
    );
  }

  UserProductReview copyWith({
    String? review,
    bool? shareConsent,
  }) =>
      UserProductReview(
        id: id,
        productId: productId,
        review: review ?? this.review,
        registeredAt: registeredAt,
        shareConsent: shareConsent ?? this.shareConsent,
      );

  static String encodeList(List<UserProductReview> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<UserProductReview> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    final dynamic parsed;
    try {
      parsed = jsonDecode(raw);
    } on FormatException {
      return const [];
    }
    if (parsed is! List) return const [];
    return parsed
        .whereType<Map<String, dynamic>>()
        .map(UserProductReview.fromJson)
        .toList(growable: false);
  }
}
