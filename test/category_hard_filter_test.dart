// 카테고리 hard filter 회귀 가드 — 사용자가 7세 아들 등록 후 비타민D
// 추천에 락토핏 키즈(probiotics 카테고리, vitamin_d_iu 함유)가 노출되는
// 이슈를 발견했습니다. 본 테스트는:
//   * 락토핏 시뮬레이션이 비타민D row에서 빠지는지
//   * 단일 비타민D 제품(락피도)은 통과하는지
//   * 가성비 카드가 다른 브랜드를 우선 선택하는지
//   * 후보 0개일 때 카테고리 자체가 surface되지 않는지
// 를 검증합니다.

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

/// 사용자 발견 페르소나 — 7세 아들. 어린이 제품(`category startsWith 'kids'`)이
/// 적합 후보로 분류되고 어른용 제품은 hard-exclude됩니다.
FamilyMember _kidSon7() => FamilyMember(
      id: 't_son',
      name: 'son7',
      relationship: Relationship.son,
      birthYear: DateTime.now().year - 7,
      sex: Sex.male,
      createdAt: DateTime(2026, 5, 6),
      updatedAt: DateTime(2026, 5, 6),
    );

void main() {
  group('카테고리 hard filter — 비타민D 카테고리에 multi-성분 제품 차단', () {
    test('락토핏 키즈(유산균 위주 3성분, vitamin_d_iu 함유) → 비타민D row 제외',
        () {
      // 사용자 발견 케이스 재현: 락토핏 키즈는 ingredients에 vitamin_d_iu
      // 400을 가지고 있지만 카테고리는 'probiotics', 성분 3개. 사용자가 7세
      // 아들을 등록한 후 비타민D 추천에 락토핏이 노출돼 "비타민D 추천에
      // 유산균이 왜?"라며 신뢰가 무너졌습니다. 페르소나 = 7세 아들.
      final repo = _MemoRepo([
        _p('lactofit_kids',
            name: '락토핏 생유산균 키즈',
            category: 'probiotics',
            brand: 'lactofit',
            ingredients: {
              'probiotics_billion_cfu': 1,
              'vitamin_d_iu': 400,
              'zinc_mg': 2.55,
            },
            popularityRank: 198),
        _p('lacfido_kids_d',
            name: '락피도 비타민D 츄어블 키즈',
            category: 'kids_vitamin_d',
            brand: 'lacfido',
            ingredients: {'vitamin_d_iu': 1000},
            popularityRank: 80),
      ]);
      final recs = NutrientRecommender(repo).recommend(
        member: _kidSon7(),
        nutrients: const [
          (key: 'vitamin_d_iu', displayName: '비타민D',
              recommended: 400.0, unit: 'IU'),
        ],
      );
      expect(recs.first.picks, isNotEmpty);
      final picked = recs.first.picks.map((r) => r.product.id).toList();
      expect(picked, contains('lacfido_kids_d'),
          reason: '단일 비타민D 키즈 제품은 통과');
      expect(picked, isNot(contains('lactofit_kids')),
          reason: '유산균 위주 multi-성분 제품은 비타민D row에서 차단');
    });

    test('단일 영양소 제품(성분 ≤ 2)은 통과', () {
      final repo = _MemoRepo([
        _p('solo_d_1000',
            category: 'general',
            brand: 'a',
            ingredients: {'vitamin_d_iu': 1000},
            popularityRank: 10),
      ]);
      final recs = NutrientRecommender(repo).recommend(
        member: _adultFemale(),
        nutrients: const [
          (key: 'vitamin_d_iu', displayName: '비타민D',
              recommended: 800.0, unit: 'IU'),
        ],
      );
      expect(recs.first.picks.first.product.id, 'solo_d_1000');
    });

    test('영양소 카테고리 (vitamin_d) 정합 제품은 성분 多여도 통과', () {
      // vitamin_d / vitamin_d_iu 같은 카테고리는 자기 정체성이 비타민D
      // 위주이므로 성분 가짓수 무관하게 통과.
      final repo = _MemoRepo([
        _p('big_d',
            category: 'vitamin_d',
            ingredients: {
              'vitamin_d_iu': 1000,
              'vitamin_k_mcg': 50,
              'magnesium_mg': 100,
              'calcium_mg': 50,
              'extra1_mg': 1,
              'extra2_mg': 1,
            },
            popularityRank: 5),
      ]);
      final recs = NutrientRecommender(repo).recommend(
        member: _adultFemale(),
        nutrients: const [
          (key: 'vitamin_d_iu', displayName: '비타민D',
              recommended: 800.0, unit: 'IU'),
        ],
      );
      expect(recs.first.picks.first.product.id, 'big_d');
    });

    test('카테고리 키(prenatal/sleep)는 p.category 직접 매칭', () {
      final repo = _MemoRepo([
        _p('elevit',
            category: 'prenatal',
            brand: 'elevit',
            ingredients: {
              'vitamin_b9_mcg': 800,
              'iron_mg': 60,
            },
            popularityRank: 1),
        // 'prenatal' 카테고리가 아닌 멀티 — 차단되어야 함
        _p('regular_multi',
            category: 'multivitamin',
            ingredients: {'vitamin_b9_mcg': 400, 'iron_mg': 8},
            popularityRank: 5),
      ]);
      final recs = NutrientRecommender(repo).recommend(
        member: _adultFemale(),
        nutrients: const [
          (key: 'prenatal', displayName: '임산부 종합',
              recommended: 0.0, unit: ''),
        ],
      );
      final picked = recs.first.picks.map((r) => r.product.id).toList();
      expect(picked, contains('elevit'));
      expect(picked, isNot(contains('regular_multi')));
    });
  });

  group('가성비 — 다른 브랜드 우선 + 후보 0개 시 카드 미표시', () {
    test('동일 브랜드 vs 다른 브랜드 → 다른 브랜드 우선', () {
      final repo = _MemoRepo([
        _p('gnc_d_1000',
            category: 'vitamin_d', brand: 'GNC',
            ingredients: {'vitamin_d_iu': 1000}, popularityRank: 1),
        // 같은 브랜드 (GNC) 라인업 — 가성비로는 X
        _p('gnc_d_2000',
            category: 'vitamin_d', brand: 'GNC',
            ingredients: {'vitamin_d_iu': 1100}, popularityRank: 30),
        // 다른 브랜드 — 가성비 우선
        _p('solgar_d_1000',
            category: 'vitamin_d', brand: 'Solgar',
            ingredients: {'vitamin_d_iu': 1000}, popularityRank: 50),
      ]);
      final recs = NutrientRecommender(repo).recommend(
        member: _adultFemale(),
        nutrients: const [
          (key: 'vitamin_d_iu', displayName: '비타민D',
              recommended: 800.0, unit: 'IU'),
        ],
      );
      final value = recs.first.picks
          .where((r) => r.tier == kTierValue)
          .toList();
      expect(value, isNotEmpty);
      expect(value.first.product.id, 'solgar_d_1000',
          reason: '다른 브랜드 우선');
    });

    test('동일 브랜드만 있을 때 폴백 (카드 자체는 표시)', () {
      // 다른 브랜드 후보가 없고, 동일 브랜드 후보가 popularity 기준을
      // 충족하면 그 후보를 가성비로 surface (카드 자체 미표시는 너무 엄격).
      final repo = _MemoRepo([
        _p('gnc_d_1000',
            category: 'vitamin_d', brand: 'GNC',
            ingredients: {'vitamin_d_iu': 1000}, popularityRank: 1),
        _p('gnc_d_other',
            category: 'vitamin_d', brand: 'GNC',
            ingredients: {'vitamin_d_iu': 1100}, popularityRank: 50),
      ]);
      final recs = NutrientRecommender(repo).recommend(
        member: _adultFemale(),
        nutrients: const [
          (key: 'vitamin_d_iu', displayName: '비타민D',
              recommended: 800.0, unit: 'IU'),
        ],
      );
      final value = recs.first.picks
          .where((r) => r.tier == kTierValue)
          .toList();
      expect(value, isNotEmpty);
      expect(value.first.product.id, 'gnc_d_other');
    });

    test('함량 매칭 X 시 가성비 카드 미표시', () {
      // 1위: vitamin_d_iu = 1000. 후보들은 모두 ±30% 밖 → 가성비 X.
      final repo = _MemoRepo([
        _p('lead', category: 'vitamin_d', brand: 'A',
            ingredients: {'vitamin_d_iu': 1000}, popularityRank: 1),
        _p('too_low', category: 'vitamin_d', brand: 'B',
            ingredients: {'vitamin_d_iu': 200}, popularityRank: 30),
        _p('too_high', category: 'vitamin_d', brand: 'C',
            ingredients: {'vitamin_d_iu': 5000}, popularityRank: 40),
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
      expect(value, isEmpty);
    });
  });

  group('카테고리 후보 0개 시 row 자체 미표시', () {
    test('vitamin_d_iu 함유 제품 0개 → row 자체 빠짐', () {
      final repo = _MemoRepo([
        _p('iron_only', category: 'iron', brand: 'A',
            ingredients: {'iron_mg': 14}, popularityRank: 1),
      ]);
      final recs = NutrientRecommender(repo).recommend(
        member: _adultFemale(),
        nutrients: const [
          (key: 'vitamin_d_iu', displayName: '비타민D',
              recommended: 800.0, unit: 'IU'),
        ],
      );
      expect(recs, isEmpty,
          reason: 'hard filter 통과 후보 0 → row 미표시');
    });
  });
}
