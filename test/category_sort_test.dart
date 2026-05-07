// Regression tests for category-detail sort modes — pinned the bug where
// "적정 함량" on a category page (간 건강 / 수면 보조 etc.) silently fell
// back to popularity rank, producing identical results to "판매량".

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
  required String key,
  double recommended = 0,
  required bool isCategoryKey,
}) =>
    compareForSortMode(
      a: a,
      b: b,
      mode: mode,
      key: key,
      recommended: recommended,
      isCategoryKey: isCategoryKey,
    );

List<Product> _sorted(
  List<Product> items, {
  required SortModeApi mode,
  required String key,
  double recommended = 0,
  required bool isCategoryKey,
}) {
  final out = [...items];
  out.sort((a, b) => _cmp(a, b,
      mode: mode,
      key: key,
      recommended: recommended,
      isCategoryKey: isCategoryKey));
  return out;
}

void main() {
  group('적정 함량 — nutrient-keyed page (vitamin_d_iu)', () {
    test('closest to recommended wins', () {
      // recommended = 1000 IU; daily delivery: a=1000, b=400, c=4000.
      final a = _p(id: 'a', category: 'vitamin_d',
          ingredients: {'vitamin_d_iu': 1000}, popularityRank: 99);
      final b = _p(id: 'b', category: 'vitamin_d',
          ingredients: {'vitamin_d_iu': 400}, popularityRank: 1);
      final c = _p(id: 'c', category: 'vitamin_d',
          ingredients: {'vitamin_d_iu': 4000}, popularityRank: 50);
      final out = _sorted([b, a, c],
          mode: SortModeApi.fit,
          key: 'vitamin_d_iu',
          recommended: 1000,
          isCategoryKey: false);
      expect(out.map((p) => p.id).toList(), ['a', 'b', 'c']);
    });
  });

  group('적정 함량 — category page with primary nutrient', () {
    test("liver → silymarin_mg desc, NOT popularity", () {
      // Even though `b` has the best popularity rank, `a` has more silymarin
      // and must come first under "적정 함량".
      final a = _p(id: 'a', category: 'liver',
          ingredients: {'silymarin_mg': 200}, popularityRank: 50);
      final b = _p(id: 'b', category: 'liver',
          ingredients: {'silymarin_mg': 80}, popularityRank: 1);
      final c = _p(id: 'c', category: 'liver',
          ingredients: {'silymarin_mg': 140}, popularityRank: 10);
      final out = _sorted([b, c, a],
          mode: SortModeApi.fit,
          key: 'liver',
          isCategoryKey: true);
      expect(out.map((p) => p.id).toList(), ['a', 'c', 'b']);
    });

    test("sleep → melatonin_mg desc", () {
      final a = _p(id: 'a', category: 'sleep',
          ingredients: {'melatonin_mg': 5}, popularityRank: 10);
      final b = _p(id: 'b', category: 'sleep',
          ingredients: {'melatonin_mg': 3}, popularityRank: 1);
      final out = _sorted([b, a],
          mode: SortModeApi.fit, key: 'sleep', isCategoryKey: true);
      expect(out.first.id, 'a');
    });

    test("prenatal → vitamin_b9_mcg (folate) desc", () {
      final a = _p(id: 'low_folate', category: 'prenatal',
          ingredients: {'vitamin_b9_mcg': 200}, popularityRank: 1);
      final b = _p(id: 'high_folate', category: 'prenatal',
          ingredients: {'vitamin_b9_mcg': 800}, popularityRank: 50);
      final out = _sorted([a, b],
          mode: SortModeApi.fit, key: 'prenatal', isCategoryKey: true);
      expect(out.first.id, 'high_folate');
    });
  });

  group('적정 함량 — category page WITHOUT primary nutrient', () {
    test('multivitamin → ingredient count desc', () {
      // 'multivitamin' isn't in the primary-nutrient map, so richer combo wins.
      final lean = _p(id: 'lean', category: 'multivitamin',
          ingredients: {'vitamin_d_iu': 400, 'vitamin_c_mg': 60},
          popularityRank: 1);
      final rich = _p(id: 'rich', category: 'multivitamin',
          ingredients: {
            'vitamin_a_mcg': 800,
            'vitamin_d_iu': 1000,
            'vitamin_e_mg': 30,
            'vitamin_b1_mg': 1.2,
            'vitamin_b2_mg': 1.4,
            'vitamin_b6_mg': 1.7,
            'vitamin_b9_mcg': 400,
            'vitamin_b12_mcg': 2.4,
            'vitamin_c_mg': 90,
            'iron_mg': 8,
          },
          popularityRank: 50);
      final out = _sorted([lean, rich],
          mode: SortModeApi.fit, key: 'multivitamin', isCategoryKey: true);
      expect(out.first.id, 'rich');
    });
  });

  group('판매량 — popularity rank ascending', () {
    test('lower rank wins; null rank goes last', () {
      final a = _p(id: 'r1', popularityRank: 1);
      final b = _p(id: 'r10', popularityRank: 10);
      final c = _p(id: 'unranked', popularityRank: null);
      final out = _sorted([c, b, a],
          mode: SortModeApi.popularity, key: 'liver', isCategoryKey: true);
      expect(out.map((p) => p.id).toList(), ['r1', 'r10', 'unranked']);
    });
  });

  group('가성비 — package size / daily dose desc (more days = better)', () {
    test('120정/일1 (120일) > 60정/일1 (60일) > 60정/일3 (20일)', () {
      final big = _p(id: '120_1', packageSize: 120, dailyDose: 1); // 120 days
      final mid = _p(id: '60_1', packageSize: 60, dailyDose: 1); // 60 days
      final dense = _p(id: '60_3', packageSize: 60, dailyDose: 3); // 20 days
      final out = _sorted([dense, mid, big],
          mode: SortModeApi.value, key: 'liver', isCategoryKey: true);
      expect(out.map((p) => p.id).toList(), ['120_1', '60_1', '60_3']);
    });
  });

  group('regression — 적정 함량 vs 판매량 produce different orders', () {
    test("liver page: 적정 함량 ≠ 판매량 when silymarin and rank disagree",
        () {
      final ranked = _p(id: 'rank_only', category: 'liver',
          ingredients: {'silymarin_mg': 100}, popularityRank: 1);
      final concentrated = _p(id: 'silymarin_high', category: 'liver',
          ingredients: {'silymarin_mg': 300}, popularityRank: 99);
      final byPop = _sorted([concentrated, ranked],
          mode: SortModeApi.popularity, key: 'liver', isCategoryKey: true);
      final byFit = _sorted([concentrated, ranked],
          mode: SortModeApi.fit, key: 'liver', isCategoryKey: true);
      expect(byPop.first.id, 'rank_only');
      expect(byFit.first.id, 'silymarin_high');
      expect(byPop, isNot(equals(byFit)));
    });
  });
}
