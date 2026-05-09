import 'dart:convert';

/// 큐레이션 [Product] (250 DB 항목)에 사용자가 등록한 약통 사진을 매핑하는
/// 컬렉션 항목.
///
/// **왜 별도 모델인가?**
/// - `Product`는 read-only 250 DB 카탈로그 — 사용자별 데이터 부착 위치가
///   모델 자체에 없음.
/// - `ManualProductEntry`는 사용자 데이터이므로 `imagePath` / `userPhotoPath`를
///   자체 보유. 본 컬렉션은 큐레이션 제품 한정.
///
/// **저장 위치 (V1.x 활성화 시)**:
///   `cloud.user_product_photos.{productId}` → JSON 배열 of [UserProductPhoto]
///   `cloud.user_product_photos.index`       → JSON 배열 of productIds (전체 순회용)
///
/// V1엔 모델/직렬화만 제공, 실 repository는 V1.x에서 단계 10 Supabase
/// 인터페이스와 함께 활성화. UI 노출 X.
class UserProductPhoto {
  /// 본 사진 항목의 안정 식별자 — `upp_{microsecondsSinceEpoch}` 형태로
  /// 생성되어 productId 내부에서 유일.
  final String id;

  /// 큐레이션 Product의 id (`Product.id`).
  final String productId;

  /// 기기 내 사진 파일 절대 경로 — `<appDocs>/products/{productId}_{ts}.jpg`.
  /// 파일 자체는 SecureStorage에 들어가지 않으므로 본 경로는 평문 보관.
  final String photoPath;

  /// 사용자가 사진을 등록한 시점 (현지 시간). DateTime → ISO8601 round-trip.
  final DateTime registeredAt;

  /// 사용자가 "다른 사용자에게 공유 동의"를 명시했는지. V1엔 항상 false
  /// (UI 미노출). V1.x 클라우드 도입 시 사용자 토글로 전환.
  final bool shareConsent;

  const UserProductPhoto({
    required this.id,
    required this.productId,
    required this.photoPath,
    required this.registeredAt,
    this.shareConsent = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'photo_path': photoPath,
        'registered_at': registeredAt.toIso8601String(),
        'share_consent': shareConsent,
      };

  factory UserProductPhoto.fromJson(Map<String, dynamic> json) {
    return UserProductPhoto(
      id: (json['id'] as String?) ?? '',
      productId: (json['product_id'] as String?) ?? '',
      photoPath: (json['photo_path'] as String?) ?? '',
      registeredAt: DateTime.parse(json['registered_at'] as String),
      // legacy payload (share_consent 누락) → false 폴백
      shareConsent: (json['share_consent'] as bool?) ?? false,
    );
  }

  UserProductPhoto copyWith({
    String? photoPath,
    bool? shareConsent,
  }) =>
      UserProductPhoto(
        id: id,
        productId: productId,
        photoPath: photoPath ?? this.photoPath,
        registeredAt: registeredAt,
        shareConsent: shareConsent ?? this.shareConsent,
      );

  /// 직렬화/역직렬화 도우미 — SecureStorage가 String만 받으므로 list 단위
  /// 인코딩에 사용.
  static String encodeList(List<UserProductPhoto> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<UserProductPhoto> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    final dynamic parsed;
    try {
      parsed = jsonDecode(raw);
    } on FormatException {
      // 깨진 JSON / 평문 입력 — 안전하게 빈 리스트로 폴백.
      return const [];
    }
    if (parsed is! List) return const [];
    return parsed
        .whereType<Map<String, dynamic>>()
        .map(UserProductPhoto.fromJson)
        .toList(growable: false);
  }
}
