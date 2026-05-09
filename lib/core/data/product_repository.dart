import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/product_model.dart';

class ProductRepository {
  ProductRepository();

  /// Test-only seeded repository. Lets us exercise search/lookup logic
  /// without going through the asset bundle.
  @visibleForTesting
  ProductRepository.withProducts(List<Product> items) {
    _products.addAll(items);
    _loaded = true;
  }

  final List<Product> _products = [];
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/data/products.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final list = (json['products'] as List?) ?? const [];
    _products
      ..clear()
      ..addAll(list.map((e) => Product.fromJson(e as Map<String, dynamic>)));
    _loaded = true;
  }

  List<Product> all() => List.unmodifiable(_products);

  Product? getById(String id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<Product> getByCategory(String category) =>
      _products.where((p) => p.category == category).toList(growable: false);

  List<Product> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all();
    // 사용자는 약통 라벨을 보면서 "센트룸 맨" / "Centrum Men" / "센트룸맨" /
    // "센트룸 50+" 같이 다양한 형태로 입력함. 공백을 토큰 구분자로만 쓰고
    // 각 토큰을 (한글명 / 영문명 / 카테고리) 어느 한 필드에라도 포함되면
    // 해당 토큰 매칭 성공으로 처리. 모든 토큰이 매칭(AND)되어야 결과에 포함.
    final tokens = q
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList(growable: false);
    if (tokens.isEmpty) return all();
    return _products
        .where((p) => tokens.every((t) => _matchesToken(p, t)))
        .toList(growable: false);
  }

  static bool _matchesToken(Product p, String token) {
    final t = token.replaceAll(RegExp(r'\s+'), '');
    if (t.isEmpty) return true;
    bool fieldHas(String field) =>
        field.toLowerCase().replaceAll(RegExp(r'\s+'), '').contains(t);
    return fieldHas(p.name) ||
        fieldHas(p.englishName) ||
        fieldHas(p.category);
  }

  /// Same category, sorted by ascending price.
  List<Product> findAlternatives(String productId) {
    final base = getById(productId);
    if (base == null) return const [];
    final candidates = _products
        .where((p) => p.id != productId && p.category == base.category)
        .toList(growable: true);
    candidates.sort((a, b) =>
        (a.popularityRank ?? 999).compareTo(b.popularityRank ?? 999));
    return List.unmodifiable(candidates);
  }

  /// Find optimal product combos that cover the needed nutrients.
  /// Returns top 3 combos sorted by coverage desc, count asc, cost asc.
  List<ProductCombo> findOptimalCombos({
    required Map<String, double> neededNutrients,
    Map<String, double> currentIntake = const {},
    int maxProducts = 3,
  }) {
    if (neededNutrients.isEmpty || _products.isEmpty) return const [];

    final gap = <String, double>{};
    neededNutrients.forEach((nutrient, needed) {
      final already = currentIntake[nutrient] ?? 0;
      final remaining = needed - already;
      if (remaining > 0) gap[nutrient] = remaining;
    });
    if (gap.isEmpty) return const [];

    final candidates = _products
        .where((p) => p.ingredients.keys.any(gap.containsKey))
        .toList(growable: false);
    if (candidates.isEmpty) return const [];

    final combos = <ProductCombo>[];

    for (final p in candidates) {
      combos.add(_buildCombo([p], gap));
    }

    if (_findBestCoverage(combos) < 0.7 && maxProducts >= 2) {
      for (var i = 0; i < candidates.length; i++) {
        for (var j = i + 1; j < candidates.length; j++) {
          combos.add(_buildCombo([candidates[i], candidates[j]], gap));
        }
      }
    }

    if (_findBestCoverage(combos) < 0.7 && maxProducts >= 3) {
      for (var i = 0; i < candidates.length; i++) {
        for (var j = i + 1; j < candidates.length; j++) {
          for (var k = j + 1; k < candidates.length; k++) {
            combos.add(_buildCombo(
              [candidates[i], candidates[j], candidates[k]],
              gap,
            ));
          }
        }
      }
    }

    combos.sort((a, b) {
      final cmpCoverage = b.averageCoverage.compareTo(a.averageCoverage);
      if (cmpCoverage != 0) return cmpCoverage;
      return a.productCount.compareTo(b.productCount);
    });

    final seen = <String>{};
    final unique = <ProductCombo>[];
    for (final combo in combos) {
      final key = (combo.products.map((p) => p.id).toList()..sort()).join(',');
      if (seen.add(key)) unique.add(combo);
      if (unique.length >= 3) break;
    }
    return unique;
  }

  double _findBestCoverage(List<ProductCombo> combos) {
    var best = 0.0;
    for (final c in combos) {
      if (c.averageCoverage > best) best = c.averageCoverage;
    }
    return best;
  }

  ProductCombo _buildCombo(List<Product> products, Map<String, double> gap) {
    final supplied = <String, double>{};
    for (final p in products) {
      p.ingredients.forEach((nutrient, amount) {
        supplied.update(
          nutrient,
          (existing) => existing + amount * p.dailyDose,
          ifAbsent: () => amount * p.dailyDose,
        );
      });
    }

    final perNutrient = <String, double>{};
    final missing = <String>[];
    var sum = 0.0;
    gap.forEach((nutrient, needed) {
      final got = supplied[nutrient] ?? 0;
      final ratio = needed > 0 ? (got / needed).clamp(0.0, 1.5) : 0.0;
      perNutrient[nutrient] = ratio;
      sum += ratio.clamp(0.0, 1.0);
      if (got < needed * 0.7) missing.add(nutrient);
    });

    final average = gap.isEmpty ? 0.0 : sum / gap.length;

    return ProductCombo(
      products: List.unmodifiable(products),
      totalCoverage: Map.unmodifiable(perNutrient),
      missingNutrients: List.unmodifiable(missing),
      productCount: products.length,
      averageCoverage: average,
    );
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  throw UnimplementedError(
    'productRepositoryProvider must be overridden in main() with a loaded instance.',
  );
});
