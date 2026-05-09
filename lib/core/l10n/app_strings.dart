/// Single source for all Korean text in the app.
/// Prepared for future i18n by centralizing strings.
class AppStrings {
  AppStrings._();

  // App
  static const String appName = '알약';
  static const String appTagline = '우리 가족 건강한 영양제 습관';
  static const String appNameSubtitle = '우리 가족 영양제 케어';

  // Common
  static const String next = '다음';
  static const String prev = '이전';
  static const String back = '뒤로';
  static const String done = '완료';
  static const String save = '저장';
  static const String cancel = '취소';
  static const String confirm = '확인';
  static const String close = '닫기';
  static const String edit = '수정';
  static const String delete = '삭제';
  static const String add = '추가';
  static const String skip = '건너뛰기';
  static const String start = '시작하기';
  static const String startNow = '시작하기';
  static const String later = '나중에';
  static const String more = '더보기';
  static const String search = '검색';
  static const String retry = '다시 시도';
  static const String yes = '네';
  static const String no = '아니요';

  // Disclaimer (used app-wide)
  static const String disclaimerText =
      '본 앱은 의사·약사의 전문 진단을 대체하지 않습니다';
  static const String disclaimerNutrient =
      '영양제 복용은 본인의 건강 상태에 맞게 결정해주세요';

  // Welcome
  static const String welcomeMessage1 = '우리 가족의 건강을 위해 💚';
  static const String welcomeMessage2 = '가장 중요한 분을 먼저 등록해요';
  static const String welcomeMessage3 = '바로 사용자님이에요 😊';
  static const String welcomeButtonOwn = '나부터 등록할게요';
  static const String welcomeButtonFamily = '가족 먼저 등록할게요';

  // Privacy consent
  static const String privacyConsentTitle = '개인정보 수집·이용 동의';
  static const String privacyAgreeButton = '동의하고 시작하기';

  // Empty/error states
  static const String loadingText = '잠시만요...';
  static const String emptyFamily = '가족을 추가해보세요';
  static const String addFamily = '가족 추가하기';

  // Navigation
  static const String navHome = '홈';
  static const String navFamily = '가족';
  static const String navSupplements = '영양제';
  static const String navSettings = '설정';

  // Privacy
  static const String privacyTitle = '개인정보 안내';
  static const String privacyConsent = '개인정보 처리에 동의합니다';
  static const String privacyDataLocal = '입력하신 건강 정보는 기기에만 저장돼요';
  static const String privacyEncryption = '민감한 정보는 AES-256으로 암호화돼요';
  static const String privacyMedicalNote =
      '본 앱은 의료 상담을 대체할 수 없으며, 정보 제공 목적으로만 사용돼요';

  // Onboarding
  static const String onboardingWelcome = '우리 가족 영양제 챙기기,\n알약과 함께 시작해요';
  static const String onboardingDesc1 = '가족 한 명 한 명에 맞는 영양제를 추천해드려요';
  static const String onboardingDesc2 = '복용 시간과 조합도 알려드릴게요';
  static const String onboardingDesc3 = '복용 중인 약과 충돌하는 영양제도 알려드려요';

  // Home
  static const String homeGreeting = '안녕하세요 👋';
  static const String homeFamilyTitle = '우리 가족 영양제';
  static const String homeHelpTitle = '🎯 무엇을 도와드릴까요?';
  static const String homeTodaySchedule = '오늘의 복용 일정';
  static const String homeStreak = '연속 복용';
  static const String homeAddFamily = '가족 추가하기';
  static const String homeStartRecommendation = '추천 받기';

  // Home entry points
  static const String entryBuySupplements = '🛒 영양제 새로 사기';
  static const String entryCurrentCheck = '⚠️ 지금 점검';
  static const String entrySymptomSearch = '🥗 컨디션별 영양 가이드';
  static const String entryFamilyManage = '👨‍👩‍👧 가족 관리';

  // Home notifications
  static const String homeNotificationsTitle = '🔔 알림';

  // Empty state
  static const String emptyFamilyTitle = '아직 등록된 가족이 없어요';
  static const String emptyFamilyDescription =
      '가족을 추가하면 영양제 챙기기를 시작할 수 있어요';
  static const String addFamilyButton = '+ 가족 추가하기';

  // Card status
  static const String cardStatusEnough = '충분히 섭취중';
  static const String cardStatusFewDeficitTemplate = '%d개 부족';
  static const String cardCurrentlyTakingTemplate = '%d개 섭취중';
  static const String cardSeeDetail = '상세 보기 →';
  static const String moreItemsCountTemplate = '+%d개 더';
  static const String cardDeficientNutrients = '부족한 영양소';
  static const String cardSufficientNutrients = '잘 섭취중';

  // Quick actions
  static const String quickActionRecommend = '💊 영양제 새로 추천받기';
  static const String quickActionCheck = '⚠️ 지금 먹는 것 점검';
  static const String quickActionEdit = '📝 정보 수정';
  static const String quickActionRemove = '🗑️ 가족에서 제거';
  static const String quickActionManageProducts = '💊 섭취중인 영양제 관리';

