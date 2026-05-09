// V2 추천 엔진 — 가성비/종합추천 폐기 후 카테고리 hard filter 통과 후보
// 중 판매량 점수 상위 3개를 1·2·3위로 반환합니다. 본 테스트는:
//   * 1·2·3위 정렬이 판매량 점수식(popularity + target + focus)과 일치
//   * 후보 부족 시 부분 결과 (빈 자리 채움 X)
//   * RankedProduct.rank가 1·2·3 순서로 부여
//   * 호환 인자 deficitNutrients가 결과에 영향 없음
// 을 검증합니다.

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
  String category = 'vitamin_d',
  String brand = 'b',
  Map<String, double> ingredients = const {},
  int? popularityRank,
  int dailyDose = 1,
  int packageSize = 60,
}) =>
    Product(
      id: id,
      name: name.isEmpty ? id : name,
      brand: brand,
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
      createdAt: DateTime(2026, 5, 6),
      updatedAt: DateTime(2026, 5, 6),
    );

void main() {
  group('1·2·3위 정렬 — 판매량 점수 상위 3개', () {
    test('rank 1/30/80 → 1·2·3위 부여', () {
      final repo = _MemoRepo([
        _p('big', popularityRank: 1,
            ingredients: {'vitamin_d_iu': 1000}),
        _p('mid', popularityRank: 30,
            ingredients: {'vitamin_d_iu': 1000}),
        _p('small', popularityRank: 80,
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
      final picks = recs.first.picks;
      expect(picks.map((p) => p.product.id).toList(),
          ['big', 'mid', 'small']);
      expect(picks.map((p) => p.rank).toList(), [1, 2, 3]);
    });

    test('후보 4개+ → 상위 3개만 반환', () {
      final repo = _MemoRepo([
        _p('a', popularityRank: 1, ingredients: {'vitamin_d_iu': 1000}),
        _p('b', popularityRank: 5, ingredients: {'vitamin_d_iu': 1000}),
        _p('c', popularityRank: 10, ingredients: {'vitamin_d_iu': 1000}),
        _p('d', popularityRank: 50, ingredients: {'vitamin_d_iu': 1000}),
        _p('e', popularityRank: 100, ingredients: {'vitamin_d_iu': 1000}),
      ]);
      final recs = NutrientRecommender(repo).recommend(
        member: _adultFemale(),
        nutrients: const [
          (key: 'vitamin_d_iu', displayName: '비타민D',
              recommended: 1000.0, unit: 'IU'),
        ],
      );
      expect(recs.first.picks.length, 3);
      expect(
        recs.first.picks.map((p) => p.product.id).toList(),
        ['a', 'b', 'c'],
      );
    });
  });

  group('후보 부족 시 부분 결과 — 빈 자리 채움 X', () {
    test('후보 1개 → rank 1만 반환', () {
      final repo = _MemoRepo([
        _p('only', popularityRank: 5,
            ingredients: {'vitamin_d_iu': 1000}),
      ]);
      final recs = NutrientRecommender(repo).recommend(
        member: _adultFemale(),
        nutrients: const [
          (key: 'vitamin_d_iu', displayName: '비타민D',
              recommended: 1000.0, unit: 'IU'),
        ],
      );
      expect(recs.first.picks.length, 1);
      expect(recs.first.picks.first.rank, 1);
      expect(recs.first.picks.first.product.id, 'only');
    });

    test('후보 2개 → rank 1·2만 반환', () {
      final repo = _MemoRepo([
        _p('a', popularityRank: 5, ingredients: {'vitamin_d_iu': 1000}),
        _p('b', popularityRank: 50, ingredients: {'vitamin_d_iu': 1000}),
      ]);
      final recs = NutrientRecommender(repo).recommend(
        member: _adultFemale(),
        nutrients: const [
          (key: 'vitamin_d_iu', displayName: '비타민D',
              recommended: 1000.0, unit: 'IU'),
        ],
      );
      expect(recs.first.picks.map((p) => p.rank).toList(), [1, 2]);
    });

    test('후보 0개 → row 자체 미표시', () {
      final repo = _MemoRepo([
        _p('iron_only', category: 'iron',
            ingredients: {'iron_mg': 14}, popularityRank: 1),
      ]);
      final recs = NutrientRecommender(repo).recommend(
        member: _adultFemale(),
        nutrients: const [
          (key: 'vitamin_d_iu', displayName: '비타민D',
              recommended: 800.0, unit: 'IU'),
        ],
      );
      expect(recs, isEmpty);
    });
  });

  group('호환 인자 deficitNutrients — V2에서 무시', () {
    test('deficitNutrients 빈 리스트와 채워진 리스트 결과 동일', () {
      List<Product> products() => [
            _p('big', popularityRank: 1,
                ingredients: {'vitamin_d_iu': 1000}),
            _p('mid', popularityRank: 30,
                ingredients: {'vitamin_d_iu': 1000}),
          ];
      final without = NutrientRecommender(_MemoRepo(products())).recommend(
        member: _adultFemale(),
        nutrients: const [
          (key: 'vitamin_d_iu', displayName: '비타민D',
              recommended: 1000.0, unit: 'IU'),
        ],
      );
      final with_ = NutrientRecommender(_MemoRepo(products())).recommend(
        member: _adultFemale(),
        deficitNutrients: const [
          'vitamin_d_iu',
          'magnesium_mg',
          'iron_mg',
        ],
        nutrients: const [
          (key: 'vitamin_d_iu', displayName: '비타민D',
              recommended: 1000.0, unit: 'IU'),
        ],
      );
      expect(
        without.first.picks.map((p) => p.product.id).toList(),
        with_.first.picks.map((p) => p.product.id).toList(),
      );
    });
  });
}
