import '../data/models/product_model.dart';
import '../data/product_repository.dart';
import '../../features/family/models/family_member.dart';
import 'product_targeting.dart';

/// Tier label constants — kept stable across the codebase. Card UIs and
/// sort toggles render these verbatim.
const String kTierBestseller = '판매량';
const String kTierValue = '가성비';
const String kTierComprehensive = '종합추천';

/// Minimum fraction of the user's deficit list a product must cover before
/// it can claim the 종합추천 tier. Spec: "점수 70% 미만 = 표시 X".
const double kComprehensiveMinScore = 0.7;

/// Multivitamin / prenatal categories get a small bonus when ranking the
/// 종합추천 pick, since they're designed to broadly cover deficits.
const double kComprehensiveMultiBonus = 0.15;

/// 가성비 (value) tier requires the candidate's main-nutrient amount to be
/// within ±30% of the bestseller's. "Same effect at a different price point".
/// Loosened from ±20% in V1 release polish — 어린이 카테고리처럼 후보 풀이
/// 적은 곳에서 가성비 카드 미표시 빈도 줄이기 위함.
const double kValueAmountTolerance = 0.30;

/// 가성비 (value) tier requires the candidate to be less heavily promoted
/// than the bestseller. Anything ranked 6+ counts as "low ad budget".
const int kValueMinPopularityRank = 6;

/// 카테고리 포커스 — 단일 / 주력 영양제(성분 1-3개)는 100점, 5개 이하는
/// 70점, 8개+ 종합비타민은 30점. 판매량 / 가성비 카드에 가중 합산되며
/// 종합추천 카드에는 적용되지 않습니다 — 종합추천은 multi가 본질적으로
/// 더 적합하기 때문.
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
  /// Why we picked it: [kTierBestseller], [kTierValue], [kTierComprehensive].
  final String tier;
  final Product product;
  const RankedProduct({required this.tier, required this.product});
}

/// Build top-N nutrient recommendations for a persona, drawing from the
/// curated 250 products. Each row gets up to 3 picks with distinct tiers.
class NutrientRecommender {
  final ProductRepository repo;
  NutrientRecommender(this.repo);

  /// Persona-driven nutrient recommendations. [nutrients] is the list of
  /// nutrient ids (e.g. `vitamin_d_iu`) or category names (`liver`,
  /// `sleep`) the analysis flagged as worth recommending, in priority order.
  ///
  /// [deficitNutrients] is the user's full deficit set — used to score the
  /// 종합추천 pick. Pass an empty list when no analysis is available; the
  /// 종합추천 tier will then be skipped (showing only 판매량 / 가성비).
  ///
  /// Returns one row per nutrient, capped to [picksPerNutrient] picks per
  /// row. Tier order: 판매량 → 가성비 → 종합추천. Picks that don't qualify
  /// are silently dropped — the screen surfaces only what passes the
  /// thresholds.
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

      // 두 후보 풀:
      //   * tight (hard filter) — 사용자가 "비타민D 추천에 락토핏이 왜?"라고
      //     혼란스러워하지 않도록 단일/주력 제품 또는 영양소 카테고리 정합
      //     제품만. bestseller + value 티어에 사용.
      //   * broad — 메인 영양소를 함유하기만 하면 OK. multivitamin/prenatal
      //     같은 종합 제품이 종합추천 티어에 surface 될 수 있게 함.
      final tightCandidates = all
          .where((p) => _categoryHardMatch(p, n.key, isCategoryKey))
          .toList(growable: false);
      final broadCandidates = isCategoryKey
          ? tightCandidates // 카테고리 키는 둘 다 동일
          : all
              .where((p) => (p.ingredients[n.key] ?? 0) > 0)
              .toList(growable: false);

      if (broadCandidates.isEmpty) continue;

      _ScoredCandidate score(Product p) => _ScoredCandidate(
            product: p,
            targetScore: targetMatchScore(product: p, member: member),
            popularityScore: _popularityScore(p),
            focusScore: isCategoryKey
                ? 50
                : _categoryFocusScore(p, n.key),
          );

      final tightScored = tightCandidates
          .map(score)
          .where((c) => c.targetScore >= 0)
          .toList(growable: true);
      final broadScored = broadCandidates
          .map(score)
          .where((c) => c.targetScore >= 0)
          .toList(growable: true);

      final picks = <RankedProduct>[];
      final used = <String>{};

      // 1. 판매량 — tight pool에서. 카테고리에 단일/주력 제품 후보가 없으면
      // bestseller도 없는 것이 맞습니다 (사용자 혼란 방지).
      final bestseller = _pickBy(
        tightScored,
        used,
        (c) => c.popularityScore + c.targetScore + c.focusScore,
      );
      if (bestseller != null) {
        picks.add(RankedProduct(tier: kTierBestseller, product: bestseller));
        used.add(bestseller.id);
      }

      // 2. 가성비 — tight pool에서, 다른 브랜드 우선.
      if (bestseller != null && picks.length < picksPerNutrient) {
        final value = _pickValueAlternative(
          bestseller: bestseller,
          mainNutrient: n.key,
          isCategoryKey: isCategoryKey,
          scored: tightScored,
          used: used,
        );
        if (value != null) {
          picks.add(RankedProduct(tier: kTierValue, product: value));
          used.add(value.id);
        }
      }

