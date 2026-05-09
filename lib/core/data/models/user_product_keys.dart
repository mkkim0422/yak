/// 큐레이션 Product에 매핑된 사용자 데이터 (사진/후기) 의 SecureStorage
/// 키 스키마. V1엔 모델/직렬화·키 상수만 정의되며, 실 repository는 V1.x
/// (단계 10 Supabase 인터페이스)에서 활성화.
///
/// 키 형태:
///   `cloud.user_product_photos.{productId}`   → JSON list of UserProductPhoto
///   `cloud.user_product_photos.index`         → JSON list of productIds
///   `cloud.user_product_reviews.{productId}`  → JSON list of UserProductReview
///   `cloud.user_product_reviews.index`        → JSON list of productIds
///
/// per-product 그루핑으로 카드/상세 진입 시 O(1) lookup. V1엔 SecureStorage
/// (AES-256-GCM)에 평문 JSON으로 저장될 예정 — 사진 파일 자체는 별도
/// `<appDocs>/products/`에 jpg로 저장되고 본 키는 경로만 참조.
class UserProductKeys {
  UserProductKeys._();

  static const String _photosPrefix = 'cloud.user_product_photos.';
  static const String _reviewsPrefix = 'cloud.user_product_reviews.';

  /// 특정 productId의 사용자 사진 JSON 리스트 키.
  static String photosFor(String productId) => '$_photosPrefix$productId';

  /// 사용자 사진을 보유한 productId 목록 인덱스 키.
  static const String photosIndex = '${_photosPrefix}index';

  /// 특정 productId의 사용자 후기 JSON 리스트 키.
  static String reviewsFor(String productId) => '$_reviewsPrefix$productId';

  /// 사용자 후기를 보유한 productId 목록 인덱스 키.
  static const String reviewsIndex = '${_reviewsPrefix}index';
}
