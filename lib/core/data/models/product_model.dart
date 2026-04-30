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

class Product {
  final String id;
  final String name;
  final String brand;
  final ProductBrandType brandType;
  final String category;
  final int pricePerUnitKrw;
  final String unit;
  final int dailyDose;
  final int packageSize;
  final int packagePriceKrw;
  final Map<String, double> ingredients;
  final Map<String, String> ingredientUnits;
  final List<String> goodFor;
  final List<String> alternatives;
  final String? notes;
  final int? popularityRank;
  final DateTime? lastUpdated;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.brandType,
    required this.category,
    required this.pricePerUnitKrw,
    required this.unit,
    required this.dailyDose,
    required this.packageSize,
    required this.packagePriceKrw,
    required this.ingredients,
    required this.ingredientUnits,
    required this.goodFor,
    required this.alternatives,
    this.notes,
    this.popularityRank,
    this.lastUpdated,
  });

  int get dailyCostKrw => pricePerUnitKrw * dailyDose;

  factory Product.fromJson(Map<String, dynamic> json) {
    final ing = (json['ingredients'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    final units = (json['ingredient_units'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    return Product(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      brand: (json['brand'] as String?) ?? '',
      brandType: _brandTypeFrom(json['brand_type'] as String?),
      category: (json['category'] as String?) ?? '',
      pricePerUnitKrw: (json['price_per_unit_krw'] as num?)?.toInt() ?? 0,
      unit: (json['unit'] as String?) ?? '',
      dailyDose: (json['daily_dose'] as num?)?.toInt() ?? 1,
      packageSize: (json['package_size'] as num?)?.toInt() ?? 0,
      packagePriceKrw: (json['package_price_krw'] as num?)?.toInt() ?? 0,
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
      lastUpdated: _parseDate(json['last_updated']),
    );
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}

class ProductCombo {
  final List<Product> products;
  final Map<String, double> totalCoverage;
  final List<String> missingNutrients;
  final int totalDailyCostKrw;
  final int productCount;
  final double averageCoverage;

  const ProductCombo({
    required this.products,
    required this.totalCoverage,
    required this.missingNutrients,
    required this.totalDailyCostKrw,
    required this.productCount,
    required this.averageCoverage,
  });
}
