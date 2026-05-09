import '../../../core/data/models/family_input.dart' as input_model;
import '../../../core/data/models/product_model.dart'
    show IntakeTiming, IntakeTimingX;

/// Relationship of a family member to the primary user.
enum Relationship {
  self,
  husband,
  wife,
  son,
  daughter,
  father,
  mother,
  other,
}

extension RelationshipX on Relationship {
  String get label {
    switch (this) {
      case Relationship.self:
        return '본인';
      case Relationship.husband:
        return '남편';
      case Relationship.wife:
        return '아내';
      case Relationship.son:
        return '아들';
      case Relationship.daughter:
        return '딸';
      case Relationship.father:
        return '아빠';
      case Relationship.mother:
        return '엄마';
      case Relationship.other:
        return '가족';
    }
  }

  String toJsonValue() => name;

  static Relationship fromJson(Object? raw) {
    if (raw is! String) return Relationship.other;
    return Relationship.values.firstWhere(
      (r) => r.name == raw,
      orElse: () => Relationship.other,
    );
  }
}

enum Sex { male, female }

extension SexX on Sex {
  String get label => this == Sex.male ? '남' : '여';
  String toJsonValue() => name;
  static Sex fromJson(Object? raw) =>
      raw == 'female' ? Sex.female : Sex.male;
}

enum AgeGroup { newborn, toddler, child, teen, adult, middleAged, elderly }

enum SmokingStatus { never, former, current }

enum DrinkingFrequency { never, weekly, daily }

enum DietQuality { poor, average, good }

enum SleepHours { less5, fiveToSeven, sevenToNine, more9 }

enum StressLevel { low, medium, high }

T _enumByName<T extends Enum>(List<T> values, Object? raw, T fallback) {
  if (raw is! String) return fallback;
  for (final v in values) {
    if (v.name == raw) return v;
  }
  return fallback;
}

class ManualProductEntry {
  final String id;
  final String name;
  final String? brand;
  final String category;
  final int dailyDose;
  final int packageSize;
  final int? priceKrw;

  /// V1 active. 직접 입력 항목의 약통 사진 — 본인 식별용 private 사진.
  /// `<appDocs>/manual_products/<id>_<ts>.jpg`에 저장되며 외부 전송 X.
  /// V1.x에서도 본인 카드/시간대 그룹 썸네일에서만 사용.
  final String? imagePath;

  /// V1.x 예정 (미활성). 사용자가 "다른 사용자에게도 도움될 수 있다"고
  /// 명시 동의한 사진의 경로. [imagePath]와 분리해 동의 게이팅을 명확히
  /// 하기 위함 — UI에서 "공유할게요" 토글 후 별도 저장. 클라우드 동기화
  /// 시 본 필드만 업로드 후보가 됨.
  ///
  /// 참고: 큐레이션 [Product] (250 DB 항목)에 사용자 사진을 부착하려면
  /// [UserProductPhoto] 컬렉션을 사용. ManualProductEntry의 본 필드는
  /// 직접 입력 항목 자체에 한정.
  final String? userPhotoPath;

  final Map<String, double> ingredients;
  final DateTime startedAt;

  /// V1.x 예정 (미활성, 모델만 보유). 복용 종료일 — 사용자가 "더 이상
  /// 안 먹어요"를 누르면 기록. null = 진행 중. V1.x에서 누적 기록·재구매
  /// 분석에 활용.
  final DateTime? endedAt;

  /// V1.x 예정 (미활성, 모델만 보유). 사용자 후기 메모 — 200자 제한,
  /// sanitize 후 저장. null/빈 문자열 = 후기 없음.
  ///
  /// 참고: 큐레이션 [Product]에 대한 후기는 [UserProductReview] 컬렉션을
  /// 사용. 본 필드는 직접 입력 항목 자체에 한정.
  final String? review;

  /// When the user takes the product. Defaults to anyTimeAfterMeal for
  /// legacy entries that predate this field.
  final IntakeTiming intakeTiming;

  /// Quantity per single intake. Invariant: dosePerIntake * intakesPerDay
  /// == dailyDose.
  final int dosePerIntake;

