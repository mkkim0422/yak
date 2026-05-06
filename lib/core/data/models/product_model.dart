enum ProductBrandType { brand, generic, storeBrand }

ProductBrandType _brandTypeFrom(String? raw) {
  switch (raw) {
    case 'generic':
      return ProductBrandType.generic;
    case 'store_brand':
      return ProductBrandType.storeBrand;
    default:
      return ProductBrandType.brand;
  }
}

/// When the product should be taken. Maps 1:1 to JSON `intake_timing`.
///
/// `multiple` is reserved for products with `intakes_per_day >= 2` whose
/// servings are spread across the day (e.g. 1+2 = 아침/저녁 분산).
enum IntakeTiming {
  morningEmpty,
  morningAfter,
  lunchAfter,
  dinnerAfter,
  beforeSleep,
  anyTimeAfterMeal,
  withMeal,
  multiple,
}

extension IntakeTimingX on IntakeTiming {
  /// Stable JSON value — kept identical to the camelCase enum name so future
  /// edits to the JSON read naturally.
  String toJsonValue() => name;

  /// Korean label with leading time-of-day emoji. `multiple` returns a
  /// generic label; per-product display is computed in the UI by combining
  /// `intakes_per_day` and `dose_per_intake`.
  String get koreanLabel {
    switch (this) {
      case IntakeTiming.morningEmpty:
        return '🌅 오전 식사 전 (공복)';
      case IntakeTiming.morningAfter:
        return '🌅 오전 식사 후';
      case IntakeTiming.lunchAfter:
        return '🌞 점심 식사 후';
      case IntakeTiming.dinnerAfter:
        return '🌙 저녁 식사 후';
      case IntakeTiming.beforeSleep:
        return '🌙 취침 전';
      case IntakeTiming.anyTimeAfterMeal:
        return '🍴 식후';
      case IntakeTiming.withMeal:
        return '🍴 식사 중';
      case IntakeTiming.multiple:
        return '⏰ 1일 여러 회 분산';
    }
  }
}

IntakeTiming _intakeTimingFrom(Object? raw) {
  if (raw is! String) return IntakeTiming.anyTimeAfterMeal;
  for (final t in IntakeTiming.values) {
    if (t.name == raw) return t;
  }
  return IntakeTiming.anyTimeAfterMeal;
}

class Product {
  final String id;
  final String name;
  final String brand;
  final ProductBrandType brandType;
  final String category;
  final String unit;
  final int dailyDose;
  final int packageSize;
  final Map<String, double> ingredients;
  final Map<String, String> ingredientUnits;
  final List<String> goodFor;
  final List<String> alternatives;
  final String? notes;
  final int? popularityRank;
  final DateTime? lastUpdated;
  final String? dataSource;

  /// When the product should be taken (식전/식후/취침 전 etc.).
  final IntakeTiming intakeTiming;

  /// 한 번에 몇 정/포 — quantity per single intake.
  final int dosePerIntake;

  /// 하루 몇 회 — how many separate intakes per day.
  /// Invariant: dosePerIntake * intakesPerDay == dailyDose.
  final int intakesPerDay;

  /// Free-text note for edge cases ("라벨 참조", 약사 권고 등).
  final String? intakeNote;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.brandType,
    required this.category,
    required this.unit,
    required this.dailyDose,
    required this.packageSize,
    required this.ingredients,
    required this.ingredientUnits,
    required this.goodFor,
    required this.alternatives,
    this.notes,
    this.popularityRank,
    this.lastUpdated,
    this.dataSource,
    this.intakeTiming = IntakeTiming.anyTimeAfterMeal,
    this.dosePerIntake = 1,
    this.intakesPerDay = 1,
    this.intakeNote,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final ing = (json['ingredients'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    final units = (json['ingredient_units'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    final dailyDose = (json['daily_dose'] as num?)?.toInt() ?? 1;
    final dosePerIntake =
        (json['dose_per_intake'] as num?)?.toInt() ?? dailyDose;
    final intakesPerDay = (json['intakes_per_day'] as num?)?.toInt() ?? 1;
    return Product(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      brand: (json['brand'] as String?) ?? '',
      brandType: _brandTypeFrom(json['brand_type'] as String?),
      category: (json['category'] as String?) ?? '',
      unit: (json['unit'] as String?) ?? (json['package_unit'] as String?) ?? '',
      dailyDose: dailyDose,
      packageSize: (json['package_size'] as num?)?.toInt() ?? 0,
      ingredients: ing.map(
        (key, value) => MapEntry(key, (value as num?)?.toDouble() ?? 0),
      ),
      ingredientUnits:
          units.map((key, value) => MapEntry(key, value.toString())),
      goodFor: ((json['good_for'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      alternatives: ((json['alternatives'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      notes: json['notes'] as String?,
      popularityRank: (json['popularity_rank'] as num?)?.toInt(),
      lastUpdated: _parseDate(json['last_updated'] ?? json['verified_date']),
      dataSource: json['data_source'] as String?,
      intakeTiming: _intakeTimingFrom(json['intake_timing']),
      dosePerIntake: dosePerIntake < 1 ? 1 : dosePerIntake,
      intakesPerDay: intakesPerDay < 1 ? 1 : intakesPerDay,
      intakeNote: json['intake_note'] as String?,
    );
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// Compose a Korean-language schedule line for the card UI.
  ///
  /// 1회/일 → "🌙 취침 전 1정"
  /// 2회/일 → "🌅 아침 1정 / 🌙 저녁 1정"
  /// 3회/일 → "🌅 아침 1정 / 🌞 점심 1정 / 🌙 저녁 1정"
  /// 4회 이상 → "1일 N회 (라벨 참조)"
  String get scheduleLabel {
    final n = intakesPerDay;
    final dose = dosePerIntake;
    final u = unit.isEmpty ? '정' : unit;
    if (n <= 1) {
      return '${intakeTiming.koreanLabel} $dose$u';
    }
    if (n == 2) {
      return '🌅 아침 $dose$u / 🌙 저녁 $dose$u';
    }
    if (n == 3) {
      return '🌅 아침 $dose$u / 🌞 점심 $dose$u / 🌙 저녁 $dose$u';
    }
    return '⏰ 1일 $n회 (라벨 참조)';
  }
}

class ProductCombo {
  final List<Product> products;
  final Map<String, double> totalCoverage;
  final List<String> missingNutrients;
  final int productCount;
  final double averageCoverage;

  const ProductCombo({
    required this.products,
    required this.totalCoverage,
    required this.missingNutrients,
    required this.productCount,
    required this.averageCoverage,
  });
}
