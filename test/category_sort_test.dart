// Sort modes on the category-detail screen, after the 적정함량 → 종합추천
// rework. Three modes: 판매량 (popularity asc) / 가성비 (days of stock desc) /
// 종합추천 (deficit-coverage desc + multivitamin bonus).

import 'package:flutter_test/flutter_test.dart';

import 'package:alyak/core/data/models/product_model.dart';
import 'package:alyak/features/family/screens/category_detail_screen.dart';

Product _p({
  required String id,
  String category = 'liver',
  Map<String, double> ingredients = const {},
  int? popularityRank,
  int dailyDose = 1,
  int packageSize = 60,
}) =>
    Product(
      id: id,
      name: id,
      brand: 'b',
      brandType: ProductBrandType.brand,
      category: category,
      unit: '정',
      dailyDose: dailyDose,
      packageSize: packageSize,
      ingredients: ingredients,
      ingredientUnits: const {},
      goodFor: const [],
      alternatives: const [],
      popularityRank: popularityRank,
    );

int _cmp(
  Product a,
  Product b, {
  required SortModeApi mode,
  List<String> deficits = const [],
}) =>
    compareForSortMode(
      a: a,
      b: b,
      mode: mode,
      deficitNutrients: deficits,
    );

List<Product> _sorted(
  List<Product> items, {
  required SortModeApi mode,
  List<String> deficits = const [],
}) {
  final out = [...items];
  out.sort((a, b) => _cmp(a, b, mode: mode, deficits: deficits));
  return out;
}

void main() {
  group('판매량 — popularity rank ascending', () {
    test('rank 1 first; null rank goes last', () {
      final a = _p(id: 'r1', popularityRank: 1);
      final b = _p(id: 'r10', popularityRank: 10);
      final c = _p(id: 'unranked', popularityRank: null);
      final out = _sorted([c, b, a], mode: SortModeApi.popularity);
      expect(out.map((p) => p.id).toList(), ['r1', 'r10', 'unranked']);
    });
  });

  group('가성비 — days-of-stock descending', () {
    test('120정/일1 > 60정/일1 > 60정/일3', () {
      final big = _p(id: '120_1', packageSize: 120, dailyDose: 1);
      final mid = _p(id: '60_1', packageSize: 60, dailyDose: 1);
      final dense = _p(id: '60_3', packageSize: 60, dailyDose: 3);
      final out = _sorted([dense, mid, big], mode: SortModeApi.value);
      expect(out.map((p) => p.id).toList(), ['120_1', '60_1', '60_3']);
    });

    test('ties on stock days fall back to popularity', () {
      // Both bottles have the same days-of-stock (60). Tiebreak by rank.
      final pop = _p(id: 'popular', packageSize: 60, dailyDose: 1,
          popularityRank: 1);
      final unpop = _p(id: 'unranked', packageSize: 60, dailyDose: 1,
          popularityRank: 50);
      final out = _sorted([unpop, pop], mode: SortModeApi.value);
      expect(out.first.id, 'popular');
    });
  });

  group('종합추천 — deficit coverage descending', () {
    test('product covering more deficits ranks higher', () {
      final lean = _p(id: 'd_only', category: 'vitamin_d',
          ingredients: {'vitamin_d_iu': 1000});
      final broad = _p(id: 'multi', category: 'multivitamin',
          ingredients: {
            'vitamin_d_iu': 400,
            'magnesium_mg': 200,
            'vitamin_c_mg': 60,
          });
      final out = _sorted([lean, broad],
          mode: SortModeApi.comprehensive,
          deficits: ['vitamin_d_iu', 'magnesium_mg', 'vitamin_c_mg']);
      // multi covers 3/3 → wins (also gets +0.15 multivitamin bonus).
      expect(out.first.id, 'multi');
    });

    test('multivitamin bonus surfaces broad combos even on partial coverage',
        () {
      final single = _p(id: 'just_d', category: 'vitamin_d',
          ingredients: {'vitamin_d_iu': 1000});
      final multi = _p(id: 'multi', category: 'multivitamin',
          ingredients: {'vitamin_d_iu': 400, 'magnesium_mg': 200});
      // Both cover 1 of the deficit list → tie on raw score (1/3), but
      // multivitamin bonus pushes 'multi' above the single-nutrient product.
      final out = _sorted([single, multi],
          mode: SortModeApi.comprehensive,
          deficits: ['vitamin_d_iu', 'iron_mg', 'zinc_mg']);
      expect(out.first.id, 'multi');
    });

    test('empty deficit list → multivitamin bonus alone (still meaningful)',
        () {
      final regular = _p(id: 'regular', category: 'vitamin_d',
          ingredients: {'vitamin_d_iu': 1000});
      final multi = _p(id: 'multi', category: 'multivitamin',
          ingredients: {'vitamin_d_iu': 400});
      final out = _sorted([regular, multi],
          mode: SortModeApi.comprehensive, deficits: const []);
      expect(out.first.id, 'multi');
    });

    test('zero-coverage products fall back to popularity tiebreak', () {
      final ranked = _p(id: 'ranked', popularityRank: 1,
          ingredients: {'silymarin_mg': 100});
      final unranked = _p(id: 'unranked', popularityRank: 100,
          ingredients: {'silymarin_mg': 200});
      // Neither contains the deficit nutrients → tie at score 0 → popularity.
      final out = _sorted([unranked, ranked],
          mode: SortModeApi.comprehensive,
          deficits: ['vitamin_d_iu', 'iron_mg']);
      expect(out.first.id, 'ranked');
    });
  });

  group('regression — 판매량 ≠ 종합추천 when bestseller has narrow profile',
      () {
    test('narrow bestseller vs broad multivitamin', () {
      final bestseller = _p(id: 'narrow_pop', category: 'vitamin_d',
          popularityRank: 1, ingredients: {'vitamin_d_iu': 1000});
      final multi = _p(id: 'broad', category: 'multivitamin',
          popularityRank: 50,
          ingredients: {
            'vitamin_d_iu': 400,
            'magnesium_mg': 200,
            'vitamin_c_mg': 60,
            'iron_mg': 8,
          });
      final byPop = _sorted([bestseller, multi], mode: SortModeApi.popularity);
      final byComp = _sorted([bestseller, multi],
          mode: SortModeApi.comprehensive,
          deficits: ['vitamin_d_iu', 'magnesium_mg', 'vitamin_c_mg', 'iron_mg']);
      expect(byPop.first.id, 'narrow_pop');
      expect(byComp.first.id, 'broad');
      expect(byPop, isNot(equals(byComp)));
    });
  });
}