  // Member detail
  static const String memberDetailQuickActions = '📋 빠른 액션';
  static const String memberDetailNutritionStatus = '📊 영양 상태 상세';
  static const String memberDetailDeficient = '❌ 부족한 영양소';
  static const String memberDetailSufficient = '✅ 잘 섭취중';
  static const String memberDetailNoData = '아직 분석 데이터가 없어요';
  static const String coverageNotTakingLabel = '안 드심';

  // Family
  static const String familyTitle = '우리 가족';
  static const String familyAdd = '가족 추가';
  static const String familyName = '이름';
  static const String familyAge = '나이';
  static const String familyGender = '성별';
  static const String familyMale = '남성';
  static const String familyFemale = '여성';
  static const String familyAgeGroup = '연령대';
  static const String familyAgeNewborn = '영유아 (0-1세)';
  static const String familyAgeToddler = '유아 (2-6세)';
  static const String familyAgeChild = '어린이 (7-12세)';
  static const String familyAgeTeen = '청소년 (13-18세)';
  static const String familyAgeAdult = '성인 (19-59세)';
  static const String familyAgeElderly = '시니어 (60세 이상)';

  // Lifestyle
  static const String lifestyleTitle = '생활 습관';
  static const String lifestyleSmoking = '흡연';
  static const String lifestyleDrinking = '음주';
  static const String lifestyleDiet = '식습관';
  static const String lifestyleExercise = '운동';
  static const String lifestyleSleep = '수면';
  static const String lifestyleStress = '스트레스';

  // Recommendation
  static const String recoTitle = '맞춤 추천';
  static const String recoMustTake = '꼭 챙겨야 해요';
  static const String recoHighlyRecommended = '추천드려요';
  static const String recoConsiderIf = '필요하면 고려해보세요';
  static const String recoAlreadyTaking = '이미 섭취중';
  static const String recoSchedule = '복용 시간표';
  static const String recoMorning = '아침';
  static const String recoLunch = '점심';
  static const String recoEvening = '저녁';
  static const String recoBeforeSleep = '취침 전';
  static const String recoConflict = '주의가 필요해요';
  static const String recoSynergy = '함께 먹으면 좋아요';

  // Symptom
  static const String symptomTitle = '증상으로 찾기';
  static const String symptomSearchHint = '어떤 증상이 있으세요?';
  static const String symptomTypeBNotice =
      '병원 진료가 필요한 증상이에요. 빠른 시일 내에 의사와 상담하세요';

  // Settings
  static const String settingsTitle = '설정';
  static const String settingsNotification = '알림';
  static const String settingsPrivacy = '개인정보 보호';
  static const String settingsAbout = '앱 정보';
  static const String settingsVersion = '버전';

  // Intake-timing badges — 시간대 그룹 카드 / 검색 결과 / 카테고리 카드에서
  // 영양제별 권장 복용 시점을 사용자 친화 한 줄로 노출. AppColors.primarySoft
  // 배경에 IntakeTimingBadge 위젯이 그대로 사용.
  static const String intakeBadgeAnyTimeAfterMeal = '식후 아무 때나';
  static const String intakeBadgeMultiple = '묶어 드셔도 OK';
  static const String intakeBadgeMorningEmpty = '공복 권장';
  static const String intakeBadgeMorningAfter = '아침 식후';
  static const String intakeBadgeLunchAfter = '점심 식후';
  static const String intakeBadgeDinnerAfter = '저녁 식후';
  static const String intakeBadgeBeforeSleep = '잠들기 전';
  static const String intakeBadgeWithMeal = '식사 중';

  // Disclaimer
  static const String disclaimerNotMedicalAdvice =
      '의료 조언이 아니에요. 복용 전 의사 또는 약사와 상의하세요';

  /// 식품표시광고법 시행령 별표1 면제 조건 충족 문구.
  /// 가이드라인 핵심 표현 "제품과 직접적인 관련이 없습니다"를 반드시 포함.
  static const String conditionScreenLegalDisclaimer =
      '본 화면의 컨디션 정보는 일반 영양학 정보이며, '
      '표시되는 영양제 제품의 기능성·효과와는 직접적인 관련이 없습니다. '
      '컨디션이 지속되면 의료진과 상담하세요.';

  // Errors
  static const String errorGeneric = '문제가 발생했어요. 다시 시도해주세요';
  static const String errorNetwork = '네트워크 연결을 확인해주세요';
  static const String errorLoadingData = '데이터를 불러오지 못했어요';

  // Shop / affiliate
  static const String affiliateDisclosure =
      '본 앱은 일부 구매 링크에서 수수료를 받을 수 있어요';
  static const String affiliateNoteShort = '구매 시 수수료를 받아요';
  static const String shopNaver = '네이버 쇼핑';
  static const String shopCoupang = '쿠팡';
  static const String shopIherb = 'iHerb';
  static const String compareSearchPrice = '가격 비교';
  static const String buyHere = '구매하기';
}
