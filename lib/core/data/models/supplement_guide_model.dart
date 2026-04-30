enum SupplementCategory {
  fatSolubleVitamin,
  waterSolubleVitamin,
  mineral,
  essentialFattyAcid,
  probiotic,
  antioxidant,
  protein,
  joint,
  liver,
  weight,
  performance,
  mood,
  sleep,
  complex,
  unknown,
}

SupplementCategory _categoryFrom(String? raw) {
  switch (raw) {
    case 'fat_soluble_vitamin':
      return SupplementCategory.fatSolubleVitamin;
    case 'water_soluble_vitamin':
      return SupplementCategory.waterSolubleVitamin;
    case 'mineral':
      return SupplementCategory.mineral;
    case 'essential_fatty_acid':
      return SupplementCategory.essentialFattyAcid;
    case 'probiotic':
      return SupplementCategory.probiotic;
    case 'antioxidant':
      return SupplementCategory.antioxidant;
    case 'protein':
      return SupplementCategory.protein;
    case 'joint':
      return SupplementCategory.joint;
    case 'liver':
      return SupplementCategory.liver;
    case 'weight':
      return SupplementCategory.weight;
    case 'performance':
      return SupplementCategory.performance;
    case 'mood':
      return SupplementCategory.mood;
    case 'sleep':
      return SupplementCategory.sleep;
    case 'complex':
      return SupplementCategory.complex;
    default:
      return SupplementCategory.unknown;
  }
}

enum BestTime { morning, afternoon, evening, beforeSleep, anytime }

BestTime _bestTimeFrom(String? raw) {
  switch (raw) {
    case 'morning':
      return BestTime.morning;
    case 'afternoon':
      return BestTime.afternoon;
    case 'evening':
      return BestTime.evening;
    case 'before_sleep':
      return BestTime.beforeSleep;
    default:
      return BestTime.anytime;
  }
}

class TimingInfo {
  final BestTime bestTime;
  final String mealRelation;
  final String reason;

  const TimingInfo({
    required this.bestTime,
    required this.mealRelation,
    required this.reason,
  });

  factory TimingInfo.fromJson(Map<String, dynamic> json) => TimingInfo(
        bestTime: _bestTimeFrom(json['best_time'] as String?),
        mealRelation: (json['meal_relation'] as String?) ?? 'with_food',
        reason: (json['reason'] as String?) ?? '',
      );
}

class DosageBand {
  final double amount;
  final String unit;

  const DosageBand({required this.amount, required this.unit});

  factory DosageBand.fromJson(Map<String, dynamic> json) => DosageBand(
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        unit: (json['unit'] as String?) ?? '',
      );
}

class DosageInfo {
  final DosageBand adult;
  final DosageBand? child7to12;
  final DosageBand? teen13to18;
  final DosageBand? elderly60plus;
  final double? upperLimit;

  const DosageInfo({
    required this.adult,
    this.child7to12,
    this.teen13to18,
    this.elderly60plus,
    this.upperLimit,
  });

  factory DosageInfo.fromJson(Map<String, dynamic> json) {
    DosageBand? optional(String key) {
      final raw = json[key];
      if (raw is! Map<String, dynamic>) return null;
      return DosageBand.fromJson(raw);
    }

    return DosageInfo(
      adult: DosageBand.fromJson(
        (json['adult'] as Map<String, dynamic>?) ?? const {},
      ),
      child7to12: optional('child_7_12'),
      teen13to18: optional('teen_13_18'),
      elderly60plus: optional('elderly_60plus'),
      upperLimit: (json['upper_limit'] as num?)?.toDouble(),
    );
  }

  DosageBand bandForAge(int age) {
    if (age >= 60 && elderly60plus != null) return elderly60plus!;
    if (age >= 19) return adult;
    if (age >= 13 && teen13to18 != null) return teen13to18!;
    if (age >= 7 && child7to12 != null) return child7to12!;
    return child7to12 ?? adult;
  }
}

