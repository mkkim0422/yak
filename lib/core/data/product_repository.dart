import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/product_model.dart';

class ProductRepository {
  ProductRepository();

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
    return _products
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q))
        .toList(growable: false);
  }

  /// Same category, sorted by ascending price.
  List<Product> findAlternatives(String productId) {
    final base = getById(productId);
    if (base == null) return const [];
    final candidates = _products
        .where((p) => p.id != productId && p.category == base.category)
        .toList(growable: true);
    candidates.sort(
      (a, b) => a.pricePerUnitKrw.compareTo(b.pricePerUnitKrw),
    );
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
      final cmpCoverage = b.totalCoverage.compareTo(a.totalCoverage);
      if (cmpCoverage != 0) return cmpCoverage;
      final cmpCount = a.productCount.compareTo(b.productCount);
      if (cmpCount != 0) return cmpCount;
      return a.totalDailyCostKrw.compareTo(b.totalDailyCostKrw);
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
      if (c.totalCoverage > best) best = c.totalCoverage;
    }
    return best;
  }

  ProductCombo _buildCombo(List<Product> products, Map<String, double> gap) {
    final supplied = <String, double>{};
    var dailyCost = 0;
    for (final p in products) {
      dailyCost += p.dailyCostKrw;
      p.ingredients.forEach((nutrient, amount) {
        supplied.update(
          nutrient,
          (existing) => existing + amount * p.dailyDose,
          ifAbsent: () => amount * p.dailyDose,
        );
      });
    }

    var nutrientsCovered = 0;
    final missing = <String>[];
    gap.forEach((nutrient, needed) {
      final got = supplied[nutrient] ?? 0;
      if (got >= needed * 0.7) {
        nutrientsCovered++;
      } else {
        missing.add(nutrient);
      }
    });

    final coverage =
        gap.isEmpty ? 0.0 : nutrientsCovered / gap.length;

    return ProductCombo(
      products: List.unmodifiable(products),
      totalCoverage: coverage,
      missingNutrients: List.unmodifiable(missing),
      totalDailyCostKrw: dailyCost,
      productCount: products.length,
    );
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

final productRepositoryLoaderProvider = FutureProvider<ProductRepository>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  await repo.load();
  return repo;
});
