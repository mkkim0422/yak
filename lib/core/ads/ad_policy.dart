import '../../features/family/models/family_member.dart';

/// 광고 노출 정책 — Google AdMob 도입(V2) 시 본 룰셋이 단일 진입점.
///
/// V1.0 정책:
///   * 광고 미노출 (AdMob 미통합).
///   * 인터페이스만 정의해 V2 통합 시 화면 측 수정 0.
///
/// V2 정책 (예정):
///   * 키즈 / 임산부 / 수유부 화면 = 광고 노출 X (안전 / COPPA / 의료 안전)
///   * 영양제 상세 = 광고 X (정보 신뢰성)
///   * 홈 / 멤버 (성인) / 카테고리 / 검색 결과 = 배너 OK
///   * 영양제 추가 후 3-5회마다 = 전면 (V2 단계적)
///   * "광고" 라벨 명시 (공정거래법)
class AdPolicy {
  AdPolicy._();

  /// 본 멤버에게 광고 노출이 허용되는지 — 만 14세 미만(어린이) /
  /// 임신부 / 수유부는 안전·COPPA·민감 카테고리 사유로 차단.
  static bool isAdAllowedForMember(FamilyMember member) {
    if (member.age < 14) return false; // 어린이 — COPPA 안전
    if (member.isPregnant) return false; // 임산부 — 의료 안전
    if (member.isBreastfeeding) return false; // 수유부 — 의료 안전
    return true;
  }

  /// 화면별 광고 허용 여부.
  static bool isAdAllowedOnSurface(AdSurface surface) {
    switch (surface) {
      case AdSurface.home:
      case AdSurface.memberAdult:
      case AdSurface.categoryList:
      case AdSurface.searchResults:
        return true;
      case AdSurface.memberKid:
      case AdSurface.memberPregnant:
      case AdSurface.productDetail:
      case AdSurface.onboarding:
      case AdSurface.privacyConsent:
      case AdSurface.terms:
      case AdSurface.privacyPolicy:
      case AdSurface.disclaimer:
        return false;
    }
  }
}

/// 광고 노출 가능한 화면 식별자. 호출자(화면 widget)는 본 enum과 함께
/// AdPolicy를 호출해 광고 표시 여부를 판단.
enum AdSurface {
  home,
  memberAdult,
  memberKid,
  memberPregnant,
  productDetail,
  categoryList,
  searchResults,
  onboarding,
  privacyConsent,
  terms,
  privacyPolicy,
  disclaimer,
}

/// 광고 위젯 인터페이스 — V2에서 google_mobile_ads 통합 시 [BannerAdView]
/// 같은 실 구현으로 교체. V1은 [NoopAdSlot] 사용 → 빈 SizedBox.
abstract class AdSlot {
  /// 본 슬롯이 활성화돼 있는지 (AdMob 통합 + 정책 통과).
  bool get isActive;
}

/// V1 default — 광고 슬롯이 모든 화면에서 비활성. AdSlot.isActive를 보고
/// 화면 측에서 SizedBox.shrink()로 폴백할 수 있습니다.
class NoopAdSlot implements AdSlot {
  const NoopAdSlot();
  @override
  bool get isActive => false;
}

const AdSlot kBannerAd = NoopAdSlot();
const AdSlot kInterstitialAd = NoopAdSlot();
