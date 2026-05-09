import '../data/models/product_model.dart';
import '../data/product_repository.dart';
import '../../features/family/models/family_member.dart';
import 'product_targeting.dart';

/// 카테고리 포커스 — 단일 / 주력 영양제(성분 1-3개)는 100점, 5개 이하는
/// 70점, 8개+ 종합비타민은 30점. `_pickBy` 점수에 가중 합산되어 카테고리
/// 정합도가 높은 제품이 상위에 노출되도록 합니다.
int _categoryFocusScore(Product p, String mainNutrient) {
  if ((p.ingredients[mainNutrient] ?? 0) <= 0) return 0;
  final n = p.ingredients.values.where((v) => v > 0).length;
  if (n <= 3) return 100;
  if (n <= 5) return 70;
  return 30;
}

/// One nutrient row in the recommendation screen — surfaces the top 3
/// products that supply that nutrient, scored against the persona.
class NutrientRecommendation {
  final String nutrient;
  final String displayName;
  final double recommendedAmount;
  final String unit;
  final List<RankedProduct> picks;

  const NutrientRecommendation({
    required this.nutrient,
    required this.displayName,
    required this.recommendedAmount,
    required this.unit,
    required this.picks,
  });
}

class RankedProduct {
  /// 카테고리 내 판매량 순위 (1 / 2 / 3). 후보가 부족하면 1만, 또는 1·2만
  /// 반환되며 빈 자리는 채우지 않습니다.
  final int rank;
  final Product product;
  const RankedProduct({required this.rank, required this.product});
}

/// Build top-N nutrient recommendations for a persona, drawing from the
/// curated 250 products. 카테고리 hard filter 통과 후보 중 판매량 점수
/// 상위 3개를 1·2·3위로 반환합니다.
class NutrientRecommender {
  final ProductRepository repo;
  NutrientRecommender(this.repo);

  /// Persona-driven nutrient recommendations. [nutrients] is the list of
  /// nutrient ids (e.g. `vitamin_d_iu`) or category names (`liver`,
  /// `sleep`) the analysis flagged as worth recommending, in priority order.
  ///
  /// [deficitNutrients]는 호환성을 위해 시그니처에 남겨두지만 사용되지
  /// 않습니다 (V2 — 가성비/종합추천 폐기 후). 호출처에서 빈 리스트를
  /// 전달해도 동일하게 동작합니다.
  ///
  /// Returns one row per nutrient, capped to [picksPerNutrient] picks per
  /// row. 후보가 부족하면 1·2개만 반환 — 빈 자리는 채우지 않습니다.
  List<NutrientRecommendation> recommend({
    required FamilyMember member,
    required List<({String key, String displayName, double recommended, String unit})>
        nutrients,
    List<String> deficitNutrients = const [],
    int picksPerNutrient = 3,
  }) {
    final all = repo.all();
    final out = <NutrientRecommendation>[];

    for (final n in nutrients) {
      final isCategoryKey = !_looksLikeNutrientKey(n.key);

      // 카테고리 hard filter 통과 후보만 — "비타민D 추천에 락토핏(유산균
      // 위주 multi-성분)이 왜?"라는 사용자 혼란을 row 진입 단계에서 차단.
      final candidates = all
          .where((p) => _categoryHardMatch(p, n.key, isCategoryKey))
          .toList(growable: false);

      if (candidates.isEmpty) continue;

      final scored = candidates
          .map((p) => _ScoredCandidate(
                product: p,
                targetScore: targetMatchScore(product: p, member: member),
                popularityScore: _popularityScore(p),
                focusScore: isCategoryKey
                    ? 50
                    : _categoryFocusScore(p, n.key),
              ))
          .where((c) => c.targetScore >= 0)
          .toList(growable: true);

      // 판매량 점수식 = popularity + target + focus. 기존 1위 선정 로직을
      // 그대로 재사용해 상위 N개로 확장합니다.
      scored.sort((a, b) {
        final av = a.popularityScore + a.targetScore + a.focusScore;
        final bv = b.popularityScore + b.targetScore + b.focusScore;
        return bv.compareTo(av);
      });

      final top = scored.take(picksPerNutrient).toList();
      if (top.isEmpty) continue;

      final picks = <RankedProduct>[
        for (var i = 0; i < top.length; i++)
          RankedProduct(rank: i + 1, product: top[i].product),
      ];

      out.add(NutrientRecommendation(
        nutrient: n.key,
        displayName: n.displayName,
        recommendedAmount: n.recommended,
        unit: n.unit,
        picks: picks,
      ));
    }

    return out;
  }
}

