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
// AppStrings 의존을 피하기 위해 본 파일 내부에 뱃지 텍스트를 직접 보유.
// 단일 출처는 AppStrings — 두 정의가 같은 한국어 문구로 유지되도록 동기화.
const String _kBadgeAnyTimeAfterMeal = '식후 아무 때나';
const String _kBadgeMultiple = '묶어 드셔도 OK';
const String _kBadgeMorningEmpty = '공복 권장';
const String _kBadgeMorningAfter = '아침 식후';
const String _kBadgeLunchAfter = '점심 식후';
const String _kBadgeDinnerAfter = '저녁 식후';
const String _kBadgeBeforeSleep = '잠들기 전';
const String _kBadgeWithMeal = '식사 중';

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

  /// 사용자 친화 한 줄 뱃지. 시간대 그룹 카드 / 검색 결과 / 카테고리 카드에
  /// 권장 복용 시점을 톤다운된 형태로 노출.
  String get badgeText {
    switch (this) {
      case IntakeTiming.anyTimeAfterMeal:
        return _kBadgeAnyTimeAfterMeal;
      case IntakeTiming.multiple:
        return _kBadgeMultiple;
      case IntakeTiming.morningEmpty:
        return _kBadgeMorningEmpty;
      case IntakeTiming.morningAfter:
        return _kBadgeMorningAfter;
      case IntakeTiming.lunchAfter:
        return _kBadgeLunchAfter;
      case IntakeTiming.dinnerAfter:
        return _kBadgeDinnerAfter;
      case IntakeTiming.beforeSleep:
        return _kBadgeBeforeSleep;
      case IntakeTiming.withMeal:
        return _kBadgeWithMeal;
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

  /// Optional English-language product name (e.g. "Centrum For Men"). Surfaces
  /// for search only — users typing the bottle's English label should match.
  /// Empty string when the JSON entry has no `english_name`.
  final String englishName;
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

  /// Source URL for the product photo (og:image / twitter:image extracted
  /// from the product's `data_source` page). Mirrors the JSON `image_url`
  /// field. Used by the build pipeline; runtime UI loads from
  /// `assets/images/products/{id}.jpg` instead.
  final String? imageUrl;

  const Product({
    required this.id,
    required this.name,
    this.englishName = '',
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
    this.imageUrl,
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
      englishName: (json['english_name'] as String?) ?? '',
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
      imageUrl: json['image_url'] as String?,
    );
  }

  /// Local asset path the runtime should try first. Pair with `Image.asset`
  /// + `errorBuilder` so missing files fall back to a category emoji.
  String get imageAssetPath => 'assets/images/products/$id.jpg';

  static DateTime? _parseDate(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// 사용자 행동(아침에 한 번에) 정렬 — 분산 표시("아침 1정 / 점심 1정")
  /// 대신 "하루 N정" 단순 형태. 시점 정보는 [IntakeTimingX.badgeText] 뱃지로
  /// 별도 노출.
  String get scheduleLabel {
    final u = unit.isEmpty ? '정' : unit;
    return '하루 $dailyDose$u';
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
