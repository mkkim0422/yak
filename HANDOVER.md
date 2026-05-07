# 알약(Alyak) — Claude AI 인수인계서 (완본)

**작성일**: 2026-05-07
**프로젝트 경로**: `C:\Users\User\OneDrive\바탕 화면\회사\00.연습\yak`
**현재 브랜치**: `main` (clean)
**총 커밋 수**: 92
**프로젝트 단계**: V1.0 출시 직전 (외부 의존 제외 코드 완료 / 테스트 300/300 통과)
**연락처**: help@sphinfo.co.kr
**Android 패키지명**: `kr.co.sphinfo.alyak.alyak`
**버전**: 1.0.0+1

> 새 Claude 채팅 시작 시 이 문서를 첫 메시지에 그대로 붙여넣어 공유. 모든 결정 배경 / 작업 내역 / 코드 구조 / 컨벤션 / 남은 작업이 단일 파일에 정리돼 있어 파일을 다시 열지 않고도 90% 이상 파악 가능.

---

# 목차

- [PART 1. 프로젝트 빠른 개요](#part-1-프로젝트-빠른-개요)
- [PART 2. 도메인 핵심 (KDRIs / 4단계 평가 / 추천 / 충돌 / 카테고리 / 모델)](#part-2-도메인-핵심)
- [PART 3. UI 화면 & 위젯](#part-3-ui-화면--위젯)
- [PART 4. 인프라 (테마 / 보안 / 알림 / 서비스 / 라우팅 / Android)](#part-4-인프라)
- [PART 5. 데이터 자산 (products.json 등)](#part-5-데이터-자산)
- [PART 6. 테스트 / 스크립트 / 디자인](#part-6-테스트--스크립트--디자인)
- [PART 7. 92개 커밋 히스토리 (단계별 WHY/WHAT/RESULT)](#part-7-92개-커밋-히스토리)
- [PART 8. 출시 체크리스트 / 남은 작업](#part-8-출시-체크리스트--남은-작업)
- [PART 9. 컨벤션 / 트랩 / 작업 시 주의사항](#part-9-컨벤션--트랩)
- [PART 10. 새 Claude에게 전달 팁](#part-10-새-claude에게-전달-팁)

---

# PART 1. 프로젝트 빠른 개요

## 한 줄 정의

**알약(Alyak)** = Flutter 기반 한국 가족 영양제 관리 앱.

- **타깃 사용자**: 30-40대 엄마 (가족 구성원의 영양제를 한 화면에서 케어)
- **모토**: "30-40대 엄마가 화면을 보고 1초 안에 이해할 수 있어야 한다."
- **차별점**: 2025 한국인 영양소 섭취기준(KDRIs) 기반 + 가족 구성원별 맞춤 + 영양제 250종 큐레이션 + 사진 250장 100% 커버리지
- **출시 형태**: V1.0 = 외부 서버 0개(Firebase / AdMob 미통합), 모든 데이터 기기 내 SecureStorage(AES-256-GCM)

## 기술 스택

| 영역 | 선택 |
|---|---|
| Framework | Flutter (SDK ^3.11.4) |
| 언어 | Dart |
| State | `flutter_riverpod` ^2.6.1 |
| Routing | `go_router` ^14.6.2 |
| Storage | `flutter_secure_storage` ^9.2.2 + `encrypt` ^5.0.3 (AES-256-GCM) |
| 알림 | `flutter_local_notifications` ^18.0.1 + `flutter_timezone` ^4.1.0 + `timezone` ^0.10.0 |
| 이미지 | `image_picker` ^1.1.2 (프로필 사진), 250개 제품 사진 → `assets/images/products/` |
| 외부 링크 | `url_launcher` ^6.3.1 (네이버쇼핑 / 쿠팡) |
| 기타 | `intl` ^0.20.1, `shared_preferences` ^2.3.4, `path_provider` ^2.1.5, `collection` ^1.19.0, `http` ^1.2.2, `crypto` ^3.0.6, `cupertino_icons` ^1.0.8 |
| Lints | `flutter_lints` ^6.0.0 |
| OS | Windows 11, PowerShell |
| 타깃 OS | Android (V1 우선), iOS (V1.x 검증) |
| Android | namespace `kr.co.sphinfo.alyak.alyak`, JVM 17, MultiDex, isCoreLibraryDesugaringEnabled=true |

> ⚠️ Firebase / AdMob / share_plus 등 V2 도입 예정 패키지는 **현 단계에서 추가 X**. 인터페이스(no-op)만 정의. `lib/core/firebase/firebase_integration_plan.md`에 V2 외부 작업 절차 정리됨.

## 폴더 트리

```
lib/
├── main.dart                   (3개 서비스 init: Encryption / Notification / Product)
├── app/
│   ├── app.dart                (MaterialApp.router + SecureAppShell)
│   └── router.dart             (GoRouter — _decideBootRoute 부팅 분기)
├── core/
│   ├── ads/ad_policy.dart      (V1 no-op, 키즈/임신부 광고 차단 정책 정의)
│   ├── analytics/analytics_service.dart (V1 NoopAnalyticsService)
│   ├── api/claude_api.dart     (V1 미사용 — 향후 AI 코멘트용)
│   ├── config/                 (env_config / region_config / shop_config)
│   ├── data/
│   │   ├── kdris_2025.dart     ⭐ 2025 KDRIs 권장량/UL 매트릭스 (24종 × 13구간 × 성별)
│   │   ├── nutrient_evaluation.dart  ⭐ 4단계 평가
│   │   ├── nutrient_labels.dart      ⭐ products.json 키 → 한글 라벨
│   │   ├── product_category_meta.dart (47개 카테고리 → 라벨/효능/주의사항)
│   │   ├── product_repository.dart   (assets/data/products.json 로더)
│   │   ├── supplement_repository.dart
│   │   └── models/             (product_model / family_input / recommendation_* / conflict_warning / schedule_result / supplement_guide / symptom_result)
│   ├── firebase/firebase_integration_plan.md  ⭐ V2 외부 작업 절차서
│   ├── l10n/app_strings.dart   (모든 한글 문구 단일화)
│   ├── legal/legal_documents.dart  (개인정보 처리방침 / 이용약관 / 면책)
│   ├── notifications/          (NotificationService — 매일/리오더/검진 3종)
│   ├── security/               (encryption_service / secure_storage / session_guard / screen_security / root_detection)
│   ├── services/
│   │   ├── conflict_checker.dart      ⭐ 충돌 검사 (severity 3단계, 5종)
│   │   ├── data_export_service.dart   (JSON 백업 — schemaVersion=1)
│   │   ├── manual_entry_hash.dart
│   │   ├── nutrient_recommender.dart  ⭐ 판매량/가성비/종합추천 3티어
│   │   ├── product_search_links.dart  (네이버쇼핑/쿠팡 + dead-source 필터)
│   │   ├── product_targeting.dart     (페르소나 키워드 추론)
│   │   └── profile_photo_service.dart
│   ├── theme/                  (app_colors/radius/shadows/spacing/theme/typography)
│   └── widgets/                (alyak_buttons/card/chip / chat_bubbles / conflict_section / coverage_bar / disclaimer_footer / entry_row / member_picker_sheet / product_image / product_photo / profile_avatar / section_header / state_views / status_pill / step_indicator / app_icon_painter / avatar_badge)
└── features/
    ├── current_check/screens/  (현재 영양제 점검)
    ├── family/
    │   ├── models/family_member.dart  (Relationship/Sex/AgeGroup/SmokingStatus/DrinkingFrequency/DietQuality/SleepHours/StressLevel/ManualProductEntry/FamilyMember)
    │   ├── providers/family_provider.dart  (Riverpod)
    │   ├── services/intake_grouping.dart   (시간대 그룹)
    │   └── screens/            (8개: member_detail / family_edit / family_management / family_products / category_detail / recommendation_detail / supplement_search / manual_supplement_input)
    ├── home/
    │   ├── data/ai_comment_service.dart
    │   ├── providers/member_analysis_provider.dart  (캐싱)
    │   ├── widgets/            (family_cards_section / family_member_card / nutrient_status_widgets)
    │   └── screens/home_screen.dart
    ├── onboarding/
    │   ├── widgets/chat_message.dart
    │   └── screens/            (privacy_consent / onboarding(4슬라이드) / welcome / family_add(18단계 채팅) / notification_setup)
    ├── settings/screens/settings_screen.dart
    ├── supplements/screens/    (product_detail / supplement_guide)
    └── symptom/screens/symptom_search_screen.dart
```

## 데이터 자산

| 파일 | 라인 | 항목 수 | 용도 |
|---|---|---|---|
| `assets/data/products.json` | 8,058 | 250개 제품 | 큐레이션 영양제 DB (id/name/brand/category/ingredients/dailyDose/intakes/intake_timing/dose_per_intake/popularity_rank 등) |
| `assets/data/supplement_guide.json` | 3,540 | ~40개 영양소 | 영양소별 효능/조합/약물상호작용/식품대안 |
| `assets/data/age_group_recommendations.json` | 404 | 18개 페르소나 | 연령/성별/임신/수유/채식 등 페르소나 권장 |
| `assets/data/combination_optimizer.json` | 126 | 9 separation + 13 synergy | 조합 최적화 |
| `assets/data/symptom_guide.json` | 608 | 50개 증상 | 증상 → 영양소 매핑 |
| `assets/images/products/` | — | 250장 JPG | 240×240 q80, ~2.6MB |

---

# PART 2. 도메인 핵심

## 2-1. KDRIs 2025 매트릭스 (`lib/core/data/kdris_2025.dart`)

**출처**: 한국영양학회 / 보건복지부 발표 (2025-12-31), 정오표(2026.02-03) 반영.

### 13구간 연령 enum

```dart
enum KAgeBracket {
  infant0to5,     // 0-5개월
  infant6to11,    // 6-11개월
  child1to2, child3to5, child6to8, child9to11,
  teen12to14, teen15to18,
  adult19to29, adult30to49, adult50to64,
  elderly65to74, elderly75plus,
}
```

### `bracketForAge(int age) → KAgeBracket`

만 나이 → 13구간. **V1 한계**: 만 0세는 모두 `infant0to5`로 단일화 (출생월 미수집). 6-11개월 영아의 권장량(예: 철 6mg)이 0-5개월 값(철 0.3mg)으로 비교돼 영양제 추천이 보수적. 채팅 step 5 의학 면책으로 소아과 우선 안내. → **V1.1에서 출생월 입력 추가 시 해결.**

### `NutrientReference` 클래스

```dart
class NutrientReference {
  final String name;                                   // 한글명 ("비타민D")
  final String unit;                                   // 단위 (IU, mg, mcg, 억CFU, g)
  final Map<(KAgeBracket, bool), double> matrix;       // (bracket, isMale) → RDA/AI
  final double? pregnancyAdd;                          // 임신 가산
  final double? lactationAdd;                          // 수유 가산
  final double? upperLimit;                            // UL
  final double? cdrr;                                  // 만성질환 위험감소 섭취량
  final String? note;
}
```

핵심 메서드: `recommendedFor(age, isMale, isPregnant, isLactating) → double`
- 매트릭스 조회 → 동일 성별 인접 구간 폴백(영아/소아만) → 임신/수유 누적

### 정의된 24종 영양소

| 키 (products.json) | 한글명 | 단위 | RDA 예시 (성인 19-29) | UL | 임신/수유 |
|---|---|---|---|---|---|
| `vitamin_d_iu` | 비타민D | IU | 400 / 65+ 600 | 4000 | — |
| `vitamin_c_mg` | 비타민C | mg | 100 | 2000 | +10 / +35 |
| `vitamin_b9_mcg` | 엽산 | mcg DFE | 400 | 1000 | +220 / +150 |
| `vitamin_b12_mcg` | 비타민B12 | mcg | 2.4 | — | +0.2 / +0.4 |
| `calcium_mg` | 칼슘 | mg | 700-800 | 2500 | — |
| `iron_mg` | 철분 | mg | 여 14, 남 10 | 45 | +10 / — |
| `magnesium_mg` | 마그네슘 | mg | 280-370 | 350 (보충제만) | +40 / — |
| `zinc_mg` | 아연 | mg | 8-10 | 35 | +2.5 / +5 |
| `omega3_total_mg` | 오메가3 | mg | 1000 | — | +200 |
| `probiotics_billion_cfu` | 유산균 | 억CFU | 10 (권고) | — | — |
| `coenzyme_q10_mg` | 코엔자임Q10 | mg | 100 (보충) | — | — |
| `choline_mg` | 콜린 | mg | 425-550 | 3500 | +25 / +125 (**2025 신규**) |
| `vitamin_a_mcg` | 비타민A | mcg RAE | — | 3000 | +70 / +490 |
| `vitamin_e_mg` | 비타민E | mg α-TE | 12 | 540 | — / +3 |
| `vitamin_b6_mg` | 비타민B6 | mg | 1.4-1.5 | 100 | +0.8 / +0.8 |
| `vitamin_b3_mg` | 나이아신 | mg NE | 14-16 | 35 | +4 / +3 |
| `vitamin_b1_mg` | 비타민B1 | mg | 1.1-1.2 | — | +0.4 / +0.4 |
| `vitamin_b2_mg` | 비타민B2 | mg | 1.2-1.5 | — | +0.4 / +0.5 |
| `vitamin_b5_mg` | 판토텐산 | mg (AI) | 5 | — | +1 / +2 |
| `biotin_mcg` | 비오틴 | mcg (AI) | 30 | — | — / +5 |
| `vitamin_k_mcg` | 비타민K | mcg (AI) | 65-75 | — | — |
| `selenium_mcg` | 셀레늄 | mcg | 60 | 400 | +4 / +10 |
| `iodine_mcg` | 요오드 | mcg | 150 | 2400 | +90 / +190 |
| `copper_mg` | 구리 | mg | 0.80-0.85 | 10 | +0.13 / +0.48 |
| `manganese_mg` | 망간 | mg (AI) | 3.5-4.0 | 11 | — |

### 진입점 함수

```dart
double? recommendedKDRIs2025({
  required String nutrient,    // 'vitamin_d_iu' 등
  required int age,
  required bool isMale,
  bool isPregnant = false,
  bool isLactating = false,
});  // 키 미존재 또는 0 이하 → null

double? upperLimitKDRIs2025(String nutrient);
String? nameKDRIs2025(String nutrient);
```

### 키 정규화 (중요!)

- `niacin_mg` (legacy) ↔ `vitamin_b3_mg` (products.json 표준)
- `vitamin_d_mcg` (legacy) ↔ `vitamin_d_iu` (KDRIs 기본)
- `copper_mcg` (legacy) ↔ `copper_mg` (products.json 표준)
- `niacin_mg` 키는 `conflict_checker`의 alias UL lookup에만 보존

---

## 2-2. 4단계 영양 평가 (`lib/core/data/nutrient_evaluation.dart`)

이전 `999%`, `250%` 같은 충격 % 표시 → **4단계 라벨**로 전면 교체.

### 분기 로직

```
1. UL 초과              → excessive    "⚠️ 60 mg 많아요"   (빨강)
2. 권장량 정보 없음     → unknown      "ℹ️ 정보 없음"      (회색)
3. 권장량 90% 이상     → sufficient   "✅ 충분해요"        (초록/청록)
4. 권장량 90% 미만     → insufficient "⚠️ 450 mg 부족해요" (주황)
```

### 핵심 상수

```dart
const double kSufficientMargin = 0.9;
// 사용자 피드백 "철분 13.5/14 = 거의 다" → 10% 마진
```

### enum & 클래스

```dart
enum NutrientStatus { sufficient, insufficient, excessive, unknown }

class NutrientEvaluation {
  final NutrientStatus status;
  final double? deficit;   // insufficient일 때만: RDA - amount
  final double? excess;    // excessive일 때만: amount - UL
}
```

### 평가 함수

```dart
NutrientEvaluation evaluateNutrient({
  required double amount,
  required double? recommended,
  required double? upperLimit,
})
```

분기 순서: **UL 초과 → unknown → margin → insufficient**.

### 라벨 생성 규칙

```dart
String statusLabelFor(NutrientEvaluation eval, String unit)
```

- 단위 단순화: `α-TE` 제거, `RAE` 제거, `NE` 제거, `DFE` 제거
- 숫자 포맷:
  - ≥100 또는 정수 → 소수점 없음
  - 10-99 → 소수점 1자리
  - <10 → 소수점 2자리

```dart
String simplifyUnit(String unit)
// 'mg α-TE' → 'mg'
// 'mcg RAE' → 'mcg'
// 'mg NE' → 'mg'
// 'mcg DFE' → 'mcg'

String formatAmount(double amount)
```

---

## 2-3. 영양제 추천 3티어 (`lib/core/services/nutrient_recommender.dart`)

각 부족 영양소당 최대 3개 제품 추천 — **판매량 / 가성비 / 종합추천**.

### 티어 상수

```dart
const String kTierBestseller = '판매량';
const String kTierValue = '가성비';
const String kTierComprehensive = '종합추천';
```

### 점수 상수

```dart
const double kComprehensiveMinScore = 0.7;     // 결핍 70% 이상 커버
const double kComprehensiveMultiBonus = 0.15;  // 멀티 카테고리 +15%
const double kValueAmountTolerance = 0.30;     // 함량 ±30% (V1.0에서 0.20→0.30 완화)
const int kValueMinPopularityRank = 6;         // 가성비는 6위 이하만
```

### 카테고리 포커스 점수

```dart
int _categoryFocusScore(Product p, String mainNutrient)
// 메인 영양소 함량 = 0 → 0점
// 성분 1-3개  → 100점 (단일/주력)
// 성분 4-5개  → 70점
// 성분 8개+   → 30점 (종합비타민)
```

> 판매량/가성비에만 적용, 종합추천에는 비적용 (멀티가 본질적으로 더 적합).

### 3티어 선택 로직

**후보 풀**:
- **tight**: hard filter (메인 영양소 함유 + 카테고리 정합 + 성분 ≤2개) — 판매량/가성비용
- **broad**: 메인 성분만 함유 — 종합추천용

**선택 순서**:

1. **판매량** — tight pool에서 `popularity + targetScore + focusScore` 최고. tight 비면 표시 X.
2. **가성비** — tight pool에서 bestseller 제외 + 함량 ±30% + popularity_rank ≥ 6 + focus ≥ 30. **다른 브랜드 우선** (동일 브랜드 폴백). 조건 불만족 → null.
3. **종합추천** — broad pool에서 deficitNutrients 70%+ 커버 + 멀티 +15% 보너스. deficit 비면 skip.

### 클래스

```dart
class NutrientRecommendation {
  final String nutrient;
  final String displayName;
  final double recommendedAmount;
  final String unit;
  final List<RankedProduct> picks;  // 최대 3
}

class RankedProduct {
  final String tier;        // '판매량'/'가성비'/'종합추천'
  final Product product;
}
```

### 진입점

```dart
List<NutrientRecommendation> recommend({
  required FamilyMember member,
  required List<({String key, String displayName, double recommended, String unit})> nutrients,
  List<String> deficitNutrients = const [],   // 종합추천용
  int picksPerNutrient = 3,
})
```

---

## 2-4. 충돌 검사 (`lib/core/services/conflict_checker.dart`)

### Severity 3단계

| level | 색 | 용도 |
|---|---|---|
| `info` | 회색 "참고" | 2시간 분리 권장 / 시간대 누적 |
| `warning` | 주황 "주의" | 권장량 초과 / 임신·수유 시 함량 확인 |
| `danger` | 빨강 | 의학적 위험 (임신 + 비타민A 과다) |

### `ConflictItem`

```dart
class ConflictItem {
  final ConflictSeverity severity;
  final String emoji;
  final String title;
  final String message;
  final List<String> sourceProductNames;  // 어떤 제품들이 문제인지
}
```

### 진입점

```dart
static List<ConflictItem> check({
  required FamilyMember member,
  required List<Product> products,
  required List<ManualProductEntry> manuals,
  Product? candidateProduct,        // 신규 추가 시뮬레이션용
  ManualProductEntry? candidateManual,
})
```

### 5가지 충돌 규칙

#### 1. UL 초과 (Overdose)
- 임계: 영양소별 UL
- **멀티비타민 단독은 면제**: 종합비타민이 8개 이상 성분 또는 `multivitamin`/`prenatal`/`kids_multivitamin` 카테고리이면, 다른 제품과의 누적이 없으면 경고 안 함. → "한 통이 안전 함량 내에서 설계됐기 때문"
- 메시지: "합산 {amount}{unit} (안전 상한 {ul}{unit})"
- alias UL lookup:
```dart
const _kKDRIsAliasUls = {
  'vitamin_a_iu': 10000,
  'vitamin_d_mcg': 100,
  'vitamin_d3_iu': 4000,
  'folate_mcg': 1000,
  'caffeine_mg': 400,
  // ...
};
```

#### 2. 흡수 간섭 (Absorption Conflict)
같은 시간대 섭취 시:
- 칼슘 + 철분: "2시간 분리 권장"
- 칼슘 + 마그네슘: "가능하면 분리 복용"
- 비타민C + B12: "비타민C가 B12를 분해할 수 있어요"

#### 3. 타이밍 누적 (Pile-up)
- 같은 시간대 5개 이상 → "한 번에 N개 영양제"

#### 4. 약물 상호작용
- Phase 2 예약. 구조만 존재.

#### 5. 임신/수유 특화
```dart
const _kPregnantRules = [
  // 비타민A 합산 ≥ 3000 mcg → danger
  // 비타민D 합산 ≥ 4000 IU → warning
  // 카페인 ≥ 200 mg → warning
];
const _kLactatingRules = [
  // 비타민B6 ≥ 100 mg → warning
];
```

---

## 2-5. 카테고리 메타 (`lib/core/data/product_category_meta.dart`)

47개 카테고리 정적 정의. 제품 상세 화면이 동적 JSON 조회 없이 정적 렌더.

```dart
class ProductCategoryMeta {
  final String label;       // "오메가-3"
  final String benefit;     // 효능 텍스트
  final List<String> cautions;  // 주의사항 (없으면 경고 섹션 X)
}
```

**주요 카테고리**:
- `multivitamin` 종합비타민 / `omega3` 오메가-3 (항응고제) / `krill_oil` 크릴오일 (갑각류 알레르기)
- `vitamin_d` 비타민D (신장/부갑상선) / `vitamin_c` 비타민C (1g 이상 신장결석) / `vitamin_b` / `biotin`
- `probiotic`/`probiotics` 유산균 / `fiber` 식이섬유 (충분한 물)
- `calcium` 칼슘 (갑상선약·철분제와 2시간 간격) / `magnesium` (고용량 설사) / `iron` (공복 흡수, 위장자극 시 식후)
- `mineral`, `lutein`, `eye`, `antioxidant`, `collagen`, `joint`, `liver`
- `sleep` (운전 금지) / `immune`/`immunity` / `circulation` (항응고제)
- `menopause_female`, `menopause_male`, `women_health`, `men_health`
- `pregnancy`/`prenatal` (**산부인과 의사 상의 필수**)
- `kids`, `kids_multivitamin`, `kids_omega3`, `kids_vitamin_d`, `kids_korean_herbal` (한의사 상의)
- `korean_herbal` (임산부 한의사) / `ginseng` (고혈압·자가면역)
- `sports`, `weight` (식단·운동 병행), `superfood`

**폴백**: 알려지지 않은 카테고리 → `{ label: '영양제', benefit: '제품 라벨에 표시된 효능을 확인해주세요', cautions: [] }`

```dart
ProductCategoryMeta categoryMeta(String category) → _kCategoryMeta[category] ?? _kFallback;
```

---

## 2-6. 한글 라벨 매핑 (`lib/core/data/nutrient_labels.dart`)

products.json snake_case 키 → 한글. 단위 suffix 자동 strip.

### 함수

```dart
(String base, String unit) splitNutrientKey(String key)
// 'vitamin_d_iu' → ('vitamin_d', 'IU')
// 'calcium_mg' → ('calcium', 'mg')
// 'probiotics_billion_cfu' → ('probiotics', '억CFU')

String nutrientLabel(String key)
// 'vitamin_d_iu' → '비타민D'
// 'unknown_xyz' → 'Unknown Xyz' (humanize 폴백)

String formatIngredientLine(String key, double amount)
// ('vitamin_d_iu', 400) → '비타민D 400IU'
```

### 매핑 그룹 (총 89종 매핑)

- **비타민** 15: `vitamin_a/b1-b7/b9/b12/c/d/d3/e/k/k1/k2/choline` + 별칭(`niacin`, `pantothenic_acid`, `biotin`, `folate`, `folic_acid`)
- **미네랄** 12: `calcium/iron/magnesium/zinc/selenium/iodine/copper/manganese/chromium/molybdenum/potassium/phosphorus`
- **오메가3·지방산** 5: `omega3_total/omega3/omega3_epa/epa/omega3_dha/dha/ala`
- **항산화·기능성** 10: `coenzyme_q10/coq10/lutein/zeaxanthin/astaxanthin/resveratrol/curcumin/milk_thistle/silymarin/lycopene`
- **유산균·소화** 2: `probiotics/fiber`
- **관절** 4: `glucosamine/chondroitin/msm/collagen/collagen_peptide`
- **한약·식물** 8: `red_ginseng/ginseng/ginsenoside/ginkgo_biloba/ginkgo/saw_palmetto/ashwagandha/boswellia/cranberry/propolis`
- **아미노산·스포츠** 16: `taurine/arginine/l_arginine/theanine/l_theanine/glutamine/l_glutamine/creatine/protein/whey_protein/bcaa/eaa/aakg/beta_alanine/citrulline/l_carnitine/carnitine`
- **수면·자극** 3: `melatonin/caffeine/gaba`
- **기타** 14: `spirulina/chlorella/krill_oil/mct_oil/inositol/nac/_5htp/cla/gla/hca` + 카로티노이드/헛개나무/마카/옥타코사놀/피페린/헴철/플라보노이드/안토시아니딘 등

> `test/nutrient_labels_coverage_test.dart` — products.json의 모든 ingredient 키가 라벨 매핑됨을 검증. 33개 누락 사전 추가됨 (커밋 77dacc8).

---

## 2-7. FamilyMember 모델 (`lib/features/family/models/family_member.dart`)

### enums

```dart
enum Relationship { self, husband, wife, son, daughter, father, mother, other }
// .label → '본인' / '남편' / '아내' / '아들' / '딸' / '아빠' / '엄마' / '가족'

enum Sex { male, female }                 // .label → '남' / '여'
enum AgeGroup { newborn, toddler, child, teen, adult, middleAged, elderly }
enum SmokingStatus { never, former, current }      // V1.1: 채팅 미수집
enum DrinkingFrequency { never, weekly, daily }    // V1.1: 채팅 미수집
enum DietQuality { poor, average, good }           // 채팅은 good/poor만, average는 legacy
enum SleepHours { less5, fiveToSeven, sevenToNine, more9 }  // V1.1: 채팅 미수집
enum StressLevel { low, medium, high }              // V1.1: 채팅 미수집
```

### `ManualProductEntry`

```dart
class ManualProductEntry {
  final String id;
  final String name;
  final String? brand;
  final String category;
  final int dailyDose;                    // 1일 총정수 (1-999)
  final int packageSize;
  final int? priceKrw;
  final String? imagePath;
  final Map<String, double> ingredients;
  final DateTime startedAt;
  final IntakeTiming intakeTiming;
  final int dosePerIntake;                // 1회 정수
  final int intakesPerDay;                // 1일 횟수
  final String? intakeNote;
  // 불변식: dosePerIntake × intakesPerDay == dailyDose
}
```

`scheduleLabel` getter:
- 1회/일 → "🌅 오전 식사 후 1정"
- 2회/일 → "🌅 아침 1정 / 🌙 저녁 1정"
- 3회/일 → "🌅 아침 1정 / 🌞 점심 1정 / 🌙 저녁 1정"

### `FamilyMember`

```dart
class FamilyMember {
  final String id;                          // "fm_{microseconds}"
  final String name;
  final Relationship relationship;
  final int birthYear;                      // 영구 저장 (age 계산식)
  int get age => DateTime.now().year - birthYear;
  String get ageLabel => '만 $age세';

  final Sex sex;
  final double? heightCm;
  final double? weightKg;

  final SmokingStatus smokingStatus;
  final DrinkingFrequency drinkingFrequency;
  final DietQuality dietQuality;
  final SleepHours sleepHours;
  final StressLevel stressLevel;

  final List<String> allergies;
  final List<String> medications;
  final bool isPregnant;
  final bool isBreastfeeding;
  final String? bloodType;                  // 'A+', 'O-' 등 (정보용)
  final List<String> chronicConditions;    // "고혈압", "당뇨" 등

  final List<String> currentProductIds;    // 큐레이션 250개
  final List<ManualProductEntry> manualProducts;

  final DateTime? lastCheckupDate;
  final String? checkupNote;               // ≤200자

  final String? profileImagePath;          // JPEG 경로

  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### avatarEmoji 규칙

```
self → 👤
husband → 👨, wife → 👩
son: <13세 👦, ≥13세 🧑
daughter: <13세 👧, ≥13세 🧑
father: ≥65세 👴, <65세 👨
mother: ≥65세 👵, <65세 👩
other → 🙂
```

### JSON 마이그레이션

- legacy `age` 필드 → `birthYear = currentYear - age` (영구 저장형으로 변환)
- legacy `dietQuality: 'average'` → `'good'` 정규화

---

## 2-8. Product 모델 (`lib/core/data/models/product_model.dart`)

### `IntakeTiming`

```dart
enum IntakeTiming {
  morningEmpty,        // 🌅 오전 식사 전 (공복)
  morningAfter,        // 🌅 오전 식사 후
  lunchAfter,          // 🌞 점심 식사 후
  dinnerAfter,         // 🌙 저녁 식사 후
  beforeSleep,         // 🌙 취침 전
  anyTimeAfterMeal,    // 🍴 식후 (기본)
  withMeal,            // 🍴 식사 중
  multiple,            // ⏰ 1일 여러 회 분산
}

extension IntakeTimingX on IntakeTiming {
  String toJsonValue() => name;        // camelCase 그대로
  String get koreanLabel { ... }
}
```

### `Product`

```dart
class Product {
  final String id;
  final String name;
  final String brand;
  final ProductBrandType brandType;     // brand / generic / storeBrand
  final String category;
  final String unit;                    // 정/캡슐/포 등
  final int dailyDose;
  final int packageSize;
  final IntakeTiming intakeTiming;
  final int dosePerIntake;
  final int intakesPerDay;
  // 불변식: dosePerIntake × intakesPerDay == dailyDose

  final Map<String, double> ingredients;
  final Map<String, String> ingredientUnits;
  final List<String> goodFor;
  final List<String> alternatives;
  final String? notes;
  final int? popularityRank;            // 1-250
  final DateTime? lastUpdated;
  final String? dataSource;             // URL
  final String? intakeNote;             // 라벨 한 줄
  final String? imageUrl;

  String get imageAssetPath => 'assets/images/products/$id.jpg';
  String get scheduleLabel { ... }
}
```

### `ProductCombo` — 조합 추천

```dart
class ProductCombo {
  final List<Product> products;
  final Map<String, double> totalCoverage;
  final List<String> missingNutrients;
  final int productCount;
  final double averageCoverage;
}
```

---

## 2-9. 핵심 흐름도

### 영양소 평가
```
사용자 섭취 {vitamin_d_iu: 400, ...}
  → FamilyMember (age, sex, isPregnant)
  → 각 영양소: RDA = recommendedKDRIs2025(...), UL = upperLimitKDRIs2025(...)
  → evaluateNutrient(amount, RDA, UL) → NutrientStatus
  → statusLabelFor(eval, unit) → "✅ 충분해요" 등
```

### 충돌 감지
```
Products + Manuals → _IntakeRow[] (성분 × dailyDose)
  → 5규칙 순차: UL 초과(멀티 면제) → 흡수 간섭 → 타이밍 누적 → 약물(예약) → 임신/수유
  → ConflictItem[] (severity 내림차순)
```

### 추천
```
FamilyMember + 추천 영양소 목록
  → tight pool (hard filter) + broad pool
  → 판매량(tight 최고점) → 가성비(±30%, rank≥6, 다른 브랜드) → 종합추천(broad, ≥70% 커버)
  → NutrientRecommendation[] (RankedProduct 최대 3)
```

---

# PART 3. UI 화면 & 위젯

## 3-1. 라우트 전체 (`lib/app/router.dart`)

### 부팅 분기 (`_decideBootRoute`)

```
1. SessionGuard.isExpired() → SecureStorage.wipe() + /privacy-consent
2. privacyConsent != '1' → /privacy-consent
3. onboardingComplete != '1' → /onboarding
4. familyMembersList 비어있음 → /onboarding/welcome
5. SessionGuard.touch() → /home
```

### 라우트 표

| 경로 | 매개변수 | 화면 | 비고 |
|---|---|---|---|
| `/boot` | — | _BootScreen | 부팅 로딩 |
| `/privacy-consent` | — | PrivacyConsentScreen | 동의 |
| `/privacy-policy` | — | _PrivacyPolicyScreen | 처리방침 |
| `/disclaimer` | — | _DisclaimerScreen | 면책 |
| `/terms` | — | _TermsScreen | 약관 |
| `/onboarding` | `?from=settings` | OnboardingScreen | 4슬라이드 |
| `/onboarding/welcome` | — | WelcomeScreen | 본인/가족 선택 |
| `/onboarding/family-add` | `?relationship=` | FamilyAddScreen | **18단계 채팅** |
| `/onboarding/notification` | — | NotificationSetupScreen | 알림 설정 |
| `/home` | — | HomeScreen | 메인 |
| `/family/:id` | id | MemberDetailScreen | 멤버 상세 |
| `/family/:id/edit` | id | FamilyEditScreen | 멤버 편집 |
| `/family/:id/products` | id | FamilyProductsScreen | 멤버 영양제 |
| `/current-check/:memberId` | memberId | CurrentCheckScreen | 점검 |
| `/family-management` | — | FamilyManagementScreen | 가족 관리 |
| `/recommendation/:memberId` | memberId | RecommendationDetailScreen | 추천 |
| `/recommendation/:memberId/category/:category` | 둘 | CategoryDetailScreen | 카테고리 더보기 |
| `/supplement/search` | `?member=` | SupplementSearchScreen | 검색 |
| `/supplement/manual` | `?member=` | ManualSupplementInputScreen | 수동 입력 |
| `/supplement/manual/edit/:entryId` | entryId, `?member=` | ManualSupplementInputScreen | 수동 편집 |
| `/product/:productId` | productId, `?member=` | ProductDetailScreen | **member 있을 때 4단계 평가 렌더** |
| `/supplement-guide/:supplementId` | supplementId | SupplementGuideScreen | 가이드 |
| `/symptom-search` | — | SymptomSearchScreen | 증상 검색 |
| `/settings` | — | SettingsScreen | 설정 |

## 3-2. 홈 (`lib/features/home/screens/home_screen.dart`)

**구조** (위→아래):
1. **헤더** — "안녕하세요 👋" + "우리 가족 영양제" + 우상단 설정 종 아이콘
2. **가족 카드 섹션** (`FamilyCardsSection`) — 멤버 수에 따른 동적 레이아웃:
   - 1명: Large 풀폭
   - 2명: Compact 가로 2열
   - 3명: Large 1 + Compact 2 (하단)
   - 4명: 2×2 Compact 그리드
   - 5명+: 2×2 + 우측 미니 스크롤 (끝에 + 슬롯)
3. **+ 가족 추가하기** (멤버 있을 때, SecondaryButton)
4. **빈 가족 히어로** (`_EmptyFamilyHero`, 멤버 0)
5. **DisclaimerFooter**

**액션**:
- 카드 탭 → `/family/{id}`
- 카드 롱프레스 → 퀵액션 바텀시트 (추천/점검/편집/삭제)
- 설정 종 → `/settings`

## 3-3. 가족 카드 위젯 (`lib/features/home/widgets/`)

### `FamilyMemberCard` 변형 3가지

**Large** (1명, 또는 3명 중 최상단):
- 상단: 56px 아바타 + 이름 + 나이/성별/관계
- 구분선
- "💊 섭취중인 영양제 N개"
- "보충 필요 영양소" + 부족 영양소 2개 (+N개 더 ellipsis)

**Compact** (2명, 4명 그리드):
- 40px 아바타 + 이름 + 나이/성별
- "💊 N개 섭취중" + 우측 상태 점 (초록=영양제 보유, 회색=미보유)

**Mini** (5명+ 스크롤):
- 36px 아바타 → 이름 → 나이/성별 → "💊 N개" + 점

**상태 점 (`_StatusDot`)**:
- 단순 indicator: 영양제 보유 → 청록(`primary`), 미보유 → 매우 밝음(`faint`)
- ⚠️ 부족/주의는 카드에 표시하지 않음 (상세 진입 후만) — 톤다운 정책

### `nutrient_status_widgets.dart`

- **`NutrientPriorityCard`** — 부족 영양소 상위. 5개 이하 쉼표 구분, 5개 초과 "A, B, C 외 N개"
- **`NutrientCollapsibleSection`** — 펼침/접힘 섹션
- helpers: `formatNutrientList(names)`, `formatSecondaryLine()`, `formatSufficientLine()`

## 3-4. 온보딩 화면

### `privacy_consent_screen.dart`

- "시작하기 전에\n한 가지만 알려드릴게요"
- 메인: "가족 정보는 **이 폰에만** 저장돼요. 서버로 보내지 않아요."
- 3개 Promise 카드: 🔒 내 폰에만 저장 / 🚫 광고 없음 / 🩺 의료 행위 아님
- 체크박스 2개 (필수): ☑ 동의 + ☑ 만 14세 이상
- "네, 시작할게요" → `SecureStorage.write(privacyConsent, '1')` → `/onboarding/welcome`

### `onboarding_screen.dart` — 4슬라이드

1. 👨‍👩‍👧‍👦 파랑 — "우리 가족 영양제,\n한 번에 관리해요"
2. 💊 초록 — "검증된 250개 영양제"
3. 🔔 주황 — "결정 시점에만\n도와드려요"
4. ✨ 파랑 — "지금 시작해보세요" (CTA: "시작하기")

- PageView + 점 indicator (현재 24px primary, 나머지 8px hairline)
- 마지막 슬라이드 클릭 → `SecureStorage.write(onboardingComplete, '1')`
- `fromSettings=true` → `pop()`, false → `/boot`

### `welcome_screen.dart`

- 채팅 메시지 3개 (타이밍 200/800/600ms 딜레이)
  - "안녕하세요 👋"
  - "알약은 우리 가족이 어떤 영양제를 먹고 있는지, 어떤 영양소가 부족한지 알려드려요"
  - "어떻게 시작하실까요?"
- 600ms 후 fade-in 2개 타일:
  - 👤 "본인부터 등록할게요" (강조 보더)
  - 👨‍👩‍👧 "다른 가족부터요"
- 본인 → `/onboarding/family-add?relationship=self` (step 1 스킵)
- 가족 → `/onboarding/family-add` (step 1부터)

### `family_add_screen.dart` — **18단계 채팅 (가장 중요)**

**구조**:
- 앱바: 백 + StepIndicator("N/18") + 건너뛰기 (step<18 && step≠5)
- ListView: BotBubble (회색 왼쪽) + UserBubble (파란 오른쪽)
- 하단 `_StepInput` (단계별 다른 UI)

**18단계 상세**:

| 단계 | 질문 | 분기 (`_shouldShow`) | 비고 |
|---|---|---|---|
| 1 | 관계 (8택 그리드) | 항상 | preset=self면 스킵 |
| 2 | 이름 (텍스트) | 항상 | autocorrect:false, enableSuggestions:false |
| 3 | 출생연도 (4자리) | 항상 | helper: "올해는 YYYY년" |
| 4 | 성별 (남/여) | `_impliedSex(r) == null` | husband/wife/father/mother/son/daughter는 자동 |
| 5 | ⚠️ 의료 안내 | `age < 4` | "확인했어요" 단일 버튼, 자동 다음 |
| 6 | 키/몸무게 | 항상 | 공란 가능, decimal 허용 |
| 7 | 임신/수유 (4택) | `sex==female && 20≤age≤50` | 임신중/수유중/둘다/없음 |
| 8 | 혈액형 (8칩) | 항상 | "모름/건너뛰기" 가능 |
| 9 | (흡연) | **SKIP** (KDRIs 2025 정렬) | 필드 보존 |
| 10 | (음주) | **SKIP** (KDRIs 2025 정렬) | 필드 보존 |
| 11 | 식단 (균형/부족) | `age >= 4` | good/poor만 |
| 12 | (수면) | **SKIP** | |
| 13 | (스트레스) | **SKIP** | |
| 14 | 알레르기 (다중) | 항상 | 우유/갑각류/생선/대두/효모/땅콩/밀/기타 |
| 15 | 약 (다중) | `age >= 1` | 혈압/당뇨/고지혈증/항응고제/갑상선/기타 |
| 16 | 영양제 (인라인 시트) | 항상 | "없음" / "등록하기" |
| 17 | 검진 (날짜+메모) | `age >= 20` | showCheckupEditor modal |
| 18 | 완료 🎉 | 항상 | "{name}님 등록 완료" |

**`_Draft` 클래스**:
```dart
class _Draft {
  Relationship? relationship;
  String name = '';
  int birthYear = DateTime.now().year - 30;
  Sex sex = Sex.male;
  double? heightCm;
  double? weightKg;
  bool isPregnant = false;
  bool isBreastfeeding = false;
  SmokingStatus smokingStatus = SmokingStatus.never;     // 미수집
  DrinkingFrequency drinkingFrequency = DrinkingFrequency.never;  // 미수집
  DietQuality dietQuality = DietQuality.good;
  SleepHours sleepHours = SleepHours.sevenToNine;        // 미수집
  StressLevel stressLevel = StressLevel.low;             // 미수집
  List<String> allergies = [];
  List<String> medications = [];
  String? bloodType;
  List<String> pendingCuratedProductIds = const [];
  DateTime? lastCheckupDate;
  String? checkupNote;
  final List<_AnsweredEntry> answers = [];
}
```

**저장 로직 (`_save`)**:
1. 필수 검증 (relationship, name, birthYear)
2. `FamilyMember` 생성 (id = "fm_{microseconds}")
3. `familyControllerProvider.addMember(member)`
4. 재구매 알림 스케줄 (각 제품, ~25일 전)
5. 검진 알림 스케줄 (1년 후)
6. 라우팅: 첫 멤버면 `/onboarding/notification`, 이후면 `pop()` 또는 `/home`

**Step 16 ProductPickerSheet**: 검색 + 다중 선택 + "선택한 영양제 N개 사라집니다" 취소 확인.
**Step 17 showCheckupEditor**: 날짜 픽커 + 메모 (≤200자).

### `notification_setup_screen.dart`

- "알림은 가볍게,\n꼭 필요한 것만 알려드려요"
- 3개 토글:
  - 📦 영양제 떨어짐 (3일 전, 기본 ON)
  - 🩺 검진 (연 1회, 기본 ON)
  - 💊 복용 시간 (**기본 OFF**)
- 시간 설정 (복용 ON 시): 🌅 아침 07:30, 🌙 저녁 20:00
- 토글 ON → OS 권한 요청 → 거부 시 toast + 자동 OFF 유지

저장 키: `kNotifMorningKey`, `kNotifEveningKey`, `kNotifEnabledKey`, `kReorderEnabledKey`, `kCheckupEnabledKey`.

## 3-5. 멤버 상세 (`member_detail_screen.dart`)

**구조**:
1. 앱바 — "{member.name}의 영양제 관리" + 백
2. **`_ProfileHero`** — 72px 아바타(편집 hint 가능) + 이름/나이/성별/관계 + 연필(`/family/{id}/edit`)
3. **현재 섭취 영양제** (`_CurrentSupplementsSection`) — 큰 카드, "💊 섭취중인 영양제 N개" + 추가 CTA
4. **⚠️ 주의 사항** (`ConflictSection`) — 충돌 있을 때만
5. **건강검진 기록** (`_CheckupSection`)
6. **📊 영양 상태** (`_NutritionStatusSection`)
   - 부족 (priority): 카드
   - 보충 필요 (secondary): collapsible
   - 충분: collapsible
7. **💊 영양제 사러 가기** (`_BuyCta`) → `/recommendation/{memberId}`
8. 면책 2개

**의존**: `familyProvider`, `memberNutrientAnalysisProvider`, `productRepositoryProvider`, `ConflictChecker`.

## 3-6. 영양제 상세 (`product_detail_screen.dart`)

**구조**:
1. 사진 + 이름 + 브랜드 (큰 hero)
2. 복용량/일 + 포장 크기 (`_IntakeSection`)
3. 카테고리별 이점 (`_CategoryBenefitSection`)
4. **성분표** — `?member=ID` 있으면 KDRIs 4단계 평가 병렬 표시
5. 주의사항 (카테고리별)
6. 가격 링크 (네이버쇼핑/쿠팡)
7. 데이터 출처 (`isDeadSourceUrl()` 통과 시만 표시)
8. 면책

**4단계 표시 (커밋 c2141e2 / 22c235e)**:
- UL 초과 → 빨강 "주의 (UL 초과)"
- 200%+ → 회색 "충분 (200%+)" (999% 차단)
- 100-200% → 청록 "충분"
- 50-99% → 녹색 "적정"
- 50% 미만 → 주황 "보충 필요"

> 이전 `_IngredientRow`가 999% 같은 충격 % 표시했으나 → **22c235e에서 4단계 라벨로 완전 교체**.

**26개 제품**: 라벨 데이터 미수록 (`ingredients == {}`) → "라벨 미수록" 뱃지 + "라벨을 직접 확인하세요" 카드.

## 3-7. 설정 (`settings_screen.dart`)

**섹션**:
- **알림** — 매일/리오더/검진 토글 + 시간 설정
- **가족** — 가족 관리 / 가족 추가 / **내 데이터 내보내기** (DataExportService → JSON, 클립보드 복사)
- **정보** — 온보딩 다시 보기 / 처리방침 / 약관 / 면책 / 앱 정보 (1.0.0)
- **⚠️ 모든 데이터 삭제** — 2단계 확인 ("삭제" 입력) → `notificationServiceProvider.cancelAll()` + `SecureStorage.wipe()` → `/privacy-consent`

## 3-8. 핵심 위젯 (`lib/core/widgets/`)

### 버튼 (`alyak_buttons.dart`)
- `PrimaryButton` (파란 채움), `SecondaryButton` (회색 테두리), `AlyakTextButton`
- size: sm 40px / md 48px / lg 56px
- `full=true` → 가로 꽉, `disabled` 지원

### 카드 (`alyak_card.dart`)
- `AlyakCard`: padding 16, radius r16, surface 배경, card 그림자, optional `onTap`

### 채팅 (`chat_bubbles.dart`)
- `BotBubble` 회색 왼쪽 (좌상단 4px, 나머지 16px 비대칭)
- `UserBubble` 파란 오른쪽 (우상단 4px)
- `AlyakBrandMark` CustomPaint 로고

### 충돌 (`conflict_section.dart`)
- `ConflictSection` 래퍼 (비면 숨김)
- `ConflictCard` severity별 배경색
- `ConflictAddDialog` 제품 추가 시 확인

### 상태 (`state_views.dart`)
- `EmptyStateView` — emoji + title + message + 1-2 CTA
- `LoadingStateView` — 64px circular spinner (teal)
- `ErrorStateView`

### 이미지 (`product_image.dart`)
- `assets/images/products/{id}.jpg` 시도
- 실패 시 `_CategoryFallback` (카테고리 emoji + soft 배경)
- 26개 매핑: multivitamin 💊 / vitamin_b 🌅 / vitamin_c 🍋 / vitamin_d ☀️ / omega3 🐟 / calcium 🦴 / 등

### 프로필 (`profile_avatar.dart`)
- `member.profileImagePath` 있으면 사진, 없으면 `member.avatarEmoji`
- `showEditHint=true` → 우하단 카메라 뱃지
- radius = size × 0.32 (둥근 정사각형)

### 기타
- `CoverageBar` — 진행바 (percent, status 색)
- `SectionHeader` — "⚠️ 주의 · 3개"
- `StepIndicator` — "5/18"
- `DisclaimerFooter` — 면책
- `ChatMessage`, `EntryRow`, `StatusPill`, `MemberPickerSheet`, `AvatarBadge`, `AppIconPainter`

---

# PART 4. 인프라

## 4-1. 테마 (`lib/core/theme/`)

### `app_colors.dart`

**철학**: 청록(teal) 주조색, 호박(amber) 경고, 빨강(red)은 의학적 위험만.

| 토큰 | hex | 용도 |
|---|---|---|
| `primary` | `#00ACC1` | 메인 청록 (버튼, 진행률, 초점) |
| `primarySoft` | `#E0F7FA` | 연한 배경 (카드 강조, 배지) |
| `primaryInk` | `#00838F` | 어두운 청록 텍스트 |
| `background` | `#F5F7FA` | Scaffold |
| `surface` | `#FFFFFF` | 카드 |
| `surfaceMuted` | `#F0F2F5` | 칩, 약한 배경 |
| `divider` | `#EEF0F3` | 리스트 분할 |
| `hairline` | `#E0E0E0` | 입력 필드 테두리 |
| `ink` | `#1A1A1A` | 검은 텍스트 |
| `ink2` | `#333333` | 회색1 |
| `muted` | `#666666` | 회색2 (메타) |
| `faint` | `#999999` | 회색3 (비활성) |
| `ghost` | `#C7CCD3` | 매우 밝음 (플레이스홀더) |
| `okBorder` | `#4CAF50` | 충분 경계 |
| `okBg` | `#E8F5E9` | 충분 배경 |
| `okInk` | `#2E7D32` | 충분 텍스트 |
| `warnBorder` | `#FF9800` | 주의 경계 |
| `warnBg` | `#FFF3E0` | 주의 배경 |
| `warnInk` | `#E65100` | 주의 텍스트 |
| `danger` | `#D32F2F` | 의학적 위험 |
| `dangerBg` | `#FFEBEE` | 위험 배경 |
| `pillBg` | `#F0F2F5` | 알약 카드 |
| `pillInk` | `#374151` | 알약 텍스트 |

**`HealthStatus` 결정 함수**:
```dart
HealthStatus statusFromDeficitCount(int count) {
  if (count == 0) return ok;
  if (count <= 2) return warn;
  return alert;
}
```

**가족 멤버 색상 6가지 순환**: `[#FF6B9D, #4FACFE, #43E97B, #FA8231, #A29BFE, #FD79A8]`.

### `app_typography.dart`

**폰트 폴백**: `[Pretendard, Apple SD Gothic Neo, Noto Sans KR]` → 자동 한글 폰트 선택.

| 스타일 | 크기 | weight | letter-spacing | line-height | 색 |
|---|---|---|---|---|---|
| `display` | 24 | 800 | -0.6 | 1.3 | ink |
| `heading1` | 22 | 800 | -0.55 | 1.3 | ink |
| `heading2` | 18 | 700 | -0.4 | 1.35 | ink |
| `sectionTitle` | 17 | 700 | -0.34 | 1.35 | ink |
| `heading3` | 16 | 700 | -0.3 | 1.4 | ink |
| `title` | 15 | 700 | -0.15 | 1.4 | ink |
| `body1` | 14 | 500 | 0 | 1.5 | ink |
| `body2` | 13 | 500 | 0 | 1.5 | ink2 |
| `caption` | 12 | 500 | 0 | 1.4 | muted |
| `micro` | 11 | 500 | 0 | 1.4 | muted |

### `app_spacing.dart` (8 배수)
`xs=4, s=8, sm=12, m=16, ml=20, l=24, xl=32, xxl=40, pageH=20`

### `app_radius.dart`
`r4, r8, r10, r12, r14, r16, r20, r24, pill=999`
- 버튼 r14 / 카드 r16 / 칩·배지 pill / 다이얼로그 r20 / 바텀시트 r20 (상단만)

### `app_shadows.dart`
- **card** (얕음): blur 8 / offset (0,2) / rgba(16,24,40, 0.04) + 보조 blur 2
- **raise** (중간): blur 24 / offset (0,8) / 0.08 + 보조 blur 6
- **popover** (깊음): blur 32 / offset (0,12) / 0.14 + 보조 blur 6

### `app_theme.dart` 합성
- `ColorScheme.fromSeed(primary)` light
- `Scaffold` background `AppColors.background`
- `AppBar` 0 elevation, 배경 동일
- `Card` r16, elevation 0
- `ElevatedButton`/`FilledButton` primary 배경 + h20v16 padding + r14
- `OutlinedButton` primary 전경 + h16v12 + r12
- `Input` surface 배경 + r14 + 포커스 시 primary 1.5px
- `Chip` surfaceMuted, 선택 시 primary
- `SnackBar` floating + ink 배경 + r12 + h4
- `Dialog` r20 + surface
- `BottomSheet` r20 (상단) + drag handle

## 4-2. 보안 (`lib/core/security/`)

### `encryption_service.dart`
- **AES-256-GCM** + 12바이트 random IV
- 기기 키: `SecureStorage.read('alyak.deviceKey.v1')` → 없으면 32바이트 난수 생성 → base64 저장
- 암호화: plaintext → 12바이트 IV → AES-GCM → (IV ‖ ciphertext) base64
- API: `encryptString/decryptString/encryptJson/decryptJson/rotateKey`

### `secure_storage.dart`
- Android: `flutter_secure_storage` + `encryptedSharedPreferences=true`
- iOS: Keychain + `first_unlock_this_device`
- 주요 키:
  - `SecureKeys.privacyConsent` ('1' or 없음)
  - `SecureKeys.onboardingComplete` ('1' or 없음)
  - `SecureKeys.familyDraftsIndex` (JSON 배열)
  - `SecureKeys.familyOrder`
  - `SecureKeys.notificationSettings`
  - `kFamilyMembersListKey` = `'family.members.list'`
  - `'family.member.{id}'` (FamilyMember JSON)
  - `'alyak.family.draft.{id}'`
  - `'alyak.session.lastActive'`
  - `'alyak.deviceKey.v1'`
  - `'alyak.checkin.{id}.{yyyymmdd}'`
  - `'ai_comment.{id}.{yyyy-mm-dd}'`
- 동적 helpers: `familyDraft(id)`, `checkin(id, date)`, `aiComment(id, date)`
- `wipe()` / `deleteAll()` — 모든 키 삭제 (로그아웃)

### `session_guard.dart`
- 정책: **30일 자동 로그아웃**
- `_maxIdle = Duration(days: 30)`, `_lastActiveKey = 'alyak.session.lastActive'`
- API: `touch()` (UTC ms 저장) / `isExpired()` / `clear()`
- 호출: `_BootScreenState.initState()`, `SecureAppShell.didChangeAppLifecycleState(resumed)`
- 만료 시 `SecureStorage.wipe()` + `/privacy-consent`

### `screen_security.dart`
- `SecureAppShell`: `WidgetsBindingObserver`
- 트리거: `inactive`/`paused`/`hidden` 상태 → 블러
- BackdropFilter blur σ=24 + 반투명 흰 오버레이 `Color(0x80FFFFFF)`
- ⚠️ FLAG_SECURE / iOS CALayer 스냅샷은 현재 비활성 (TODO, 프로덕션 전 재활성화)

### `root_detection.dart`
- 경고만, 차단 X
- Android 감시: `/system/bin/su`, `/system/xbin/su`, `/sbin/su`, `/system/app/Superuser.apk` 등
- iOS 감시: `/Applications/Cydia.app`, `/Library/MobileSubstrate/MobileSubstrate.dylib`, `/bin/bash` 등
- 비동기 체크 + 타임아웃 시 false

## 4-3. 알림 (`lib/core/notifications/`)

### `notification_service.dart`

**초기화**:
1. timezone 패키지 init
2. 로컬 타임존 감지 (실패 시 `Asia/Seoul` 폴백)
3. Flutter Local Notifications 초기화
4. Android 채널 생성

**채널**: id=`supplement_reminder`, 이름=`영양제 복용 알림`, 설명=`영양제 복용 시간을 알려드려요`, 중요도 HIGH.

**알림 ID 체계**:
| 타입 | 베이스 | 범위 | 규칙 |
|---|---|---|---|
| 아침 | 1001 | 고정 | `_morningId = 1001` |
| 저녁 | 1002 | 고정 | `_eveningId = 1002` |
| 재구매 | 2000 | +999 | `2000 + hashCode('{id}#reorder:{productId}').abs() % 999` |
| 검진 | 3000 | +999 | `3000 + hashCode('{id}#annual_checkup').abs() % 999` |

**주요 메서드**:

```dart
rescheduleDaily(TimeOfDay? morning, TimeOfDay? evening, {int familyCount=1})
// familyCount >= 2: "가족 영양제 챙기실 시간이에요"
// familyCount < 2: "오늘 영양제 챙기셨어요?"
// 아침 본문: "물 한 컵과 함께 챙겨드세요"
// 저녁 본문: "오늘도 수고 많으셨어요"

scheduleProductReorderReminder(String memberId, String productId, {int daysFromNow=25})
// 제목: "영양제 재구매 시점이 다가왔어요"
// 본문: "남은 수량을 확인해보세요"
// payload: 'reorder:{memberId}:{productId}'

scheduleAnnualCheckupReminder(String memberId, {DateTime? from, String? memberName})
// memberName 있을 때: "{name}님 건강검진 받으신 지 1년이 되었어요"
// 기본: "1년에 한 번 건강검진 받으세요"
// 본문: "국가 건강검진을 챙겨보세요"
// payload: 'annual_checkup:{memberId}'
// 과거 → +1일 조정

cancelReorderReminder(memberId, productId)
cancelAnnualCheckupReminder(memberId)
cancelAllForMember(memberId)
cancelAll()
requestPermission()
```

**스케줄링**: `AndroidScheduleMode.exactAllowWhileIdle` (배터리 세이버 무시) + `matchDateTimeComponents: DateTimeComponents.time` (매일 반복).

### `notification_provider.dart`

```dart
final notificationServiceProvider = Provider<NotificationService>(...);

// 저장 키
const kNotifMorningKey = 'notif.morning.time';   // HH:mm
const kNotifEveningKey = 'notif.evening.time';
const kNotifEnabledKey = 'notif.enabled';        // '0'/'1'
const kReorderEnabledKey = 'notif.reorder.enabled';
const kCheckupEnabledKey = 'notif.checkup.enabled';
const kReorderDaysKey = 'notif.reorder.days';

// 헬퍼
TimeOfDay parseStoredTime(String? raw, TimeOfDay fallback);
String formatTimeOfDay(TimeOfDay t);
```

## 4-4. 핵심 서비스 (`lib/core/services/`)

### `data_export_service.dart`

```json
{
  "schema": 1,
  "exportedAt": "2026-05-07T12:34:56.000Z",
  "appVersion": "1.0.0",
  "memberCount": 2,
  "members": [ ... FamilyMember.toJson() ... ],
  "notes": "본 파일은 기기 내에서 생성됐으며 서버로 전송되지 않습니다. ..."
}
```

- `schemaVersion = 1` (V2 마이그레이션 키)
- `appVersion = '1.0.0'`
- API: `buildJson(members)`, `writeToExternalStorage(members) → 파일 경로`
- Android 외부 저장소 우선, iOS는 `getApplicationDocumentsDirectory` 폴백
- 파일명: `alyak_backup_YYYYMMDDTHHMMSS.json`
- **클립보드 복사 추가** — share_plus 추가 전(V1.1) 사용자가 경로를 수동 공유 가능

### `manual_entry_hash.dart`
- 사용자 직접 입력 영양제의 안정 정체성. **Phase 4 백엔드 가입 키**.
- 해시 대상 (파이프 결합):
  ```
  정규화이름 | 정규화브랜드 | 카테고리(소문자) | intakeTiming.name | dosePerIntake | intakesPerDay | packageSize
  ```
- 정규화: 소문자 + 공백 축약 (구두점 유지)
- 알고리즘: SHA-1
- V1: 로컬만 / Phase 4: 해시 POST → 카운터 증가 → 20+ 도달 시 운영자 검토 → 큐레이션 DB 통합

### `product_search_links.dart`
```dart
String naverShoppingUrl(String query)
  // 'https://search.shopping.naver.com/search/all?query={encoded}'
String coupangSearchUrl(String query)
  // 'https://www.coupang.com/np/search?q={encoded}'

const Set<String> _kDeadSourceHosts = {
  'centrum.pchkorea.co.kr',  // Pfizer Korea 폐쇄
  'pchkorea.co.kr',
};

bool isDeadSourceUrl(String? url);
// null/empty → true
// parse 실패 → true
// host 차단 목록 (정확/접미사 매칭) → true
```

> 추가 시: lower-case + bare host (no scheme/path)

### `product_targeting.dart`
```dart
enum TargetGroup {
  kids, adultMale, adultFemale, seniorMale, seniorFemale,
  pregnant, menopauseFemale, menopauseMale,
}

Set<TargetGroup> inferProductTargets(Product p);
// 키워드 매칭:
//   카테고리 'kids' / 이름 '키즈/어린이/유아/아이/주니어' → kids
//   카테고리 'prenatal'/'pregnancy' / 이름 '임산부/산모/엘레비트' → pregnant
//   이름 '우먼/woman/여성' → adultFemale (시니어 시 seniorFemale)
//   이름 '맨/men's/남성' → adultMale (시니어 시 seniorMale)
//   이름 '실버/시니어/senior/50+' → 시니어
//   카테고리 'menopause_female/male' → menopause*
```

**페르소나 우선순위**:
- 임신: `[pregnant, adultFemale]`
- <13세: `[kids]`
- 여성 65+: `[seniorFemale, adultFemale]`
- 여성 50-64: `[menopauseFemale, adultFemale, seniorFemale]`
- 여성 <50: `[adultFemale]`
- 남성 동일 패턴

**점수**:
- 제네릭(target 없음) +10
- 1순위 매칭 +50
- 2+순위 매칭 +20
- 제외 목록 -100 (하드 제외)

**제외 규칙**:
- 임신: 남성 타깃 제거
- <13세: 모든 성인/노인/폐경 제외
- <50 여성: menopauseFemale 제외
- <50 남성: menopauseMale 제외
- 19+: kids 제외

### `profile_photo_service.dart`
- 저장: `<appDocuments>/profiles/{memberId}_{timestamp}.jpg`
- 카메라/갤러리: 500×500, q=80
- API: `saveForMember(memberId, XFile)`, `deleteIfExists(path?)`
- 삭제 시 `PaintingBinding.instance.imageCache.evict()` 호출 (캐시 무효화)

## 4-5. 가족 Provider (`lib/features/family/providers/family_provider.dart`)

### 저장 구조
```
SecureStorage:
  'family.members.list' → '[id1, id2, ...]'
  'family.member.{id}' → FamilyMember JSON
  'alyak.family.draft.{id}' → 작성 중 멤버 (선택)
```

### `FamilyMembersNotifier extends StateNotifier<List<FamilyMember>>`
- `addMember(member)` → 상태 + 저장 + 인덱스 갱신
- `updateMember(member)` → 상태 + 저장
- `removeMember(memberId)` → 상태 - 저장 + 사진 삭제 + 알림 취소 콜백
- `getMember(id)` → 검색
- `ready` (Future) → 초기 로드 완료 대기
- 패턴: 상태 변경 → 개별 멤버 write → 인덱스 write
- 로드: 인덱스 read → 각 멤버 read → 손상 레코드 스킵

### Riverpod 노출
```dart
final familyMembersProvider = StateNotifierProvider<FamilyMembersNotifier, List<FamilyMember>>;
final familyProvider = Provider<FamilyState>;        // .members + .getMember()
final familyControllerProvider = Provider<FamilyMembersNotifier>;
```

테스트용 `InMemoryFamilyStorage`도 제공.

## 4-6. 시간대 그룹 (`intake_grouping.dart`)

```dart
enum IntakeSlot { morning(🌅), lunch(🌞), evening(🌙) }
```

**정책**:
- 1회/일 → 1슬롯
- 2회+ → 아침 + 저녁
- 3회+ → 아침 + 점심 + 저녁
- 4회+ → 3슬롯 (라벨 참조 노트)

**IntakeTiming → 슬롯**:
| Timing | 슬롯 | MealRelation |
|---|---|---|
| morningEmpty | morning | beforeMeal |
| morningAfter | morning | afterMeal |
| lunchAfter | lunch | afterMeal |
| dinnerAfter | evening | afterMeal |
| withMeal | morning | withMeal |
| beforeSleep | evening | beforeSleep |
| anyTimeAfterMeal | morning | afterMeal |
| multiple | 여러 슬롯 | afterMeal |

```dart
class IntakeOccurrence {
  String entryId;
  bool isCurated;
  String name;
  int dose;
  String unit;       // "정", "캡슐"
  MealRelation mealRelation;
  Product? product;
  ManualProductEntry? manual;
}

IntakeGroupedSchedule buildGroupedSchedule(...);
```

## 4-7. 멤버 분석 Provider (`member_analysis_provider.dart`)

**분석 대상 13종**:
```
vitamin_d_iu, magnesium_mg, omega3_total_mg, calcium_mg, iron_mg, zinc_mg,
vitamin_b12_mcg, vitamin_b9_mcg, vitamin_c_mg, probiotics_billion_cfu,
coenzyme_q10_mg, choline_mg
```

**`MemberAnalysis`**:
```dart
{
  List<NutrientDeficit> deficits;
  List<NutrientDeficit> sufficient;
  int currentProductCount;
  List<NutrientStatus> priority;          // Top 3
  List<NutrientStatus> secondary;         // 4-5개
  List<LifestyleSuggestion> lifestyleSuggestions;
}

class NutrientDeficit {
  String nutrient;            // 'vitamin_d_iu'
  String displayName;         // '비타민D'
  double current;
  double recommended;
  int percentage;             // 0-200 클램프
  List<String> sourceProductNames;
}

class LifestyleSuggestion {
  String category;            // DB 카테고리 (liver, sleep, sports)
  String displayName;         // '간 건강'
  String reason;              // '음주 습관으로인한 추천'
}
```

**캐싱**: `member_analysis_caching_test.dart`로 회귀 가드.

## 4-8. AI 코멘트 (`ai_comment_service.dart`)

**폴백 메시지 10가지** (캐시 키 `'ai_comment.{id}.YYYY-MM-DD'`):
```
1. "물 한 컵과 함께 영양제, 잊지 마세요 💧"
2. "오늘도 가족 건강 챙기시느라 수고 많으세요 💚"
3. "꾸준함이 가장 큰 보약이에요 🌱"
4. "작은 습관이 큰 변화를 만들어요 ✨"
5. "가족의 미소를 위한 한 알 💊"
6. "오늘 컨디션 어떠세요? 😊"
7. "건강한 하루 되세요 🌞"
8. "영양제 한 알에 마음을 담아 보세요 🌷"
9. "꾸준한 챙김이 큰 사랑이에요 💝"
10. "오늘도 가족을 위한 하루 시작해요 🌅"
```

**동작**: 캐시 → 있으면 반환 → ClaudeApi 호출 시도(현재 빈 키) → 실패/없음 시 폴백 (`hashCode % 10`).

## 4-9. 법적 문서 (`lib/core/legal/legal_documents.dart`)

```dart
const kPrivacyPolicyEffectiveDate = '2026-05-07';
const kPrivacyPolicyVersion = '1.0';
const kPrivacyPolicyContact = 'help@sphinfo.co.kr';
```

### `kPrivacyPolicyMarkdown` 섹션
- 제1조 수집 항목 — 이름(별칭), 출생연도, 성별, 관계, 키/몸무게, 알레르기, 약물, 임신/수유, 혈액형, 만성질환, 영양제 정보
- 제2조 이용 목적 — 맞춤 추천, 충돌/과다 안내, 알림, 검진 알림
- 제3조 보유 기간 — 기기 내, 외부 전송 X (V1)
- 제4조 제3자 제공 — 없음 (V1), V2 예정 Firebase/AdMob
- 제7조 보안 — AES-256 암호화, allowBackup=false, 검색 쿼리만 외부

### `kTermsOfServiceMarkdown` 핵심
- 의료 행위 X
- 의사/약사 상담 권장 (특히 임신/만성질환/약물)
- 사용자 입력 정보 정확성 책임은 사용자
- 라벨 정보 없는 제품 → "라벨 정보 없음" 표시

### `kMedicalDisclaimerShort`
```
본 앱은 의료 행위가 아니며, 의사·약사의 전문 진단을 대체하지 않습니다.
추천은 2025 한국인 영양소 섭취기준을 기반으로 한 일반 정보이며,
개인 건강 상태에 따른 결정은 의사·약사와 상담 후 진행하세요.
```

## 4-10. App Boot

### `lib/main.dart`
```dart
WidgetsFlutterBinding.ensureInitialized();
final encryption = EncryptionService();    await encryption.init();
final notifications = NotificationService(); await notifications.ensureInitialized();
final productRepository = ProductRepository(); await productRepository.load();
runApp(ProviderScope(
  overrides: [
    encryptionServiceProvider.overrideWithValue(encryption),
    notificationServiceProvider.overrideWithValue(notifications),
    productRepositoryProvider.overrideWithValue(productRepository),
  ],
  child: const AlyakApp(),
));
```

### `lib/app/app.dart`
```dart
MaterialApp.router(
  title: '알약',
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light(),
  routerConfig: router,
  builder: (ctx, child) => SecureAppShell(child: child ?? SizedBox.shrink()),
);
```

## 4-11. Android 설정

### `android/app/build.gradle.kts`
```kotlin
android {
    namespace = "kr.co.sphinfo.alyak.alyak"
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true   // Java 8 백포트
    }
    kotlinOptions { jvmTarget = "17" }
    defaultConfig {
        applicationId = "kr.co.sphinfo.alyak.alyak"
        multiDexEnabled = true                  // 100K+ 메서드
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            // ⚠️ TODO: 프로덕션 서명 추가
        }
    }
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

### `AndroidManifest.xml`

**권한** (총 13개):
- 네트워크: `INTERNET`, `ACCESS_NETWORK_STATE`
- 알림: `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK`, `VIBRATE`
- 카메라/사진: `CAMERA`, `READ_MEDIA_IMAGES`, `READ_EXTERNAL_STORAGE` (maxSdk=32)

**Application 설정**:
```xml
android:label="알약"
android:usesCleartextTraffic="false"   <!-- HTTPS 강제 -->
android:allowBackup="false"            <!-- ADB 백업 차단 -->
android:dataExtractionRules="@xml/data_extraction_rules"
android:fullBackupContent="false"
```

**MainActivity**: `exported="true"`, `launchMode="singleTop"`, `taskAffinity=""`.

**알림 수신자**: `flutterlocalnotifications.ScheduledNotificationReceiver` + `ScheduledNotificationBootReceiver` (BOOT_COMPLETED, MY_PACKAGE_REPLACED, QUICKBOOT_POWERON).

**Queries**: TEXT 처리 + HTTP/HTTPS Intent.

---

# PART 5. 데이터 자산

## 5-1. `assets/data/products.json` (8,058줄, 250제품)

### Top-level

```json
{
  "version": "2026.05.06-v9-all-verified",
  "currency": "KRW",
  "schema_notes": [...],
  "products": [...]   // 250개
}
```

**스키마 노트 (핵심)**:
- 성분 함량은 **단위당(정/캡슐/포)** 기준 — daily_dose로 곱함
- `probiotics_billion_cfu`: 보장균수(유통기한 말). 마케팅 함유균수와 구분
- `ingredients = {}`: 정량 정보 미공개 제품 (검색용만 등록, 26개)
- `dose_per_intake × intakes_per_day == daily_dose` (불변식)

### 샘플 entry
```json
{
  "id": "centrum_woman",
  "name": "센트룸 우먼",
  "english_name": "Centrum For Women",
  "brand": "센트룸",
  "brand_type": "brand",
  "category": "multivitamin",
  "unit": "정",
  "daily_dose": 1,
  "package_size": 60,
  "intake_timing": "anyTimeAfterMeal",
  "dose_per_intake": 1,
  "intakes_per_day": 1,
  "intake_note": "오전중 식후 1정 (만 12세 이상 여성)",
  "ingredients": {
    "vitamin_a_mcg": 1097, "vitamin_d_iu": 400, "vitamin_e_mg": 33.5,
    "vitamin_k_mcg": 50, "vitamin_b1_mg": 3.4, "vitamin_b2_mg": 3.9,
    "vitamin_b3_mg": 14, "vitamin_b5_mg": 12, "vitamin_b6_mg": 4.9,
    "vitamin_b9_mcg": 400, "vitamin_b12_mcg": 22, "vitamin_c_mg": 120,
    "calcium_mg": 250, "iron_mg": 10
  },
  "good_for": ["성인 여성 종합", "철분 보충"],
  "alternatives": ["centrum_man", "centrum_silver_woman"],
  "popularity_rank": 1,
  "data_source": "https://www.health.kr/searchDrug/result_drug.asp?drug_cd=A11AOOOOO0627",
  "verified_date": "2026-05-06",
  "image_url": "https://img.danuri.io/catalog-image/..."
}
```

### 카테고리 분포 (총 42개)

| 카테고리 | 수 | 카테고리 | 수 |
|---|---|---|---|
| multivitamin | 31 | omega3 | 12 |
| vitamin_d | 17 | vitamin_c | 11 |
| vitamin_b | 15 | probiotic | 11 |
| sports | 14 | collagen | 11 |
| antioxidant | 11 | joint | 10 |
| mineral | 9 | eye | 8 |
| prenatal | 7 | calcium | 7 |
| liver | 6 | korean_herbal | 6 |
| sleep | 5 | probiotics | 5 |
| magnesium | 5 | weight | 4 |
| kids_omega3 | 4 | kids | 4 |
| circulation | 4 | men_health | 3 |
| kids_multivitamin | 3 | kids_korean_herbal | 3 |
| fiber | 3 | superfood | 2 |
| pregnancy | 2 | menopause_female | 2 |
| lutein | 2 | krill_oil | 2 |
| kids_vitamin_d | 2 | immunity | 2 |
| immune | 2 | women_health | 1 |
| menopause_male | 1 | iron | 1 |
| ginseng | 1 | biotin | 1 |

### intake_timing 분포

| Timing | 수 |
|---|---|
| anyTimeAfterMeal | 94 |
| multiple | 42 |
| morningAfter | 40 |
| morningEmpty | 37 |
| withMeal | 21 |
| dinnerAfter | 8 |
| beforeSleep | 8 |

### 성분 키 (총 72종)

비타민(A/B1-B12/C/E/K), 미네랄(Ca/Fe/Mg/Zn/Se/I/Cu/Mn/Cr/Mo), 오메가3(EPA/DHA/total), 항산화(코엔자임Q10/루테인/지아잔틴/아스타잔틴/레스베라트롤/커큐민/실리마린/리코펜), 한약(진세노사이드/은행잎/쏘팔메토/보스웰리아/크랜베리), 아미노산(BCAA/L-카르니틴/글루타민/citrulline/L-아르기닌/타우린/L-테아닌), 수면(멜라토닌), 지방산(베타-카로틴/CLA/GLA/EPO), 기타(콜라겐/콜라겐펩타이드/MSM/글루코사민/콘드로이친/유산균CFU/식이섬유/이노시톨/NAC/HCA/스피루리나/엽록소/베타알라닌/크레아틴/플라보노이드/안토시아니딘/옥타코사놀/피페린/헛개나무/마카/헴철/필라피드/포스포리피드 등).

### 브랜드 타입
- `brand`: 227, `generic`: 23

### 검증
- 250개 100% 라벨 검증 (verified_date=2026-05-06)
- 스키마 검증: `test/products_intake_test.dart`

## 5-2. `supplement_guide.json` (3,540줄)

```json
{
  "version": "2026.04",
  "supplements": [...]
}
```

**각 entry**:
```json
{
  "id": "s001",
  "korean_name": "비타민A",
  "english_name": "Vitamin A",
  "category": "fat_soluble_vitamin",  // water_soluble_vitamin / mineral / phytonutrient
  "main_benefits": ["시력 유지에 도움이 돼요", ...],
  "personalized_reasons": {
    "smoker": "베타카로틴 형태가 더 안전해요",
    "elderly": "야맹증 예방에 도움이 돼요",
    "child": "성장기 시력 발달에 필요해요",
    "female_30s": "피부 건강 유지에 좋아요"
  },
  "timing": { "best_time": "morning", "meal_relation": "with_food", "reason": "지방과 함께 흡수돼요" },
  "dosage": {
    "adult": {"amount": 800, "unit": "mcg"},
    "child_7_12": {"amount": 500, "unit": "mcg"},
    "teen_13_18": {"amount": 700, "unit": "mcg"},
    "elderly_60plus": {"amount": 800, "unit": "mcg"},
    "upper_limit": 3000
  },
  "good_combinations": [{"with": "비타민E", "reason": "산화 방지에 도움돼요"}],
  "bad_combinations": [{"with": "이소트레티노인", "severity": "warning"}],
  "drug_interactions": [...],
  "food_alternatives": ["당근", "고구마", "달걀노른자", "시금치"],
  "effect_timeline": "꾸준히 1-2개월 복용해야 효과를 느낄 수 있어요"
}
```

## 5-3. `age_group_recommendations.json` (404줄, 18 페르소나)

| ID | age_group | gender | 특수 |
|---|---|---|---|
| p001-002 | newborn | M/F | — |
| p003-004 | toddler | M/F | — |
| p005-006 | child | M/F | — |
| p007-008 | teen | M/F | — |
| p009-010 | adult | M/F | — |
| p011-012 | elderly | M/F | — |
| p013 | adult | pregnant | 임신 |
| p014 | adult | breastfeeding | 수유 |
| p015 | child | picky_eater | 편식 |
| p016 | adult | vegetarian | 채식 |
| p017-018 | middle_age | M/F | 50-64 |

각 프로필: `must_take[]` / `highly_recommended[]` / `consider_if[]` / `avoid[]` / `region_notes` (KR/JP).

## 5-4. `combination_optimizer.json` (126줄)

- **separation_required** 9건 (예: 철분-칼슘 120분, 철분-녹차 60분)
- **synergy** 13건 (비타민D+칼슘, 루테인+지아잔틴 등)
- **time_slot_optimization** 4슬롯:
  - morning: 52종 (D, 철분, 유산균 등)
  - afternoon: 4종 (C, 프로바이오틱스)
  - evening: 15종 (오메가3, 칼슘, 글루코사민 등)
  - before_sleep: 5종 (멜라토닌, 마그네슘, 콜라겐)
- **overdose_warnings** 9건 (종합비타민 + 단일 비타민 조합)

## 5-5. `symptom_guide.json` (608줄, 50 증상)

50개 증상: 눈이 떨려요, 다리에 쥐가 나요, 만성 피로, 머리카락 빠짐, 잠들기 어려움, 소화불량, 변비, 설사, 가슴 통증, 감기, 시야 흐림, 갱년기, 골다공증, 관절 통증, 근육 약화, 기억력 저하, 눈 건조, 눈 피로, 단 음식 갈망, 두통, 땀 많음, 면역력 저하, 발기부전, 불안감, 비염, 빈혈, 뼈 통증, 생리불순, 성욕 감소, 손발 차가움, 손톱 부서짐, 스트레스, 시력 저하, 식욕 부진, 심한 두통, 심한 출혈, 안구 건조증, 알레르기, 어깨 결림, 어지러움, 우울감, 의식 잃음, 입냄새, 잇몸 출혈, 집중력 저하, 천식, 체중 감소, 체중 증가, 피부 트러블, 허리 통증.

각 entry: `id` (sym001-050), `symptom`, `type` (A/B), `keywords[]`, `related_supplements[]` (relevance: primary/secondary), `lifestyle_tips[]`, `urgency` (low/medium/high).

## 5-6. `assets/images/products/` (250장)

- 포맷: JPEG
- 명명: `{product_id}.jpg` (또는 `{brand}_{name}.jpg`)
- 해상도: 240×240 픽셀 (정사각 중앙 크롭)
- 품질: q=80
- 파일 크기: 3.9-12 KB
- 총 ~2.6MB

---

# PART 6. 테스트 / 스크립트 / 디자인

## 6-1. test/ (29개 테스트, 300/300 통과)

| 파일 | 검증 |
|---|---|
| `category_hard_filter_test.dart` | 비타민D 추천에서 probiotics 제외, 단일 비타민D 통과, 가성비 브랜드, 후보 0개 시 카테고리 미노출 |
| `category_sort_test.dart` | 카테고리 더보기 정렬 (판매량/가성비/종합추천) |
| `checkup_persistence_test.dart` | lastCheckupDate + checkupNote JSON 라운드트립, legacy 호환 |
| `conflict_checker_test.dart` | UL 초과(멀티 면제), 흡수 간섭, 시간 누적, 약물 스텁, 임산부/수유부 규칙 |
| `entry_screens_test.dart` | 알림 권한, 동의, 일과 시간, 가족 추가 라우팅 |
| `family_add_persona_test.dart` | KDRIs 2025 정렬 후 18단계 페르소나별 분기 |
| `family_member_card_test.dart` | 멤버 정보, 분석 상태, 결핍 표시 |
| `family_persistence_test.dart` | JSON 직렬화 모든 필드 라운드트립 |
| `home_simplified_test.dart` | 영양제 진입 행 제거, 가족 추가 버튼 복원, 컴팩트 카드, amber→red |
| `hotfix_test.dart` | bracketForAge(0)→infant0to5, DietQuality 기본=good, manual 안내, 빈 ingredients 26개 |
| `intake_grouping_test.dart` | 시간대 슬롯별 그룹화 |
| `kdris_2025_extension_test.dart` | KDRIs 24종 페르소나별 (B군 추가 후 13구간 풀 매트릭스) |
| `kdris_2025_test.dart` | bracketForAge() 13구간, 권장량, 임신/수유 가산, UL, 5 페르소나(35F/임/수/70F/10세) |
| `lifestyle_suggestions_test.dart` | 음주/수면/스트레스/식단 제안 (V1 정렬 후 일부 회귀 가드) |
| `manual_entry_hash_test.dart` | 동일 입력→동일 해시, 정규화 |
| `manual_product_entry_test.dart` | intakeTiming/dosePerIntake/intakesPerDay/intakeNote 직렬화, scheduleLabel |
| `member_analysis_caching_test.dart` | 분석 캐시 일관성, 다른 멤버 변경 시 무효화 X |
| `member_picker_sheet_test.dart` | 0/1/N 분기 (0→None, 1→자동 선택, N→시트) |
| `nutrient_evaluation_test.dart` | **30 케이스: 4분기 / 마진 경계 / 단위 단순화 / 숫자 포맷 / 페르소나** |
| `nutrient_labels_coverage_test.dart` | products.json 모든 ingredient 키가 한글 매핑됨 |
| `nutrient_list_format_test.dart` | 숫자 포맷, 단위, UI 텍스트 |
| `onboarding_screen_test.dart` | 4슬라이드 순회, 동의→알림 경로 |
| `product_search_links_test.dart` | URL 인코딩, 한글 %, dead-source 필터 |
| `product_targeting_test.dart` | 35F→센트룸맨 비추천, 60F→시니어 여성 |
| `products_intake_test.dart` | 250제품 모두 intake_timing/dose/intakes 보유, 불변식 |
| `profile_avatar_test.dart` | 사진 없음→이모지 폴백 |
| `recommender_tiers_test.dart` | 판매량/가성비/종합추천 3티어 |
| `release_blocker_fixes_test.dart` | 출시 차단 4건 통합 회귀 가드 |
| `widget_test.dart` | 기본 부팅/렌더 |

## 6-2. scripts/ (12개)

| 파일 | 용도 |
|---|---|
| `add_intake_fields.py` | products.json에 intake_timing/dose_per_intake/intakes_per_day/intake_note 일괄 추가 (카테고리 기반 기본값, 멱등) |
| `download_product_images.py` | image_url → 240×240 q=80 JPEG 다운로드 (4KB+/120px+ 필터, 로고 거절) |
| `fetch_product_images.py` | data_source URL → og:image 자동 추출 (선행 스크립트) |
| `retry_missing_images.py` | 다중 검색 (name → english_name → brand+name → brand) + aspect ratio 검증 |
| `search_product_images.py` | 다나와 검색 fallback |
| `test_apis.dart` | API 테스트 |
| `verify_top30.py` | 상위 30개 라벨 검증 |
| `verify_multiple68.py` | multiple timing 68개 검증 |
| `verify_atm_me.py` | anyTimeAfterMeal + morningEmpty 116개 검증 |
| `verify_remaining47.py` | 잔여 47개 최종 검증 |
| `_atm_me_targets.json` | ATM Me 116개 목표 데이터 |
| `_top30_mapping.json` | Top-30 매핑 데이터 |

## 6-3. design/ (12개 — Figma → JSX/HTML 시안)

| 파일 | 역할 |
|---|---|
| `Alyak.html` | 디자인 메인 / 스타일가이드 HTML |
| `screens-home.jsx` | 홈 화면 시안 (가족 카드 그리드) |
| `screens-member.jsx` | 멤버 상세 (분석/결핍/스케줄) |
| `screens-misc.jsx` | 기타 (설정/알림/프로필) |
| `screens-onboarding.jsx` | 온보딩 (18단계 채팅) |
| `screens-states.jsx` | 로딩/오류/빈 상태 |
| `screens-supplement.jsx` | 영양제 추천/상세/검색 |
| `tokens.jsx` | 색/타이포/간격 토큰 |
| `components.jsx` | 재사용 컴포넌트 카탈로그 |
| `design-canvas.jsx` | 전체 캔버스 |
| `android-frame.jsx` | Android 기기 프레임 목업 |
| `scraps/` | 이전 시안 아카이브 |

---

# PART 7. 92개 커밋 히스토리

## 단계 1. 기초 설정 + 보안 (커밋 1-5)

### `2642447` Initial commit
- **WHY**: Flutter 프로젝트 0에서 시작, Riverpod + GoRouter 선택
- **WHAT**: AES-256-GCM EncryptionService, SecureStorage, SessionGuard, RootDetection / Android cleartext 차단, allowBackup=false / 50개 영양제 가이드, 50증상, 16 페르소나, 15 제품 / Toss 스타일 #3182F6
- **RESULT**: 보안 기초 완성

### `70a01cf` Stage 1 Foundation
- **WHY**: 인프라(암호화/알림/AI) 사전 준비, iOS 권한 필수
- **WHAT**: ClaudePayloadSanitizer (PII 감지), NotificationService (매일/리오더/검진), SecureAppShell (블러), iOS Podfile/Info.plist/entitlements, AppIconPainter
- **RESULT**: 웹 서비스 준비, iOS 대비

### `c561441` Stage 2-A 영양제/증상/프로필 DB
- **WHY**: 50→100 영양제 확대. 증상별 의료 메시지 추가 (병원 vs 영양제)
- **WHAT**: supplement_guide 100개(미네랄/프로바이오틱스/항산화/눈/관절/간/체중/운동/수면/면역/여성/남성/어린이/인지) / SpecialWarnings / RecommendationProfile (MustTake/Recommended/Conditional) / 18 페르소나 (중년 M/F 추가) / IntakeTiming enum 설계
- **RESULT**: 100개 영양제 분석 기초

### `297ca94` Stage 2-B Product DB + MFDS API
- **WHY**: 15 placeholder → 100 정식. 식약처 API 통합 검토
- **WHAT**: products.json 100개 (종합 15/D 12/Ω3 12/Mg 10/Ca 12 등) / Product 확장(brand/units/popularity) / MfdsApi.dart (HtfsInfoService03, 24h 캐시) / **결과 후 MFDS API 제외** (쿼리 파라미터 미작동)
- **RESULT**: 검증 가능 100개

### `3d2757d` ShopConfig 제휴 링크 (Phase 4 대비)
- **WHY**: 미리 링크 구조 설계
- **WHAT**: ShopOption(네이버/쿠팡/iHerb URL 분리), getShopOptions, AppStrings.affiliateDisclosure
- **RESULT**: Phase 4 준비

## 단계 2. QA Round 6 — 가족 카드 + 지속성 (커밋 6-10)

### `da25c70` 가족 카드 UI
- **WHY**: 홈 가족 카드 placeholder, Stage 3 누락, 양쪽 동시 구현
- **WHAT**: FamilyMember(id/relationship/avatar) / familyProvider StateNotifier / 동적 카드 0/1/2/3/4/5+ 레이아웃 / 색상 코딩 (성공 녹색/경고 주황/주의 빨강) / 테스트 13개
- **RESULT**: 가족 카드 완전 구현

### `2f74df9` 지속성 회복
- **WHY**: 가족 데이터 메모리 전용 → 재시작 소실 (임계 오류)
- **WHAT**: SecureStorage 왕복 / FamilyMember 대폭 확장 (Lifestyle/Health/Checkup/currentProducts/timestamps) / NotificationService 확장 (재구매 + 검진 + 멤버 삭제 시 자동 cancel) / 16단계 채팅(관계→이름→나이→임산부→흡연→식단→알레르기→약→검진→완료) / 검진 입력 14단계
- **RESULT**: 지속성 완료, 9 placeholder 실제 구현

### `59d568a` Stage 3-B 진입 + 핵심 화면
- **WHY**: privacy-consent와 welcome placeholder → 앱 사용 불가
- **WHAT**: PrivacyConsentScreen (4섹션 + 이중 동의) / WelcomeScreen (봇 메시지 + fade CTA) / NotificationSetupScreen (시간 + 권한) / FamilyManagementScreen / FamilyEditScreen / SettingsScreen (이중 확인 삭제) / SymptomSearchScreen (타입 A/B) / SupplementGuideScreen (3줄 요약 + 펼침) / 모든 placeholder 라우트 실제 화면 연결
- **RESULT**: 9 핵심 화면 완전 구현

### `117409e` 폰 테스트 6 hotfix
- **WHY**: 채팅 단계 분기 불안정, 키보드 문제, DB 미정합
- **WHAT**: FIX1 _shouldShow 결정론적 / FIX2 decimal 입력 / FIX3 autocorrect:false / FIX4 영양제 모달 / FIX5 products.json snake_case 정리
- **RESULT**: 데이터 정합성, 채팅 안정성

### `5fb484d` birthYear migration + checkup 제거
- **WHY**: age → birthYear 영구 저장 / HealthCheckup 12개 의료 값 제거 (스펙 축소)
- **WHAT**: H1 birthYear 정수 영구 + age 계산식 + ageGroup 확장 (newborn-elderly), JSON migration legacy age → synthetic birthYear / H2 HealthCheckup 전체 삭제, 정보성 연간 알림만 / H3 17단계 재설계 (1-4 기초 / 5 의료(<4세) / 6 신체 / 7-8 임/수(F 15-49) / 9-10 흡연/음주(19+) / 11-12 식단/수면(4+) / 13 스트레스(13+) / 14 알레르기 / 15 약(1+) / 16-17 제품/완료) / H4 의료 안내 단계
- **RESULT**: 데이터 모델 정규화, 결정론적 단계

## 단계 3. 제품 데이터 검증 확대 (커밋 11-50)

### `f8c6366` 가격 제거 + MFDS 삭제 + 웹 검증 DB
- **WHY**: 가격 필드 → 한국 건강기능식품 규제 위반 위험. MFDS 검색 파라미터 무작동
- **WHAT**: pricePerUnitKrw/packagePriceKrw/dailyCostKrw 모두 제거 / ProductCombo coverage 정렬 / manual_supplement_input 단순화 + "정보 등록 요청" / MFDS API 완전 삭제 / products.json 웹 검증 재구성
- **RESULT**: 규정 준수, 신뢰성 강화

### `91604b1` 56 웹 검증 entries
- **WHY**: 250 목표 vs 30 검증 → 56 사전 검증 확대
- **WHAT**: 56개 (다나와/올리브영/필라이즈) / 카테고리 확대 (종합 3→7, D 3→6, Ω3 4→5, 프로바이오 3→5, 신규: 간/항산화/임산부/순환/수면/폐경/한방/어린이/스포츠) / 28% 커버리지 (56/250)
- **RESULT**: 품질 기준 설정

### `a9e6b4a` ~ `2ce296e` 56 → 71 → 250 (+194)
- **WHY**: 250개 목표 달성. 매주 배치 (브랜드별 라인업)
- **WHAT**: 35커밋 누적:
  - 콜라겐 (bblab 1500/에버콜라겐/비비랩/솔가)
  - 프로바이오 (CJ 바이오코어/bblab/애터미/휴온스/BNR17)
  - B군 (솔가 B-complex/NOW B50/B100)
  - 미네랄 (솔가 Ca/Mg/Zn/CKD)
  - 특화 (NAC/커큐민/레스베라트롤/테아닌/CoQ10/BCAA/루테인/글루코사민/쏘팔메토/크랜베리/활성엽산)
  - 어린이 (노르딕/한삼인/센트룸 키즈/함소아 홍삼)
  - dedupe 10건
- **RESULT**: **250개 완성** (커밋 2ce296e)

## 단계 4. 라벨 검증 + 디자인 시안 (커밋 51-70)

### `df0ce8e` 디자인 토큰 + 공통 컴포넌트
- **WHY**: Figma 시안 1:1 코드 반영
- **WHAT**: AppColors (#3182F6 톤다운, ok/warn/alert + HealthStatus) / Typography Pretendard 7단계 / Spacing/Radius/Shadows / 위젯 (AlyakCard/Buttons/AvatarBadge/StatusPill/CoverageBar/SectionHeader/EntryRow/DisclaimerFooter/봇·사용자버블/BrandMark/StepIndicator/ProductPhoto/Chip) / 테스트 45개 통과
- **RESULT**: 디자인 시스템 정립

### `9566306` IntakeTiming + dose/intakes 250개
- **WHY**: 모든 제품 복용 정보 정확히 기록
- **WHAT**: IntakeTiming enum 8값 / Product에 dosePerIntake/intakesPerDay/intakeNote / scheduleLabel 자동 생성 / 카테고리별 기본:
  - 멀티/Ω3/지용성 → 식후
  - B/철/엽산/콜라겐/홍삼/프로바이오 → 공복
  - Mg/밀크씨슬/수면 → 수면전
  - Ca → 저녁 / Q10 → 점심후 / 어린이 → 식사중
  / 250개 적용, intakes≥2 → multiple / 멱등 add_intake_fields.py
- **RESULT**: 복용 기초

### `ce5c9e2` Top30 라벨 직접 검증
- **WHY**: 카테고리 룰 정확도 검증
- **WHAT**: 약학정보원/제조사/다나와/올리브영/필라이즈로 라벨 확인 / 30개 중 11 보정 (Promega Dual 1+2 multi → 2+1 morningAfter 등) / verified_date + data_source URL + intake_note
- **RESULT**: 정확도 82% (168/205)

### `7cc151c` multiple 분복 vs 통합 (57개)
- **WHY**: "multiple" 자동 분복 처리, 실제론 1일 1회 N정 통합인 경우 다수
- **WHAT**: 22 변경 (1+2 multi → 2+1 anyTimeAfterMeal: Nordic Ω3 등) / 35 일치 / verify_multiple.py 멱등
- **RESULT**: 분복/통합 분명화

### `14db790` atm/me (116개)
- **WHY**: 230개 중 분산된 anyTimeAfterMeal(79) + morningEmpty(37) 검증
- **WHAT**: 116 중 7 변경 (anyTimeAfterMeal → morningAfter: Orthomol Immun 등) / 109 일치 / 누적 30+57+116 = 203 (81%)
- **RESULT**: 81% 검증

### `3f7824e` 잔여 47 — **250개 100%**
- **WHY**: 마지막 47로 완전 검증
- **WHAT**: 47 중 5 변경 (Q10 lunch→morning) / 42 일치 / **최종 250개 verified_date=2026-05-06** / 변경율 18% (45/250)
- **RESULT**: **100% 라벨 검증 달성**

## 단계 5. 제품 사진 파이프라인 (커밋 71-75)

### `091ccaa` 250 사진 파이프라인 + 91 적용
- **WHY**: 사진 없으면 사용자 구분 어려움. 240×240 center-crop JPEG q80
- **WHAT**: fetch_product_images.py (data_source URL → og:image 자동, 로고 패턴 거절) / download_product_images.py (240×240 q80, 4KB+/120px+ 필터) / ProductImage 위젯 (asset + 카테고리 이모지 폴백 26종) / 91개 (36.4%, ~742KB)
- **RESULT**: 91 사진

### `c5c60f3` 다나와 fallback + iHerb 업그레이드 91 → 216
- **WHY**: iHerb URL 업그레이드 + 다나와 검색 추가
- **WHAT**: iHerb /s/ → /l/ (3개) / search_product_images.py (search.danawa.com → img.danuri.io, 117/145 성공) / placeholder 8개 제거 / 216 (86.4%, ~1.8MB)
- **RESULT**: 216 사진 (+125)

### `c4fd31a` 잔여 28+6 — **250/250 100%**
- **WHY**: 마지막 34장 완전 커버리지
- **WHAT**: retry_missing_images.py (다중 검색: name only → english_name → brand+name → brand alone) / aspect-ratio 검증 (0.5 < ratio < 2.0, 배너 차단) / **250 100%, ~1.9MB**
- **RESULT**: **250 사진 100%**

## 단계 6. 온보딩 + UI 화면 (커밋 76-85)

### `708a159` 16단계 페르소나 분기 정정 + 인라인 시트
- **WHY**: 분기 거칠고, 영양제 추가 흐름 끊김 (저장 후 검색 별도 진입)
- **WHAT**: implied 성별 자동 + 임/수 통합(4옵션, F 20-50) / 흡연·음주(19+) / 식단·수면(4+) / 스트레스(13+) / 약(1+) / 인라인 ProductPickerSheet (검색 + 다중 + 요약) / PopScope 취소 다이얼로그 / nutrient_labels 70+ 매핑 공개
- **RESULT**: 채팅 안정성, 영양제 통합

### `31ba46e` 충돌 부활 + 알림 옵션 + 검진 통합
- **WHY**: 5종 충돌 감시 필요, 알림 선택 가능, 검진 입력
- **WHAT**: ConflictChecker 5종 (severity 3) / 충돌 카드 (멤버 상세/추천/추가) / Settings 알림 토글 (권한 거부 자동 OFF) / lastCheckupDate/checkupNote / step 17 검진 (20+) / 멤버 상세 검진 섹션 / 테스트 +19
- **RESULT**: 충돌 활성화

### `cde7939` 추천 화면 + 충돌 출시 가능 수준
- **WHY**: 충돌 RDI×2 임계 제거 (과도) → UL만 / 종합비타민 단독 면제
- **WHAT**: UL 초과만 warning / 종합(8+ 성분/카테고리 명시) 단독 면제, 합산만 / 추천 재구성: 부족 영양소별 카드 (판매량/가성비/종합) + 추천 영양소 접힘 / 다이얼로그 분리 / 페르소나 분기 (35F→우먼/여성, 임→임산부, 5세→키즈만) / 테스트 +8
- **RESULT**: 추천 정확도

### `d7f17ba` 프로필 사진 + 추가 버튼 가독성
- **WHY**: 멤버 구분 이모지뿐 헷갈림, 추가 버튼 안 보임
- **WHAT**: profileImagePath nullable / ImagePicker 500×500 q80 → /profiles/{id}_{ts}.jpg / ProfileAvatar (사진 우선, 없으면 이모지) / 멤버 수정에 _PhotoSection (96px 아바타 + 카메라 뱃지) / 가족 카드/상세/관리/picker 4곳 AvatarBadge → ProfileAvatar / ProfilePhotoService / 영양제 추가 청록 헤더 (_AddPill) + 카드 마지막 (_AddSupplementCard 점선 + 흰 +) / iOS/Android 권한
- **RESULT**: 식별 용이, 가독성

### `4770869` 사진 즉시 반영 + 시간대 그룹 + 상세 + 캐싱
- **WHY**: 사진 변경 미반영 (watch 구조), 시간대 그룹화, 캐싱 최적화
- **WHAT**: ref.watch(familyMembersProvider.select(...)) + imageCache.evict() / IntakeSlot (morning/lunch/evening) 자동 / 1회→아침 / 2회→아침+저녁 / 3회→3슬롯 / 시간대 헤더 이모지 + "아침" + 카운트 pill / 영양제 카드 압축 60×60 + 1줄 + "식후 2정" + 검증 pill (~80px ← ~180px) / 분석 캐싱: 한 멤버 watch / 영양제 상세 진입
- **RESULT**: 캐싱 효율, 흐름 직관화

### `2e1eff8` 표현 정리 — 섭취중 + 한 줄 콤마 + 라인 버튼
- **WHY**: 표현 일관성, 가독성, 톤다운
- **WHAT**: "복용 중"/"챙기시는" → **"섭취중"** (4곳) / NutrientPriorityCard "• A\n• B" → "A, B" 한 줄, 6+ → "A, B, C 외 N개" / 네이버/쿠팡 채움 → 라인 (2px 테두리 + 흰 배경 + 브랜드 텍스트)
- **RESULT**: UI 통일

### `07e858e` 시안 정렬 — 빈/에러 + 폰트 폴백
- **WHY**: 빈 상태 일원화, Pretendard 미번들 환경 폴백
- **WHAT**: state_views.dart (EmptyStateView/ErrorStateView/LoadingStateView/EmptyInlineCard) / fontFamilyFallback [Pretendard, Apple SD Gothic Neo, Noto Sans KR]
- **RESULT**: 일관성, 폰트 호환

### `2472005` 추천 검증 + 멤버/추천 정비 + 표현 순화
- **WHY**: 라이프스타일 가중 보강, 등록 요청, 순화
- **WHAT**: stress→C, sleep<5h→B6, 음주→B군 + LifestyleSuggestion (음주→간, 수면→melatonin/Mg, 임→prenatal, 식단부족→종합) / "정보 등록 요청" UI + SecureStorage 큐 + manual_entry_hash.dart sha1 / 표현 "영양제 새로 추천받기" → "추천 영양제 보기" / category_detail_screen + 정렬 토글 / ConflictAddDialog "충돌 가능성" → "확인이 필요해요" / 테스트 +17
- **RESULT**: 정확도 향상

### `0342f86` 죽은 정보 출처 차단
- **WHY**: centrum.pchkorea.co.kr DNS 미해석
- **WHAT**: isDeadSourceUrl() + denylist (centrum.pchkorea.co.kr/pchkorea.co.kr) / 테스트 +6
- **RESULT**: UX 개선

### `148b428` SnackBar/Dialog 통일 + 시간대 헤더 + 정렬 칩
- **WHY**: showDialog/showModalBottomSheet 자동 톤
- **WHAT**: ThemeData snackBarTheme(floating + ink + Pretendard) / dialogTheme(r20 + heading3) / bottomSheetTheme(r20 + drag handle) / popupMenuTheme(r12 + body1) / _SlotHeader 이모지 + "아침"(800w) + 카운트 pill / _SortToggle hairline → primarySoft pill
- **RESULT**: UI 일관성

### `e4cf369` 온보딩 4슬라이드
- **WHY**: 가족 단위 차별성, 완료율 향상
- **WHAT**: 4슬라이드 (가족 함께 / 250 검증 / 결정 시점 / 시작) / PageView + 인디케이터 / 라우터 privacy-consent → onboarding(NEW) → welcome → home / SecureKeys.onboardingComplete + ?from=settings 재진입 / Settings "다시 보기" / 테스트 +5
- **RESULT**: 온보딩 완성

### `3bd33c1` 적정 함량 정렬 — 카테고리별 주요 성분
- **WHY**: 적정 함량이 popularity로 폴백 → "판매량"과 중복
- **WHAT**: _kCategoryPrimaryNutrient (liver→silymarin_mg, sleep→melatonin_mg, prenatal→vitamin_b9_mcg, vitamin_d→vitamin_d_iu 등) / 3분기: nutrient → RDI 거리 / 매핑 카테고리 → 함량 desc / 미매핑 → 성분 가짓수 desc / 테스트 +8
- **RESULT**: 정렬 정확화

### `07f1ce2` 추천 카드 재구성 — 판매량/가성비/종합추천
- **WHY**: 적정 함량 폐지, 3티어 명확화
- **WHAT**: kTierBestseller (페르소나 적합 popularity 1위) / kTierValue (Jaccard ≥60% + popularity 더 높음) / kTierComprehensive (deficit 매칭률 desc + multi 보너스 0.15 + 70% 미만 표시 X) / CategoryDetailScreen 정렬 토글 / 테스트 +15
- **RESULT**: 추천 명확화

## 단계 7. 2025 KDRIs 마이그레이션 (커밋 84-88)

### `484c81a` KDRIs 2025 적용 — 매트릭스 단일화 + 콜린
- **WHY**: 2025-12-31 발표 공식 KDRIs 적용
- **WHAT**: kdris_2025.dart 13구간 × 성별 + 임/수 + UL / 16→24종 (신규 B1/B2/B3/B5/biotin/K/copper/manganese, UL 전용 A/E/B6/niacin/Se/I/Cu) / **콜린(425/550 + UL 3500) 신규** / 임/수 가산 (엽산 +220, 철 +10, A +70/+490, 콜린 +25/+125) / JSON migration / 테스트 +29
- **RESULT**: KDRIs 2025 완료

### `5960589` 2025 정렬 — 채팅 옵션 + 알고리즘 + 면책
- **WHY**: 라이프스타일(흡연/음주/수면/스트레스) KDRIs에 별도 권장량 없음 → 의료 상담 위임
- **WHAT**: step 9(흡연)/10(음주)/12(수면)/13(스트레스) → _shouldShow false (필드 보존) / step 11(식단) good/poor 단순화 / step 8 혈액형 8종 / FamilyMember bloodType + chronicConditions / 분석 엔진 가중 모두 제거 → KDRIs만 / 65+ Ca/D/B12 가중 추가 / liver/sleep 라이프스타일 제거 / DisclaimerFooter "2025 KDRIs 기반 일반 정보" / KdrisRecommendationDisclaimer (흡연/음주/수면/스트레스 미정의 + 의사 상담) / ProductInfoDisclaimer
- **RESULT**: KDRIs 정렬, 면책 강화

### `b30e3f3` 슬라이드4 + 영양제 상세 KDRIs 명시
- **WHY**: 사용자가 추천 출처 인지
- **WHAT**: 슬라이드 4 본문 "2025 한국인 영양소 섭취기준(KDRIs) 기반" / 영양제 상세 영양 성분 카드 끝 "권장량/상한 비교는 추천 화면 참조" / ProductInfoDisclaimer
- **RESULT**: 출처 명확화

## 단계 8. V1 출시 검증 + 수정 (커밋 89-92)

### `68c19e3` 폰 테스트 6 이슈
- **WHY**: 7세 아들 등록 시나리오에서 6 이슈
- **WHAT**:
  - FIX1: 영문 키 → 한글 매핑 (3 화면) → nutrientLabel()
  - FIX2: 가성비 = 판매량 → 함량 ±20% + popularity ≥ 6 + focusScore ≥ 30
  - FIX3: 비타민D 카테고리에 락토핏 1순위 → _categoryFocusScore (1-3:100 / ≤5:70 / 8+:30)
  - FIX4: KDRIs 권장량 노출 → /product/:id?member=ID + "X/Y 권장 (Z%)"
  - FIX5: 영양제 0 시 "이 연령대에 자주 부족"
  - FIX6: 가성비 카드 텍스트 잘림 → IntrinsicWidth + softWrap false
- **RESULT**: 6건 해결

### `bbedf40` 자체 검토 출시 차단 4
- **WHY**: 자체 검증 보고서 임계 4건
- **WHAT**:
  - FIX1: bracketForAge(0) 데드 코드 → infant0to5 + 음수 방어
  - FIX2: DietQuality.average dropout → legacy 정규화
  - FIX3: Manual 분석 미반영 → 안내 + snackbar
  - FIX4: 빈 ingredients 26 제품 _SourcePill (✅검증/📋라벨없음/📝직접) + "라벨 직접 확인" 카드
  - 테스트 +9
- **RESULT**: 출시 차단 4건 해결

### `12fe77e` 카테고리 hard filter + 가성비 + 명칭 + 톤다운 5
- **WHY**: 폰 테스트 추가 5건
- **WHAT**:
  - FIX1: 비타민D에 락토핏(probiotics) 노출 → hard filter [메인 영양소 함유] || [카테고리 정합] || [성분 ≤2]
  - FIX2: 가성비 = 같은 브랜드 → differentBrand 우선
  - FIX3: (v2) 등 개발자 명칭 정리 (5건)
  - FIX4: 가족 카드 _StatusDot 톤다운 (영양제 보유 청록 / 미보유 회색)
  - FIX5: dead getter 제거
  - 테스트 +8
- **RESULT**: 5건 해결

### `77dacc8` 전반 검토 — 33 한글 매핑 + 면책 + 시뮬레이션
- **WHY**: A-M 13 카테고리 검토에서 33 한글 매핑 누락
- **WHAT**:
  - [A] 7세 어린이 vitamin_d hard filter 250 시뮬 (락피도+세노비스만 통과)
  - [B] 33 한글 매핑 추가 (진세노사이드 7, 은행잎 4, 콜라겐 펩타이드 3, 베타카로틴 3, BCAA, 5-HTP, 보장균수, 헛개나무, 마카, 옥타코사놀, 피페린, 헴철 등) → **89종 매핑**
  - nutrient_labels_coverage_test (회귀)
  - [C] KDRIs UL 전용(E/B6/niacin/Se/I/Cu) 어린이 셀 공백 → 비교 X (영향 없음)
  - [F] 카테고리 더보기 면책 누락 → KdrisRecommendationDisclaimer
  - [G] 외부 전송 0 (claudeApiKey 빈 → null)
  - [K] release 빌드 비ASCII 경로 Gradle 실패 → 환경
  - 테스트 +1
- **RESULT**: 88% 출시 가능

### `af4a5de` 출시 준비 (외부 의존 X 범위)
- **WHY**: Firebase/AdMob/Console 없이 V1 즉시 가능 항목
- **WHAT**:
  - [8] 법적 문서 정식: 처리방침 10조 + 약관 8조 + 의료 X
  - [7.5] 데이터 내보내기 → alyak_backup_{ts}.json + 클립보드
  - [9.3] AndroidManifest ACCESS_NETWORK_STATE/WAKE_LOCK/VIBRATE
  - [5] AnalyticsService 인터페이스 + NoopAnalyticsService + 18 이벤트
  - [4] AdPolicy (14세 미만/임산부/수유부 차단) + 13 AdSurface + NoopAdSlot
  - [1+2+3+6] firebase_integration_plan.md (외부 5단계 + V2 코드 9개)
- **RESULT**: 출시 준비, 외부 의존 최소화

### `c2141e2` 영양제 상세 권장량 — 999% 캡 + 매트릭스 24 + β-카로틴
- **WHY**: 폰 테스트 UX 충격: "비타민B6 40mg/1.4mg = 999%" / KDRIs 어린이 셀 공백
- **WHAT**:
  - [1] 매트릭스 16→24 + 13구간 풀 (신규 B1/B2/B3/B5/biotin/K/copper/manganese, 어른만→풀 E/B6/niacin/Se/I/Cu) / niacin_mg → vitamin_b3_mg, copper_mcg → copper_mg
  - [2] 999% 캡 + UL 초과 4단계: UL→빨강 / 200%+→회색 (999% 차단) / 100-200%→청록 / 50-99%→녹색 / <50%→주황
  - [3] β-카로틴 → 비타민A 환산 (12 μg = 1 μg RAE): 행 합산 + "+ β-카로틴 환산" 부주석
  - [4] KDRIs 미정의 → "권장량 정보 없음"
  - 테스트 +13 (kdris_2025_extension)
- **RESULT**: UX 충격 완화, 24 커버리지

### `22c235e` (**최신**) 4단계 평가 + 쉬운 표현 + 부족/초과량
- **WHY**: 30-40대 엄마 1초 이해. 999%/250% 충격 % 완전 제거
- **WHAT**:
  - 4단계 라벨 (% 제거):
    - "✅ 충분해요" (90%+, 10% 마진: 철 13.5/14 = "거의 다")
    - "⚠️ 450 mg 부족해요" (절대량)
    - "⚠️ 60 mg 많아요" (절대량)
    - "ℹ️ 정보 없음" (RDA 미정의)
  - 전문 용어: "(KDRIs)" 4곳 / α-TE→mg / RAE→mcg / NE→mg / DFE→mcg
  - "권장량보다 많은 이유" 펼침 카드 (식약처 안전)
  - 테스트 +0 (300/300 회귀, 30 시나리오)
- **RESULT**: **999% 충격 완전 제거, 사용자 경험 극대화**

## 핵심 설계 결정 정리

| # | 결정 | WHY | 커밋 |
|---|---|---|---|
| 1 | 충돌 severity 3단계 + 종합 면제 | 종합 8+ 성분이라 단독 시장 인정 안전, 합산 시만 경고 | 31ba46e, cde7939, 12fe77e |
| 2 | `kSufficientMargin = 0.9` | 사용자 "철분 13.5/14 = 거의 다" 피드백 | c2141e2, 22c235e |
| 3 | `niacin_mg → vitamin_b3_mg` 키 | KDRIs와 products.json 정합. niacin은 conflict UL alias만 | 484c81a |
| 4 | 999% → 4단계 라벨 (2단계 해결) | 폰 테스트 UX 충격, 30-40대 모 이해 못함 | c2141e2(200%+ 캡) → 22c235e(% 완전 제거) |
| 5 | IntakeTiming 카테고리 기본 + 4차 검증 | 250개 라벨 검증 전 카테고리 룰 (1차 82%) → 라벨 보정 | 9566306, ce5c9e2~3f7824e |
| 6 | KDRIs 2025 + 라이프스타일 제거 | 흡연/음주/수면/스트레스 KDRIs 미정의 → 의료 상담 위임 | 484c81a, 5960589 |
| 7 | 프로필 사진 + 시간대 그룹 + 캐싱 | 식별 / 직관 / 효율 | d7f17ba, 4770869 |
| 8 | "정보 등록 요청" 큐 (sha1) | Phase 4 백엔드 통합 키 | 2472005 |
| 9 | 외부 전송 0 (V1) | Claude/Supabase/Firebase placeholder, isConfigured false | af4a5de, 77dacc8 |
| 10 | 카테고리 hard filter | 락토핏(probiotics, vitamin_d_iu 함유)이 비타민D에 노출 → 메인 영양소 + 카테고리 + 성분≤2 | 12fe77e |

---

# PART 8. 출시 체크리스트 / 남은 작업

## ✅ 완료 (V1.0 출시 가능)

- [x] **코드 측 출시 차단 0건** (자체 + 폰 테스트 통과)
- [x] **테스트 300/300 통과** (test/ 29개)
- [x] **flutter analyze clean**
- [x] **products.json 250개 100% 라벨 검증** (verified_date=2026-05-06)
- [x] **제품 사진 250/250 100%** (240×240 q80 ~2.6MB)
- [x] **개인정보 처리방침 정식본** (2026-05-07, v1.0)
- [x] **이용약관 정식본**
- [x] **면책 조항** (`/disclaimer`)
- [x] **데이터 내보내기** (JSON 백업 + 클립보드)
- [x] **데이터 삭제** (이중 확인 — "삭제" 입력)
- [x] **Android 권한 13개 명시** (네트워크/알림/카메라/사진)
- [x] **세션 가드** (30일 만료 → wipe + 재동의)
- [x] **AES-256-GCM 암호화**
- [x] **알림 권한 게이팅** (토글 ON 시 OS 권한, 거부 시 자동 OFF)
- [x] **광고 노출 정책** (no-op이지만 키즈/임/수/영양제 상세 차단 룰셋 정의)
- [x] **Korean 라벨 100% 커버리지** (영문 enum 노출 0)
- [x] **KDRIs 2025 매트릭스 24종** + **89종 한글 매핑**
- [x] **999% 충격 표시 완전 제거** (4단계 평가)
- [x] **screen_security 블러** (활성)
- [x] **충돌 검사 5종 + severity 3단계**
- [x] **3티어 추천** (판매량/가성비/종합)

## ⏳ 남은 작업 — 사용자(선장님) 측 외부 작업

### 1. Google Play Console 등록
- 개발자 계정 ($25, 1회)
- 새 앱 ("알약", "건강/피트니스")
- **Data Safety**: V1은 외부 전송 0건 → 데이터 수집 X로 신고
- 콘텐츠 등급
- **개인정보 처리방침 URL 등록** (예: GitHub Pages → `kPrivacyPolicyMarkdown` 정적 호스팅)

### 2. 앱 서명 키 (출시 1회)
```
keytool -genkey -v -keystore alyak-upload.keystore ...
```
- `android/key.properties` (gitignore 필수)
- `android/app/build.gradle.kts` 현재 `signingConfig = signingConfigs.getByName("debug")` → release 키로 교체
- Google Play App Signing 활성화 권장

### 3. Android 아이콘 / 스플래시
- 현재 `@mipmap/ic_launcher` = Flutter 기본
- **출시 전 알약 아이콘 교체 필수**
- `flutter_launcher_icons` 패키지 검토

### 4. iOS 빌드 (V1 우선순위 X)
- `ios/` 폴더는 있으나 검증 미완
- 별도 시점에 작업

### 5. screen_security FLAG_SECURE / iOS CALayer 재활성화
- 현재 TODO 주석 상태 (테스트 중 비활성)
- 프로덕션 빌드 전 활성화

## 🔮 V2 (Firebase 도입) — `firebase_integration_plan.md`

### 외부 작업 5단계
1. Firebase Console (Auth/Firestore asia-northeast3/FCM/Crashlytics/Analytics)
2. Google Cloud Console OAuth (Google 로그인)
3. AdMob 계정 + 광고 단위 (배너/전면)
4. 앱 서명 (keytool)
5. Play Console (Data Safety 갱신)

### V2 코드 작업
- pubspec.yaml: firebase_core/auth/firestore/messaging/analytics/crashlytics + google_sign_in + google_mobile_ads + share_plus
- android/build.gradle: google-services + crashlytics 플러그인
- main.dart: `Firebase.initializeApp()` + Crashlytics
- `NoopAnalyticsService` → `_FirebaseAnalyticsImpl`
- `NoopAdSlot` → google_mobile_ads BannerAd 래퍼
- 신규: `auth_service.dart` (익명/Google/이메일 + 자동 로그인 + 계정 삭제)
- 신규: `firestore_sync_service.dart` (users/{uid}/family/{memberId} + offline + last-write-wins + 익명→로그인 마이그레이션)
- 신규: `fcm_service.dart` (토큰 → Firestore + Cloud Function 트리거)

### 마이그레이션
- `schemaVersion 1 → 2`
- 사용자 V1→V2 업데이트 시: 첫 진입 로그인 → SecureStorage → Firestore 1회 업로드 → Stream 구독

### 예상 시간
- 외부 1-2일 + 코드 4-6일 + 테스트 2-3일 = **1-2주**

---

# PART 9. 컨벤션 / 트랩

## 9-1. 표시 관련 (필수)

- ❌ **% 표시 금지**: 4단계 라벨(`evaluateNutrient`)만 사용. 999% 같은 숫자 다시 들어오지 않게 감시.
- ❌ **영문 괄호 금지**: "(KDRIs)" 같은 표기 사용자 면 노출 X. 공식 출처 한글로.
- ✅ **단위 단순화**: `simplifyUnit()` 통과 후 노출 (α-TE → mg, RAE → mcg, NE → mg, DFE → mcg).
- ✅ **모든 한글 문구**: `lib/core/l10n/app_strings.dart` 단일화. 인라인 하드코딩 X.
- ✅ **이모지 금지** (사용자 명시 요청 시만): 코드/문서 내 이모지 추가 X.

## 9-2. 데이터 관련

- **products.json 키 ↔ KDRIs 키 매칭**: `niacin_mg` → `vitamin_b3_mg` 통일. niacin은 `conflict_checker` UL alias만. `copper_mcg` ↔ `copper_mg` (products.json은 mg).
- **multivitamin solo overdose 면제**: `_isMultivitaminCategory({'multivitamin', 'kids_multivitamin', 'prenatal'})`. 신규 멀티 카테고리 추가 시 여기에도 등록.
- **products.json 직접 수정 시**:
  - `dose_per_intake × intakes_per_day == daily_dose` 불변식
  - `verified_date` 갱신
  - `scripts/verify_*.py` 검증 통과 후 커밋
  - 라벨 직접 검증 원칙 (top30/multiple/atm_me/remaining 4파트 분할 이력)
- **빈 ingredients 26 제품**: "라벨 미수록" 뱃지 + "라벨 직접 확인" 카드 (회귀 가드 `release_blocker_fixes_test.dart`).

## 9-3. 외부 링크

- **dead-source 필터** (`product_search_links.dart `_kDeadSourceHosts`): 죽은 도메인 추가 시 lower-case + bare host (suffix 매칭).
- **네이버쇼핑 / 쿠팡** URL은 `Uri.encodeQueryComponent` 통과.

## 9-4. 알림

- 채널 ID `supplement_reminder` 고정.
- 멤버별 ID 스코프: `_idFor(memberId, baseId, [suffix])`. 가족 삭제 시 `cancelAllForMember()` 호출.
- 매일/리오더/검진 = **default OFF** (NotificationSetupScreen에서 사용자 명시 ON).

## 9-5. 라우팅

- `/family/:id` → 멤버 없으면 `ErrorStateView` 폴백 (SnackBar 직접 띄우지 말 것).
- `/product/:productId?member=ID` → 멤버 컨텍스트 시 4단계 평가 렌더.

## 9-6. UI 톤다운

- **가족 카드 _StatusDot**: 영양제 보유 → 청록(`primary`) / 미보유 → 매우 밝음(`faint`). **부족/주의 경고는 카드에 표시 X** — 상세 진입 후만.
- **NutrientPriorityCard**: 5개 이하 쉼표, 5+ "A, B, C 외 N개".
- **네이버/쿠팡 버튼**: 라인 (2px 테두리 + 흰 배경). 채움 X.
- **표현**: "복용 중", "챙기시는" → **"섭취중"**.
- **다이얼로그/SnackBar/BottomSheet**: ThemeData가 자동 톤 부여 (`r20`/`floating`/`drag handle`). 개별 스타일링 X.

## 9-7. 테스트

- 코드 수정 후 **항상** `flutter analyze` + `flutter test` 둘 다 깨끗해야 커밋.
- 회귀 가드 추가 패턴: `release_blocker_fixes_test.dart` / `hotfix_test.dart`처럼 issue 단위 테스트 파일 추가.

## 9-8. 보안

- **세션 만료**: 30일 → `SecureStorage.wipe()` + `/privacy-consent`. 변경 시 `SessionGuard._maxIdle` 수정.
- **AES 키**: `alyak.deviceKey.v1`. 키 회전 시 `EncryptionService.rotateKey()` 호출.
- **screen_security 블러**: 디버그 시 비활성 가능. **프로덕션 활성 필수**.

## 9-9. 외부 의존 도입 금지 (V1)

- Firebase / AdMob / share_plus 등 V2 패키지 임의 추가 X.
- 인터페이스 (no-op)만 정의된 상태 유지.
- 추가 필요 시 `firebase_integration_plan.md` 절차 준수.

## 9-10. 사용자 환경

- OS: Windows 11 / PowerShell. 셸 변수 `$env:VAR`, null 체크 `$null -eq`.
- POSIX 명령은 Bash 도구.
- 사용자 메일: `help@sphinfo.co.kr`.
- 커밋 메시지 스타일: `feat:`/`fix:`/`data:`/`design:`/`ui:`/`build:` 프리픽스 + 한글 본문 + Co-Authored-By 라인.
- **모토 = 쉬움**: 30-40대 엄마 1초 이해. 충격 숫자 / 영문 / 전문 용어 제거 일관 정책.

---

# PART 10. 새 Claude에게 전달 팁

## 시작 시 체크

1. **이 문서 통째로 첫 메시지에 첨부**.
2. `git log --oneline -20`로 최신 커밋 확인 (이 문서와 차이 가능).
3. `git status` 깨끗한지 확인.
4. 사용자가 어떤 작업을 원하는지 정확히 파악 후 시작.

## 작업 흐름

1. 사용자 요청 이해
2. 영향받는 도메인 모듈 식별 (KDRIs 24종 / 4단계 평가 / 3티어 추천 / 충돌 5규칙 4개 핵심 + 화면 + 테마)
3. 변경 계획 수립
4. 코드 수정 (PART 9 컨벤션 준수)
5. **필수**: `flutter analyze` + `flutter test` 둘 다 통과
6. 사용자에게 한국어로 간결 보고 후 커밋 (사용자 명시적 요청 시만)

## 자주 받을 가능성 있는 요청

1. **출시 직전 마지막 점검** — analyze + test + 시뮬레이션 → 이슈 보고
2. **앱 아이콘 / 스플래시 교체** — `flutter_launcher_icons` 검토
3. **release 서명 설정** — `key.properties` + `build.gradle.kts`
4. **개인정보 처리방침 URL 호스팅** — GitHub Pages 정적 배포 가이드
5. **추가 영양소 검증 / 폰 테스트 발견 이슈** — 기존 패턴 (회귀 가드 추가)
6. **Firebase V2 시작** — `firebase_integration_plan.md` 절차 단계별
7. **products.json 추가/수정** — `verify_*.py` 검증 + 회귀 테스트
8. **새 영양소 KDRIs 추가** — `kdris_2025.dart` 매트릭스 확장 + `nutrient_labels.dart` 매핑 + 테스트

## 명령어 치트시트

```powershell
flutter pub get             # 의존성
flutter analyze             # 정적 분석
flutter test                # 300개 테스트
flutter run                 # 디버그 (Android 폰 연결)
flutter build apk --release       # APK
flutter build appbundle --release # AAB (Play Store)

git log --oneline -20       # 최신 커밋
git status
```

> Windows / PowerShell — `$env:VAR`, `$null -eq`. POSIX는 Bash 도구.

## 절대 하지 말 것

- ❌ products.json에 검증 안 된 추정 데이터 추가
- ❌ KDRIs 매트릭스 출처 없이 수정
- ❌ Firebase / AdMob / share_plus 등 V2 패키지 V1 단계에서 임의 추가
- ❌ % 표시 부활 (999% / 250% / 200% 등)
- ❌ "(KDRIs)" 영문 괄호 사용자 면 노출
- ❌ `flutter analyze` 또는 `flutter test` 깨진 상태로 커밋
- ❌ `git push --force` 또는 destructive git 명령 사용자 명시 없이
- ❌ 광고/제휴 링크 V1 추가 (V2 인프라 도입 후만)
- ❌ V1에서 외부 서버 통신 (Claude API / Supabase / Firebase 모두 placeholder, 외부 전송 0건 정책)

## 작업 시 모범 답변 템플릿

> 사용자: "비타민 K2 추가해줘"
>
> Claude:
> "비타민K2 추가는 다음 4곳 동기 수정이 필요해요:
> 1. `kdris_2025.dart` — `vitamin_k2_mcg` NutrientReference (출처 필요)
> 2. `nutrient_labels.dart` — '비타민K2' 매핑
> 3. `products.json` — K2 함유 제품 ingredients 키 통일 (현재 `vitamin_k_mcg`/`vitamin_k1_mcg`/`vitamin_k2_mcg` 혼재)
> 4. `kdris_2025_extension_test.dart` — 페르소나별 권장량 회귀 가드
>
> 출처(2025 KDRIs 표) 확인 후 진행할까요? 아니면 K1+K2 합산 vs 분리 방침 결정 먼저?"

---

**끝.** 이 문서로 새 Claude는 92커밋의 맥락 + 도메인 + 컨벤션을 즉시 파악할 수 있어요.
- 도메인 디테일 더 필요하면 `lib/core/data/kdris_2025.dart` 직접 열기
- V2 외부 작업 절차는 `lib/core/firebase/firebase_integration_plan.md`
- 디자인 시안 원본은 `design/Alyak.html` + `screens-*.jsx`

문서 자체 길이: 약 18,000-20,000자 (PART 1-10).