class CombinationLink {
  final String with_;
  final String reason;
  final String? severity;
  final String? solution;

  const CombinationLink({
    required this.with_,
    required this.reason,
    this.severity,
    this.solution,
  });

  factory CombinationLink.fromJson(Map<String, dynamic> json) => CombinationLink(
        with_: (json['with'] as String?) ?? '',
        reason: (json['reason'] as String?) ?? (json['solution'] as String?) ?? '',
        severity: json['severity'] as String?,
        solution: json['solution'] as String?,
      );
}

class DrugInteractionEntry {
  final String drugCategory;
  final String interaction;

  const DrugInteractionEntry({
    required this.drugCategory,
    required this.interaction,
  });

  factory DrugInteractionEntry.fromJson(Map<String, dynamic> json) =>
      DrugInteractionEntry(
        drugCategory: (json['drug_category'] as String?) ?? '',
        interaction: (json['interaction'] as String?) ?? '',
      );
}

class FoodAlternative {
  final String name;
  const FoodAlternative(this.name);
}

class SpecialWarnings {
  final List<String> contraindications;
  final List<String> sideEffects;

  const SpecialWarnings({
    required this.contraindications,
    required this.sideEffects,
  });

  bool get isEmpty => contraindications.isEmpty && sideEffects.isEmpty;

  factory SpecialWarnings.fromJson(Map<String, dynamic> json) =>
      SpecialWarnings(
        contraindications: ((json['contraindications'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(growable: false),
        sideEffects: ((json['side_effects'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(growable: false),
      );
}

class SupplementGuide {
  final String id;
  final String koreanName;
  final String englishName;
  final SupplementCategory category;
  final List<String> mainBenefits;
  final Map<String, String> personalizedReasons;
  final TimingInfo timing;
  final DosageInfo dosage;
  final List<CombinationLink> goodCombinations;
  final List<CombinationLink> badCombinations;
  final List<DrugInteractionEntry> drugInteractions;
  final List<FoodAlternative> foodAlternatives;
  final String effectTimeline;
  final SpecialWarnings? warnings;

  const SupplementGuide({
    required this.id,
    required this.koreanName,
    required this.englishName,
    required this.category,
    required this.mainBenefits,
    required this.personalizedReasons,
    required this.timing,
    required this.dosage,
    required this.goodCombinations,
    required this.badCombinations,
    required this.drugInteractions,
    required this.foodAlternatives,
    required this.effectTimeline,
    this.warnings,
  });

  factory SupplementGuide.fromJson(Map<String, dynamic> json) {
    final reasons = (json['personalized_reasons'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    return SupplementGuide(
      id: (json['id'] as String?) ?? '',
      koreanName: (json['korean_name'] as String?) ?? '',
      englishName: (json['english_name'] as String?) ?? '',
      category: _categoryFrom(json['category'] as String?),
      mainBenefits: ((json['main_benefits'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      personalizedReasons:
          reasons.map((key, value) => MapEntry(key, value.toString())),
      timing: TimingInfo.fromJson(
        (json['timing'] as Map<String, dynamic>?) ?? const {},
      ),
      dosage: DosageInfo.fromJson(
        (json['dosage'] as Map<String, dynamic>?) ?? const {},
      ),
      goodCombinations: ((json['good_combinations'] as List?) ?? const [])
          .map((e) => CombinationLink.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      badCombinations: ((json['bad_combinations'] as List?) ?? const [])
          .map((e) => CombinationLink.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      drugInteractions: ((json['drug_interactions'] as List?) ?? const [])
          .map((e) => DrugInteractionEntry.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      foodAlternatives: ((json['food_alternatives'] as List?) ?? const [])
          .map((e) => FoodAlternative(e.toString()))
          .toList(growable: false),
      effectTimeline: (json['effect_timeline'] as String?) ?? '',
      warnings: json['warnings'] is Map<String, dynamic>
          ? SpecialWarnings.fromJson(json['warnings'] as Map<String, dynamic>)
          : null,
    );
  }
}