  /// Daily intake count.
  final int intakesPerDay;

  /// Free-form text — "공복 또는 식전 30분", "분복 권장" 같은 사용자
  /// 메모를 그대로 보존.
  final String? intakeNote;

  /// 후기 메모 최대 길이 — UI 측에서도 동일 상수를 참조하여 강제.
  static const int kMaxReviewLength = 200;

  const ManualProductEntry({
    required this.id,
    required this.name,
    this.brand,
    required this.category,
    required this.dailyDose,
    required this.packageSize,
    this.priceKrw,
    this.imagePath,
    this.userPhotoPath,
    required this.ingredients,
    required this.startedAt,
    this.endedAt,
    this.review,
    this.intakeTiming = IntakeTiming.anyTimeAfterMeal,
    this.dosePerIntake = 1,
    this.intakesPerDay = 1,
    this.intakeNote,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'category': category,
        'daily_dose': dailyDose,
        'package_size': packageSize,
        'price_krw': priceKrw,
        'image_path': imagePath,
        'user_photo_path': userPhotoPath,
        'ingredients': ingredients,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'review': review,
        'intake_timing': intakeTiming.name,
        'dose_per_intake': dosePerIntake,
        'intakes_per_day': intakesPerDay,
        'intake_note': intakeNote,
      };

  factory ManualProductEntry.fromJson(Map<String, dynamic> json) {
    final ing = (json['ingredients'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    final dailyDose = (json['daily_dose'] as num?)?.toInt() ?? 1;
    final dose = (json['dose_per_intake'] as num?)?.toInt();
    final n = (json['intakes_per_day'] as num?)?.toInt();

    // Migration: legacy entries lack the new fields → default to once-daily
    // single dose. dailyDose stays untouched for analysis-engine compat.
    final resolvedDose = dose ?? dailyDose;
    final resolvedN = n ?? 1;

    final timingRaw = json['intake_timing'];
    final timing = timingRaw is String
        ? IntakeTiming.values.firstWhere(
            (t) => t.name == timingRaw,
            orElse: () => IntakeTiming.anyTimeAfterMeal,
          )
        : IntakeTiming.anyTimeAfterMeal;

    // V1.x에 활성화될 옵셔널 필드 — legacy entry는 누락 → null로 안전하게
    // 폴백. ended_at은 ISO8601 문자열 또는 null.
    final endedAtRaw = json['ended_at'];
    final endedAt = endedAtRaw is String && endedAtRaw.isNotEmpty
        ? DateTime.tryParse(endedAtRaw)
        : null;

    return ManualProductEntry(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      brand: json['brand'] as String?,
      category: (json['category'] as String?) ?? '',
      dailyDose: dailyDose,
      packageSize: (json['package_size'] as num?)?.toInt() ?? 0,
      priceKrw: (json['price_krw'] as num?)?.toInt(),
      imagePath: json['image_path'] as String?,
      userPhotoPath: json['user_photo_path'] as String?,
      ingredients: ing.map(
        (key, value) => MapEntry(key, (value as num?)?.toDouble() ?? 0),
      ),
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: endedAt,
      review: json['review'] as String?,
      intakeTiming: timing,
      dosePerIntake: resolvedDose < 1 ? 1 : resolvedDose,
      intakesPerDay: resolvedN < 1 ? 1 : resolvedN,
      intakeNote: json['intake_note'] as String?,
    );
  }

  ManualProductEntry copyWith({
    String? name,
    String? brand,
    String? category,
    int? dailyDose,
    int? packageSize,
    int? priceKrw,
    String? imagePath,
    String? userPhotoPath,
    Map<String, double>? ingredients,
    DateTime? endedAt,
    String? review,
    IntakeTiming? intakeTiming,
    int? dosePerIntake,
    int? intakesPerDay,
    String? intakeNote,
  }) =>
      ManualProductEntry(
        id: id,
        name: name ?? this.name,
        brand: brand ?? this.brand,
        category: category ?? this.category,
        dailyDose: dailyDose ?? this.dailyDose,
        packageSize: packageSize ?? this.packageSize,
        priceKrw: priceKrw ?? this.priceKrw,
        imagePath: imagePath ?? this.imagePath,
        userPhotoPath: userPhotoPath ?? this.userPhotoPath,
        ingredients: ingredients ?? this.ingredients,
        startedAt: startedAt,
        endedAt: endedAt ?? this.endedAt,
        review: review ?? this.review,
        intakeTiming: intakeTiming ?? this.intakeTiming,
        dosePerIntake: dosePerIntake ?? this.dosePerIntake,
        intakesPerDay: intakesPerDay ?? this.intakesPerDay,
        intakeNote: intakeNote ?? this.intakeNote,
      );

  /// 사용자 행동 정렬 — 분산 표시 대신 "하루 N정" 단순 형태. 시점은
  /// [IntakeTimingX.badgeText] 뱃지로 별도 노출 (Product.scheduleLabel과 동일).
  String get scheduleLabel => '하루 $dailyDose정';
}

class FamilyMember {
  final String id;
  final String name;
  final Relationship relationship;

  /// Birth year (e.g. 1990). Persistent — `age` is derived from this on
  /// every read so the value auto-increments each calendar year without
  /// any background job.
  final int birthYear;
  final Sex sex;
  final double? heightCm;
  final double? weightKg;

  // Lifestyle
  final SmokingStatus smokingStatus;
  final DrinkingFrequency drinkingFrequency;
  final DietQuality dietQuality;
  final SleepHours sleepHours;
  final StressLevel stressLevel;

  // Health
  final List<String> allergies;
  final List<String> medications;
  final bool isPregnant;
  final bool isBreastfeeding;

  /// ABO + Rh blood type — `'A+' / 'B-' / 'O+' / 'AB+' / ...`. Optional;
  /// purely informational (not used by the recommender or KDRIs analysis).
  /// `null` means the user skipped the question.
  final String? bloodType;

  /// User-reported chronic conditions ("고혈압", "당뇨", "갑상선" 등).
  /// Optional. Surfaced in the UI as "의사 상담 우선" guidance — the
  /// recommender does NOT branch on these because KDRIs has no
  /// condition-specific RDAs.
  final List<String> chronicConditions;

  // Current supplements
  final List<String> currentProductIds;
  final List<ManualProductEntry> manualProducts;

  // Symptoms
  final List<String> activeSymptomIds;

  /// Absolute path to a JPEG copied into app-internal storage. Null means
  /// fall back to [avatarEmoji]. Cleared when the user resets the photo.
  final String? profileImagePath;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    required this.birthYear,
    required this.sex,
    this.heightCm,
    this.weightKg,
    this.smokingStatus = SmokingStatus.never,
    this.drinkingFrequency = DrinkingFrequency.never,
    // KDRIs 2025 정렬 — 채팅이 균형/부족 2지선만 받으므로 default를 'good'
    // 으로 변경. 'average'는 legacy 멤버 호환을 위해 enum에 남겨두지만,
    // edit 화면 dropdown items는 good/poor 2개라 average는 hydrate에서
    // 정규화해 dropdown assertion을 피합니다 (family_edit_screen 참조).
    this.dietQuality = DietQuality.good,
    this.sleepHours = SleepHours.sevenToNine,
    this.stressLevel = StressLevel.low,
    this.allergies = const [],
    this.medications = const [],
    this.isPregnant = false,
    this.isBreastfeeding = false,
    this.bloodType,
    this.chronicConditions = const [],
    this.currentProductIds = const [],
    this.manualProducts = const [],
    this.activeSymptomIds = const [],
    this.profileImagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  /// "Korean age" in the simple "current year - birth year" form, which
  /// matches how the spec asks us to display 만 X세 throughout the UI.
  int get age => DateTime.now().year - birthYear;

  /// Convenience formatter ("만 X세").
  String get ageLabel => '만 $age세';

  String get avatarEmoji {
    final a = age;
    switch (relationship) {
      case Relationship.self:
        return '👤';
      case Relationship.husband:
        return '👨';
      case Relationship.wife:
        return '👩';
      case Relationship.son:
        return a < 13 ? '👦' : '🧑';
      case Relationship.daughter:
        return a < 13 ? '👧' : '🧑';
      case Relationship.father:
        return a >= 65 ? '👴' : '👨';
      case Relationship.mother:
        return a >= 65 ? '👵' : '👩';
      case Relationship.other:
        return '🙂';
    }
  }

  AgeGroup get ageGroup {
    final a = age;
    if (a < 1) return AgeGroup.newborn;
    if (a < 4) return AgeGroup.toddler;
    if (a < 13) return AgeGroup.child;
    if (a < 19) return AgeGroup.teen;
    if (a < 50) return AgeGroup.adult;
    if (a < 65) return AgeGroup.middleAged;
    return AgeGroup.elderly;
  }

  /// Project to the legacy recommendation-engine input shape.
  input_model.FamilyInput toFamilyInput() {
    return input_model.FamilyInput(
      name: name,
      age: age,
      gender: sex == Sex.male
          ? input_model.Gender.male
          : input_model.Gender.female,
      ageGroup: _legacyAgeGroup(),
      smoker: smokingStatus == SmokingStatus.current,
      drinker: drinkingFrequency != DrinkingFrequency.never,
      drinkingFrequency: switch (drinkingFrequency) {
        DrinkingFrequency.never => null,
        DrinkingFrequency.weekly => input_model.DrinkingFrequency.weekly,
        DrinkingFrequency.daily => input_model.DrinkingFrequency.frequent,
      },
      diet: switch (dietQuality) {
        DietQuality.poor => input_model.Diet.western,
        DietQuality.average => input_model.Diet.mixed,
        DietQuality.good => input_model.Diet.korean,
      },
      sleepLevel: switch (sleepHours) {
        SleepHours.less5 => input_model.SleepLevel.poor,
        SleepHours.fiveToSeven => input_model.SleepLevel.fair,
        SleepHours.sevenToNine => input_model.SleepLevel.good,
        SleepHours.more9 => input_model.SleepLevel.excellent,
      },
      stressLevel: switch (stressLevel) {
        StressLevel.low => input_model.StressLevel.low,
        StressLevel.medium => input_model.StressLevel.moderate,
        StressLevel.high => input_model.StressLevel.high,
      },
      hasAllergies: allergies.isNotEmpty,
      allergies: allergies,
      heightCm: heightCm,
      weightKg: weightKg,
      takingMedications: medications.isNotEmpty,
      isPregnant: isPregnant,
      isBreastfeeding: isBreastfeeding,
      currentSupplements: medications,
      currentProductIds: currentProductIds,
      symptomIds: activeSymptomIds,
    );
  }

  input_model.AgeGroup _legacyAgeGroup() {
    switch (ageGroup) {
      case AgeGroup.newborn:
        return input_model.AgeGroup.newborn;
      case AgeGroup.toddler:
        return input_model.AgeGroup.toddler;
      case AgeGroup.child:
        return input_model.AgeGroup.child;
      case AgeGroup.teen:
        return input_model.AgeGroup.teen;
      case AgeGroup.adult:
        return input_model.AgeGroup.adult;
      case AgeGroup.middleAged:
        return input_model.AgeGroup.adult;
      case AgeGroup.elderly:
        return input_model.AgeGroup.elderly;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'relationship': relationship.name,
        'birth_year': birthYear,
        'sex': sex.name,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'smoking_status': smokingStatus.name,
        'drinking_frequency': drinkingFrequency.name,
        'diet_quality': dietQuality.name,
        'sleep_hours': sleepHours.name,
        'stress_level': stressLevel.name,
        'allergies': allergies,
        'medications': medications,
        'is_pregnant': isPregnant,
        'is_breastfeeding': isBreastfeeding,
        'blood_type': bloodType,
        'chronic_conditions': chronicConditions,
        'current_product_ids': currentProductIds,
        'manual_products': manualProducts.map((p) => p.toJson()).toList(),
        'active_symptom_ids': activeSymptomIds,
        'profile_image_path': profileImagePath,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    final manuals = (json['manual_products'] as List?) ?? const [];

    // Migration: old payloads stored 'age' instead of 'birth_year'. Map
    // it to a synthetic birthYear (currentYear - age) so existing rosters
    // survive the schema change.
    int birthYear;
    final byRaw = json['birth_year'];
    if (byRaw is num) {
      birthYear = byRaw.toInt();
    } else {
      final ageRaw = (json['age'] as num?)?.toInt() ?? 0;
      birthYear = DateTime.now().year - ageRaw;
    }

    return FamilyMember(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      relationship: RelationshipX.fromJson(json['relationship']),
      birthYear: birthYear,
      sex: SexX.fromJson(json['sex']),
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      smokingStatus: _enumByName(
          SmokingStatus.values, json['smoking_status'], SmokingStatus.never),
      drinkingFrequency: _enumByName(DrinkingFrequency.values,
          json['drinking_frequency'], DrinkingFrequency.never),
      // Legacy 멤버는 'average'로 저장돼 있을 수 있음 — fromJson은 그대로
       // 보존하되, 신규/누락 케이스의 폴백은 'good'으로 변경.
      dietQuality: _enumByName(
          DietQuality.values, json['diet_quality'], DietQuality.good),
      sleepHours: _enumByName(
          SleepHours.values, json['sleep_hours'], SleepHours.sevenToNine),
      stressLevel:
          _enumByName(StressLevel.values, json['stress_level'], StressLevel.low),
      allergies: ((json['allergies'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      medications: ((json['medications'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      isPregnant: (json['is_pregnant'] as bool?) ?? false,
      isBreastfeeding: (json['is_breastfeeding'] as bool?) ?? false,
      bloodType: json['blood_type'] as String?,
      chronicConditions: ((json['chronic_conditions'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      currentProductIds: ((json['current_product_ids'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      manualProducts: manuals
          .map((e) => ManualProductEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeSymptomIds: ((json['active_symptom_ids'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      profileImagePath: json['profile_image_path'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  FamilyMember copyWith({
    String? name,
    Relationship? relationship,
    int? birthYear,
    Sex? sex,
    double? heightCm,
    double? weightKg,
    SmokingStatus? smokingStatus,
    DrinkingFrequency? drinkingFrequency,
    DietQuality? dietQuality,
    SleepHours? sleepHours,
    StressLevel? stressLevel,
    List<String>? allergies,
    List<String>? medications,
    bool? isPregnant,
    bool? isBreastfeeding,
    Object? bloodType = _unset,
    List<String>? chronicConditions,
    List<String>? currentProductIds,
    List<ManualProductEntry>? manualProducts,
    List<String>? activeSymptomIds,
    Object? profileImagePath = _unset,
    DateTime? updatedAt,
  }) =>
      FamilyMember(
        id: id,
        name: name ?? this.name,
        relationship: relationship ?? this.relationship,
        birthYear: birthYear ?? this.birthYear,
        sex: sex ?? this.sex,
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        smokingStatus: smokingStatus ?? this.smokingStatus,
        drinkingFrequency: drinkingFrequency ?? this.drinkingFrequency,
        dietQuality: dietQuality ?? this.dietQuality,
        sleepHours: sleepHours ?? this.sleepHours,
        stressLevel: stressLevel ?? this.stressLevel,
        allergies: allergies ?? this.allergies,
        medications: medications ?? this.medications,
        isPregnant: isPregnant ?? this.isPregnant,
        isBreastfeeding: isBreastfeeding ?? this.isBreastfeeding,
        bloodType: identical(bloodType, _unset)
            ? this.bloodType
            : bloodType as String?,
        chronicConditions: chronicConditions ?? this.chronicConditions,
        currentProductIds: currentProductIds ?? this.currentProductIds,
        manualProducts: manualProducts ?? this.manualProducts,
        activeSymptomIds: activeSymptomIds ?? this.activeSymptomIds,
        profileImagePath: identical(profileImagePath, _unset)
            ? this.profileImagePath
            : profileImagePath as String?,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );
}

/// Sentinel used by [FamilyMember.copyWith] to distinguish "leave as is"
/// from "explicitly set to null" for nullable fields like profileImagePath.
const Object _unset = Object();
