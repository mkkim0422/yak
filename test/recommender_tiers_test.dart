// Tier logic for the recommendation cards: 판매량 / 가성비 / 종합추천.
// 판매량 = highest popularity (persona-eligible).
// 가성비 = matches the bestseller's ingredient profile but is less promoted.
// 종합추천 = covers the user's deficit list above the 70% threshold.

import 'package:flutter_test/flutter_test.dart';

import 'package:alyak/core/data/models/product_model.dart';
import 'package:alyak/core/data/product_repository.dart';
import 'package:alyak/core/services/nutrient_recommender.dart';
import 'package:alyak/features/family/models/family_member.dart';

class _MemoRepo extends ProductRepository {
  final List<Product> _items;
  _MemoRepo(this._items);
  @override
  List<Product> all() => _items;
  @override
  Product? getById(String id) {
    for (final p in _items) {
      if (p.id == id) return p;
    }
    return null;
  }
}

Product _p(
  String id, {
  String name = '',
  String category = 'multivitamin',
  Map<String, double> ingredients = const {},
  int? popularityRank,
  int dailyDose = 1,
  int packageSize = 60,
}) =>
    Product(
      id: id,
      name: name.isEmpty ? id : name,
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

FamilyMember _adultFemale() => FamilyMember(
      id: 't',
      name: 'tester',
      relationship: Relationship.self,
      birthYear: 1990,
      sex: Sex.female,
      smokingStatus: SmokingStatus.never,
      drinkingFrequency: DrinkingFrequency.never,
      dietQuality: DietQuality.average,
      sleepHours: SleepHours.sevenToNine,
      stressLevel: StressLevel.low,
      allergies: const [],
      medications: const [],
      currentProductIds: const [],
      createdAt: DateTime(2026, 5, 6),
      updatedAt: DateTime(2026, 5, 6),
    );

void main() {
  group('판매량 tier — most-popular eligible product wins', () {
    test('rank 1 surfaces over higher-rank alternatives', () {
      final repo = _MemoRepo([
        _p('big_pop', popularityRank: 1,
            ingredients: {'vitamin_d_iu': 1000}),
        _p('mid_pop', popularityRank: 50,
            ingredients: {'vitamin_d_iu': 1000}),
      ]);
      final recs = NutrientRecommender(repo).recommend(
        member: _adultFemale(),
        nutrients: const [
          (key: 'vitamin_d_iu', displayName: '비타민D',
              recommended: 1000.0, unit: 'IU'),
        ],
      );
      expect(recs, isNotEmpty);
      final bestseller =
          recs.first.picks.firstWhere((r) => r.tier == kTierBestseller);
      expect(bestseller.product.id, 'big_pop');
    });
  });

  group('가성비 tier — similar ingredients, less promoted', () {
    test("matches bestseller's profile but with weaker popularity", () {
      // 'pop' is the bestseller. 'value' has the same ingredients but a
      // weaker popularity rank — exactly what 가성비 should surface.
      final repo = _MemoRepo([
        _p('pop',
            popularityRank: 1,
            ingredients: {'vitamin_d_iu': 1000}),
        _p('value',
            popularityRank: 80,
            ingredients: {'vitamin_d_iu': 1000}),
        _p('different',
            popularityRank: 30,
            ingredients: {'vitamin_d_iu': 200}), // ratio < 0.5 → no match
      ]);
      final recs = NutrientRecommender(repo).recommend(
        member: _adultFemale(),
        nutrients: const [
          (key: 'vitamin_d_iu', displayName: '비타민D',
              recommended: 1000.0, unit: 'IU'),
        ],
      );
      final value = recs.first.picks
          .where((r) => r.tier == kTierValue)
          .toList();
      expect(value, isNotEmpty);
      expect(value.first.product.id, 'value');
    });

    test('tier dropped silently when no similar alternative exists', () {
      final repo = _MemoRepo([
        _p('only_one', popularityRank: 1,
            ingredients: {'vitamin_d_iu': 1000}),
      ]);
      final recs = NutrientRecommender(repo).recommend(
        member: _adultFemale(),
        nutrients: const [
          (key: 'vitamin_d_iu', displayName: '비타민D',
              recommended: 1000.0, unit: 'IU'),
        ],
      );
      expect(recs.first.picks.any((r) => r.tier == kTierValue), isFalse);
    });
  });

  group('종합추천 tier — covers deficit list above 70%', () {
    test('multivitamin covering 3/3 deficits surfaces as 종합추천', () {
      final repo = _MemoRepo([
        _p('narrow_d', popularityRank: 1, category: 'vitamin_d',
            ingredients: {'vitamin_d_iu': 1000}),
        _p('similar_d', popularityRank: 80, category: 'vitamin_d',
            ingredients: {'vitamin_d_iu': 1000}),
        _p('multi', popularityRank: 5, category: 'multivitamin',
            ingredients: {
              'vitamin_d_iu': 400,
              'magnesium_mg': 200,
              'vitamin_c_mg': 60,
            }),
      ]);
      final recs = NutrientRecommender(repo).recommend(
        member: _adultFemale(),
        deficitNutrients: ['vitamin_d_iu', 'magnesium_mg', 'vitamin_c_mg'],
        nutrients: const [
          (key: 'vitamin_d_iu', displayName: '비타민D',
              recommended: 1000.0, unit: 'IU'),
        ],
      );
      // narrow_d → 판매량 ; similar_d → 가성비 ; multi → 종합추천 (covers 3/3)
      final tiers = recs.first.picks.map((r) => r.tier).toList();
      expect(tiers, contains(kTierComprehensive));
      final comp = recs.first.picks
          .firstWhere((r) => r.tier == kTierComprehensive);
      expect(comp.product.id, 'multi');
    });

    test('tier dropped when nothing reaches the 70% threshold', () {
      final repo = _MemoRepo([
        _p('pop', popularityRank: 1,
            ingredients: {'vitamin_d_iu': 1000}),
        _p('value', popularityRank: 50,
            ingredients: {'vitamin_d_iu': 1000}),
      ]);
      final recs = NutrientRecommender(repo).recommend(
        member: _adultFemale(),
        // 5 deficits — neither candidate covers > 1/5 = 20%.
        deficitNutrients: const [
          'vitamin_d_iu',
          'magnesium_mg',
          'vitamin_c_mg',
          'iron_mg',
          'zinc_mg',
        ],
        nutrients: const [
          (key: 'vitamin_d_iu', displayName: '비타민D',
              recommended: 1000.0, unit: 'IU'),
        ],
      );
      expect(
        recs.first.picks.any((r) => r.tier == kTierComprehensive),
        isFalse,
      );
    });

    test('empty deficit list → 종합추천 tier always skipped', () {
      final repo = _MemoRepo([
        _p('pop', popularityRank: 1,
            ingredients: {'vitamin_d_iu': 1000}),
        _p('multi', popularityRank: 5, category: 'multivitamin',
            ingredients: {
              'vitamin_d_iu': 400,
              'magnesium_mg': 200,
              'vitamin_c_mg': 60,
            }),
      ]);
      final recs = NutrientRecommender(repo).recommend(
        member: _adultFemale(),
        nutrients: const [
          (key: 'vitamin_d_iu', displayName: '비타민D',
              recommended: 1000.0, unit: 'IU'),
        ],
      );
      expect(
        recs.first.picks.any((r) => r.tier == kTierComprehensive),
        isFalse,
      );
    });
  });

  group('tier order — 판매량 always first when present', () {
    test('three-product set yields 판매량 + 가성비 + 종합추천 in that order',
        () {
      final repo = _MemoRepo([
        _p('pop', popularityRank: 1,
            ingredients: {'vitamin_d_iu': 1000}),
        _p('value', popularityRank: 80,
            ingredients: {'vitamin_d_iu': 1000}),
        _p('multi', popularityRank: 30, category: 'multivitamin',
            ingredients: {
              'vitamin_d_iu': 400,
              'magnesium_mg': 200,
              'vitamin_c_mg': 60,
            }),
      ]);
      final recs = NutrientRecommender(repo).recommend(
        member: _adultFemale(),
        deficitNutrients: ['vitamin_d_iu', 'magnesium_mg', 'vitamin_c_mg'],
        nutrients: const [
          (key: 'vitamin_d_iu', displayName: '비타민D',
              recommended: 1000.0, unit: 'IU'),
        ],
      );
      final tiers = recs.first.picks.map((r) => r.tier).toList();
      expect(tiers, [kTierBestseller, kTierValue, kTierComprehensive]);
    });
  });
}
