// Analytics + Crashlytics 단일 진입점 — V1.0은 no-op 구현으로 외부 전송이
// 발생하지 않습니다. V2에서 firebase_analytics / firebase_crashlytics 패키지를
// 추가하면 본 인터페이스 그대로 두고 구현체만 교체합니다.
//
// 외부 작업 (선장님 측에서 처리 필요):
//   1. Firebase Console 프로젝트 생성 + Android 앱 등록 (SHA-1 등록)
//   2. google-services.json 다운로드 → android/app/ 배치
//   3. android/build.gradle / android/app/build.gradle에 google-services
//      플러그인 추가
//   4. pubspec.yaml에 firebase_core / firebase_analytics /
//      firebase_crashlytics 추가
//   5. main.dart에서 Firebase.initializeApp() 호출
//   6. 본 파일의 _NoopAnalyticsImpl을 _FirebaseAnalyticsImpl로 교체
//
// 본 인터페이스는 사용자 입력에 PII가 포함될 수 있으므로 모든 이벤트
// payload는 이미 익명화된 메타(연령대 / 가족 구성 / 영양제 카테고리)만
// 받습니다. 이름·생년월일·메모 등은 본 호출에서 의도적으로 누락됩니다.

library;

/// Analytics 이벤트 정식 이름 — 데이터 일관성을 위해 상수화.
class AnalyticsEvents {
  AnalyticsEvents._();

  static const String appOpen = 'app_open';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String familyAdded = 'family_added';
  static const String familyEdited = 'family_edited';
  static const String familyDeleted = 'family_deleted';
  static const String supplementAddedSearch = 'supplement_added_search';
  static const String supplementAddedManual = 'supplement_added_manual';
  static const String recommendationViewed = 'recommendation_viewed';
  static const String categoryDetailOpened = 'category_detail_opened';
  static const String productDetailOpened = 'product_detail_opened';
  static const String productClicked = 'product_clicked';
  static const String externalShopOpened = 'external_shop_opened';
  static const String conflictDetected = 'conflict_detected';
  static const String dataExported = 'data_exported';
  static const String dataWiped = 'data_wiped';
}

/// 익명화된 사용자 속성 — UID·이름·생년월일 같은 PII는 절대 설정하지
/// 않습니다. 연령대(20s/30s/...) / 가족 크기 / 보유 페르소나 카테고리만.
class AnalyticsUserAttributes {
  AnalyticsUserAttributes._();

  static const String ageBand = 'age_band';
  static const String familySize = 'family_size';
  static const String hasKids = 'has_kids';
  static const String hasPregnant = 'has_pregnant';
  static const String hasSenior = 'has_senior';
}

/// Analytics + Crashlytics 통합 인터페이스. V1은 [_NoopAnalyticsImpl] 사용.
abstract class AnalyticsService {
  bool get isConfigured;

  /// 익명 이벤트 기록. payload는 string/num/bool만 (PII 절대 X).
  Future<void> logEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  });

  /// 사용자 속성 — 익명화된 그룹 라벨만.
  Future<void> setUserProperty(String name, String? value);

  /// 크래시 / 비치명적 오류 보고. 사용자 입력은 sanitize 후 전송.
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  });

  /// 사용자가 데이터 삭제를 요청하면 Analytics / Crashlytics 사용자 데이터도
  /// 함께 삭제. V1은 no-op (저장된 데이터 X).
  Future<void> deleteUserData();
}

/// V1.0 default — 외부 전송 0건. 모든 호출이 즉시 반환됩니다.
class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  bool get isConfigured => false;

  @override
  Future<void> logEvent(String name,
      {Map<String, Object?> parameters = const {}}) async {}

  @override
  Future<void> setUserProperty(String name, String? value) async {}

  @override
  Future<void> recordError(Object error, StackTrace? stack,
      {String? reason, bool fatal = false}) async {}

  @override
  Future<void> deleteUserData() async {}
}

/// 글로벌 단일 인스턴스. main.dart에서 V2 도입 시 교체.
AnalyticsService kAnalytics = const NoopAnalyticsService();