      // 3. 종합추천 — broad pool에서. multivitamin이 비타민D row에서 종합
      // 추천 카드로 surface 되도록 hard filter를 거치지 않습니다.
      // 70% 임계 + multi 보너스로 자연스러운 노출.
      if (deficitNutrients.isNotEmpty && picks.length < picksPerNutrient) {
        final comp = _pickComprehensive(
          scored: broadScored,
          used: used,
          deficits: deficitNutrients,
        );
        if (comp != null) {
          picks.add(RankedProduct(tier: kTierComprehensive, product: comp));
          used.add(comp.id);
        }
      }

      if (picks.isEmpty) continue;
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

Product? _pickBy(
  List<_ScoredCandidate> scored,
  Set<String> used,
  int Function(_ScoredCandidate) projection,
) {
  _ScoredCandidate? best;
  var bestScore = -1 << 30;
  for (final c in scored) {
    if (used.contains(c.product.id)) continue;
    final v = projection(c);
    if (v > bestScore) {
      best = c;
      bestScore = v;
    }
  }
  return best?.product;
}

/// 가성비 candidate. Conditions (모두 만족해야 함):
///   1. 판매량 1위와 다른 제품 (`used` 필터로 보장)
///   2. main nutrient 함유량이 판매량 1위와 ±30% 이내 (V1.1 완화 — 어린이
///      카테고리 등 후보 풀이 적은 곳에서 매칭률 ↑)
///   3. popularity_rank ≥ 6 (광고/마케팅 영향 약함 추정)
///   4. 카테고리 포커스가 30점 이상 (종합비타민으로 빠지지 않게)
///   5. **다른 브랜드 우선** — 동일 브랜드의 라인업(예: GNC 비타민D 1000 vs
///      GNC 비타민D 5000)이 가성비로 잡혀 1위와 사실상 같은 출처를 보여주는
///      이슈 차단. 다른 브랜드 후보가 있으면 그 안에서, 없으면 동일 브랜드
///      후보로 폴백.
///
/// 매칭 후보가 없으면 `null` — UI는 가성비 카드를 표시하지 않습니다.
Product? _pickValueAlternative({
  required Product bestseller,
  required String mainNutrient,
  required bool isCategoryKey,
  required List<_ScoredCandidate> scored,
  required Set<String> used,
}) {
  final targetAmount =
      isCategoryKey ? 0.0 : (bestseller.ingredients[mainNutrient] ?? 0.0);

  final candidates = <({Product product, int popRank, int focusScore})>[];
  for (final c in scored) {
    final p = c.product;
    if (used.contains(p.id)) continue;

    final rank = p.popularityRank ?? 9999;
    if (rank < kValueMinPopularityRank) continue;
    if (c.focusScore < 30) continue;

    if (isCategoryKey) {
      candidates.add((product: p, popRank: rank, focusScore: c.focusScore));
    } else {
      if (targetAmount <= 0) continue;
      final amount = p.ingredients[mainNutrient] ?? 0;
      if (amount <= 0) continue;
      final diff = (amount - targetAmount).abs() / targetAmount;
      if (diff > kValueAmountTolerance) continue;
      candidates.add((product: p, popRank: rank, focusScore: c.focusScore));
    }
  }
  if (candidates.isEmpty) return null;

  // 다른 브랜드 우선 분리. 빈 풀이면 동일 브랜드 폴백.
  final differentBrand = candidates
      .where((c) => c.product.brand != bestseller.brand)
      .toList();
  final pool = differentBrand.isNotEmpty ? differentBrand : candidates;

  // 우선순위: 카테고리 포커스 desc → popularity rank desc(더 무명).
  pool.sort((a, b) {
    final f = b.focusScore.compareTo(a.focusScore);
    if (f != 0) return f;
    return b.popRank.compareTo(a.popRank);
  });
  return pool.first.product;
}

/// 종합추천 candidate: maximises the fraction of the user's deficits that
/// the candidate covers (treats any positive amount as "covers"). Multivit /
/// prenatal categories get a small score bonus. Returns null when the best
/// score falls below [kComprehensiveMinScore].
Product? _pickComprehensive({
  required List<_ScoredCandidate> scored,
  required Set<String> used,
  required List<String> deficits,
}) {
  if (deficits.isEmpty) return null;
  Product? best;
  var bestScore = -1.0;
  for (final c in scored) {
    if (used.contains(c.product.id)) continue;
    final raw = _comprehensiveScore(c.product, deficits);
    final bonus = _isMultiCategory(c.product.category)
        ? kComprehensiveMultiBonus
        : 0.0;
    final score = raw + bonus;
    if (score > bestScore) {
      bestScore = score;
      best = c.product;
    }
  }
  if (best == null) return null;
  if (bestScore < kComprehensiveMinScore) return null;
  return best;
}

/// Fraction of [deficits] keys that [p] supplies a positive amount of. Uses
/// the daily-dose multiplier so a 2-cap-per-day product gets credit only for
/// nutrients that meaningfully arrive at the body.
double _comprehensiveScore(Product p, List<String> deficits) {
  if (deficits.isEmpty) return 0;
  var matched = 0;
  for (final key in deficits) {
    if ((p.ingredients[key] ?? 0) > 0) matched++;
  }
  return matched / deficits.length;
}

bool _isMultiCategory(String category) {
  return category == 'multivitamin' ||
      category == 'prenatal' ||
      category == 'kids_multivitamin' ||
      category == 'mineral';
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
///      센트룸 등) → 카테고리에서 제외. 종합비타민은 별도의 종합추천
///      카드에서 surface 됩니다.
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
