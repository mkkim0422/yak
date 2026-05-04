import '../../../core/data/models/family_input.dart' as input_model;
import '../../../core/data/models/health_checkup_model.dart' as legacy_checkup;

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

enum AgeGroup { newborn, toddler, child, teen, adult, elderly }

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

class HealthCheckup {
  final DateTime checkupDate;
  final double? totalCholesterol;
  final double? ldl;
  final double? hdl;
  final double? triglycerides;
  final double? fastingGlucose;
  final double? hba1c;
  final double? hemoglobin;
  final double? alt;
  final double? ast;
  final double? vitaminD;
  final int? systolicBp;
  final int? diastolicBp;
  final bool importedFromHealthApp;

  const HealthCheckup({
    required this.checkupDate,
    this.totalCholesterol,
    this.ldl,
    this.hdl,
    this.triglycerides,
    this.fastingGlucose,
    this.hba1c,
    this.hemoglobin,
    this.alt,
    this.ast,
    this.vitaminD,
    this.systolicBp,
    this.diastolicBp,
    this.importedFromHealthApp = false,
  });

  Map<String, dynamic> toJson() => {
        'checkup_date': checkupDate.toIso8601String(),
        'total_cholesterol': totalCholesterol,
        'ldl': ldl,
        'hdl': hdl,
        'triglycerides': triglycerides,
        'fasting_glucose': fastingGlucose,
        'hba1c': hba1c,
        'hemoglobin': hemoglobin,
        'alt': alt,
        'ast': ast,
        'vitamin_d': vitaminD,
        'systolic_bp': systolicBp,
        'diastolic_bp': diastolicBp,
        'imported_from_health_app': importedFromHealthApp,
      };

  factory HealthCheckup.fromJson(Map<String, dynamic> json) => HealthCheckup(
        checkupDate: DateTime.parse(json['checkup_date'] as String),
        totalCholesterol: (json['total_cholesterol'] as num?)?.toDouble(),
        ldl: (json['ldl'] as num?)?.toDouble(),
        hdl: (json['hdl'] as num?)?.toDouble(),
        triglycerides: (json['triglycerides'] as num?)?.toDouble(),
        fastingGlucose: (json['fasting_glucose'] as num?)?.toDouble(),
        hba1c: (json['hba1c'] as num?)?.toDouble(),
        hemoglobin: (json['hemoglobin'] as num?)?.toDouble(),
        alt: (json['alt'] as num?)?.toDouble(),
        ast: (json['ast'] as num?)?.toDouble(),
        vitaminD: (json['vitamin_d'] as num?)?.toDouble(),
        systolicBp: (json['systolic_bp'] as num?)?.toInt(),
        diastolicBp: (json['diastolic_bp'] as num?)?.toInt(),
        importedFromHealthApp:
            (json['imported_from_health_app'] as bool?) ?? false,
      );

  /// Bridge to the legacy [legacy_checkup.HealthCheckup] used by the
  /// recommendation engine.
  legacy_checkup.HealthCheckup toLegacy() => legacy_checkup.HealthCheckup(
        checkupDate: checkupDate,
        cholesterolTotal: totalCholesterol,
        cholesterolLdl: ldl,
        cholesterolHdl: hdl,
        bloodSugar: fastingGlucose,
        hemoglobin: hemoglobin,
        alt: alt,
        ast: ast,
        vitaminD: vitaminD,
        bloodPressureSystolic: systolicBp?.toDouble(),
        bloodPressureDiastolic: diastolicBp?.toDouble(),
      );
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
  final int age;
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

  // Checkup
  final HealthCheckup? lastCheckup;

  // Symptoms
  final List<String> activeSymptomIds;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    required this.age,
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
    this.lastCheckup,
    this.activeSymptomIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convenience: `lastCheckup?.checkupDate`.
  DateTime? get lastCheckupDate => lastCheckup?.checkupDate;

  String get avatarEmoji {
    switch (relationship) {
      case Relationship.self:
        return '👤';
      case Relationship.husband:
        return '👨';
      case Relationship.wife:
        return '👩';
      case Relationship.son:
        return age < 13 ? '👦' : '🧑';
      case Relationship.daughter:
        return age < 13 ? '👧' : '🧑';
      case Relationship.father:
        return age >= 65 ? '👴' : '👨';
      case Relationship.mother:
        return age >= 65 ? '👵' : '👩';
      case Relationship.other:
        return '🙂';
    }
  }

  AgeGroup get ageGroup {
    if (age < 1) return AgeGroup.newborn;
    if (age < 3) return AgeGroup.toddler;
    if (age < 13) return AgeGroup.child;
    if (age < 19) return AgeGroup.teen;
    if (age < 65) return AgeGroup.adult;
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
      currentSupplements: medications,
      currentProductIds: currentProductIds,
      symptomIds: activeSymptomIds,
      lastCheckup: lastCheckup?.toLegacy(),
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
      case AgeGroup.elderly:
        return input_model.AgeGroup.elderly;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'relationship': relationship.name,
        'age': age,
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
        'last_checkup': lastCheckup?.toJson(),
        'active_symptom_ids': activeSymptomIds,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    final manuals = (json['manual_products'] as List?) ?? const [];
    return FamilyMember(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      relationship: RelationshipX.fromJson(json['relationship']),
      age: (json['age'] as num?)?.toInt() ?? 0,
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
      lastCheckup: json['last_checkup'] == null
          ? null
          : HealthCheckup.fromJson(
              json['last_checkup'] as Map<String, dynamic>),
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
    int? age,
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
    HealthCheckup? lastCheckup,
    bool clearLastCheckup = false,
    List<String>? activeSymptomIds,
    DateTime? updatedAt,
  }) =>
      FamilyMember(
        id: id,
        name: name ?? this.name,
        relationship: relationship ?? this.relationship,
        age: age ?? this.age,
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
        lastCheckup: clearLastCheckup ? null : (lastCheckup ?? this.lastCheckup),
        activeSymptomIds: activeSymptomIds ?? this.activeSymptomIds,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );
}
