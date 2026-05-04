import '../../../core/data/models/family_input.dart' as input_model;

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
  final String? imagePath;
  final Map<String, double> ingredients;
  final DateTime startedAt;

  const ManualProductEntry({
    required this.id,
    required this.name,
    this.brand,
    required this.category,
    required this.dailyDose,
    required this.packageSize,
    this.priceKrw,
    this.imagePath,
    required this.ingredients,
    required this.startedAt,
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
        'ingredients': ingredients,
        'started_at': startedAt.toIso8601String(),
      };

  factory ManualProductEntry.fromJson(Map<String, dynamic> json) {
    final ing = (json['ingredients'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    return ManualProductEntry(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      brand: json['brand'] as String?,
      category: (json['category'] as String?) ?? '',
      dailyDose: (json['daily_dose'] as num?)?.toInt() ?? 1,
      packageSize: (json['package_size'] as num?)?.toInt() ?? 0,
      priceKrw: (json['price_krw'] as num?)?.toInt(),
      imagePath: json['image_path'] as String?,
      ingredients: ing.map(
        (key, value) => MapEntry(key, (value as num?)?.toDouble() ?? 0),
      ),
      startedAt: DateTime.parse(json['started_at'] as String),
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
    Map<String, double>? ingredients,
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
        ingredients: ingredients ?? this.ingredients,
        startedAt: startedAt,
      );
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

  // Current supplements
  final List<String> currentProductIds;
  final List<ManualProductEntry> manualProducts;

  // Symptoms
  final List<String> activeSymptomIds;

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
    this.dietQuality = DietQuality.average,
    this.sleepHours = SleepHours.sevenToNine,
    this.stressLevel = StressLevel.low,
    this.allergies = const [],
    this.medications = const [],
    this.isPregnant = false,
    this.isBreastfeeding = false,
    this.currentProductIds = const [],
    this.manualProducts = const [],
    this.activeSymptomIds = const [],
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
        'current_product_ids': currentProductIds,
        'manual_products': manualProducts.map((p) => p.toJson()).toList(),
        'active_symptom_ids': activeSymptomIds,
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
      dietQuality: _enumByName(
          DietQuality.values, json['diet_quality'], DietQuality.average),
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
      currentProductIds: ((json['current_product_ids'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      manualProducts: manuals
          .map((e) => ManualProductEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeSymptomIds: ((json['active_symptom_ids'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
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
    List<String>? currentProductIds,
    List<ManualProductEntry>? manualProducts,
    List<String>? activeSymptomIds,
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
        currentProductIds: currentProductIds ?? this.currentProductIds,
        manualProducts: manualProducts ?? this.manualProducts,
        activeSymptomIds: activeSymptomIds ?? this.activeSymptomIds,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );
}