class _ScoredCandidate {
  final Product product;
  final int targetScore;
  final int popularityScore;
  final int focusScore;
  _ScoredCandidate({
    required this.product,
    required this.targetScore,
    required this.popularityScore,
    required this.focusScore,
  });
}

/// Returns true when the key is an RDI nutrient (suffix `_mg`/`_iu`/`_mcg`/
/// `_g`/`_billion_cfu`). Category keys (`liver`, `sleep`, `prenatal`, ...)
/// have no suffix and route through the category branch instead.
bool _looksLikeNutrientKey(String key) {
  return key.endsWith('_mg') ||
      key.endsWith('_iu') ||
      key.endsWith('_mcg') ||
      key.endsWith('_g') ||
      key.endsWith('_billion_cfu');
}

/// 카테고리 hard filter — 사용자 직관에 어긋나는 제품을 row 진입 단계에서
/// 차단합니다. 이전 soft 필터는 비타민D row에 락토핏 키즈(유산균 위주
/// 멀티-성분)를 노출시켰습니다. 사용자가 "비타민D 추천에 유산균이 왜?"라며
/// 신뢰를 잃는 케이스 차단이 본 함수의 목적.
///
/// 규칙:
/// - 카테고리 키(`liver`/`sleep`/`prenatal` 등): `p.category == key` 정합
/// - 영양소 키(`vitamin_d_iu` 등):
///   1) 메인 영양소 함유 필수 (현재 필터)
///   2) **카테고리가 영양소 카테고리** (예: `vitamin_d`/`vitamin_c`)이면
///      OK — 단일 영양소 주력 제품
///   3) **성분 가짓수 ≤ 2** 면 OK — 사실상 단일 영양제(센트룸 멘 같은
///      함량 없는 단순 라벨도 포함)
///   4) 그 외(probiotics 위주에 비타민D 곁들인 락토핏, 종합비타민 14성분
///      센트룸 등) → 카테고리에서 제외.
bool _categoryHardMatch(Product p, String key, bool isCategoryKey) {
  if (isCategoryKey) return p.category == key;

  // 1. 메인 영양소 함유 필수.
  final amount = p.ingredients[key] ?? 0;
  if (amount <= 0) return false;

  // 2. 카테고리가 영양소 카테고리와 정합 (vitamin_d_iu → vitamin_d).
  final keyBase = _baseFromNutrientKey(key);
  if (keyBase != null) {
    if (p.category == keyBase) return true;
    if (p.category.startsWith(keyBase)) return true;
    // omega3_total_mg → 'omega3' / 'krill_oil'(오메가3 위주) 매칭 보강.
    if (keyBase == 'omega3' &&
        (p.category == 'omega3' || p.category == 'krill_oil')) {
      return true;
    }
  }

  // 3. 단일/주력 영양제 (성분 가짓수 ≤ 2). 락토핏(3 성분)·종합비타민(8+
  // 성분)은 모두 막힙니다.
  final ingredientCount = p.ingredients.values.where((v) => v > 0).length;
  if (ingredientCount <= 2) return true;

  return false;
}

/// 영양소 키에서 단위 suffix(_mg/_iu/_mcg/_g/_billion_cfu)를 떼어내고
/// 카테고리 매칭에 쓸 베이스 명을 돌려줍니다.
String? _baseFromNutrientKey(String key) {
  for (final suffix in const [
    '_billion_cfu',
    '_mcg',
    '_mg',
    '_iu',
    '_g',
  ]) {
    if (key.endsWith(suffix)) {
      return key.substring(0, key.length - suffix.length);
    }
  }
  return null;
}

int _popularityScore(Product p) {
  final r = p.popularityRank;
  if (r == null) return 0;
  // 1 → 100, 50 → 50, 100+ → 0
  if (r <= 0) return 100;
  return (100 - r).clamp(0, 100);
}
