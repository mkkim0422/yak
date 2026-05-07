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
/// within ±20% of the bestseller's. "Same effect at a different price point".
const double kValueAmountTolerance = 0.20;

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
      final candidates = all
          .where((p) => isCategoryKey
              ? p.category == n.key
              : (p.ingredients[n.key] ?? 0) > 0)
          .toList(growable: false);
      if (candidates.isEmpty) continue;

      // Score each candidate by persona match + raw popularity. Hard-excluded
      // products (wrong sex / kids-only / etc.) drop out.
      final scored = candidates
          .map((p) => _ScoredCandidate(
                product: p,
                targetScore: targetMatchScore(product: p, member: member),
                popularityScore: _popularityScore(p),
                focusScore: isCategoryKey
                    ? 50 // 카테고리 키는 포커스 측정 의미 X (uniform)
                    : _categoryFocusScore(p, n.key),
              ))
          .where((c) => c.targetScore >= 0)
          .toList(growable: true);
      if (scored.isEmpty) continue;

      final picks = <RankedProduct>[];
      final used = <String>{};

      // 1. 판매량 — most popular product in the persona's eligible set,
      // 카테고리 포커스 가중 합산. 비타민D 카테고리에서 종합비타민이 1순위로
      // 올라가는 회귀 방지: 단일/주력 제품이 popularity가 비슷하면 우선.
      final bestseller = _pickBy(
        scored,
        used,
        (c) => c.popularityScore + c.targetScore + c.focusScore,
      );
      if (bestseller != null) {
        picks.add(RankedProduct(tier: kTierBestseller, product: bestseller));
        used.add(bestseller.id);
      }

      // 2. 가성비 — main-nutrient 함량이 판매량 1위와 ±20% 이내이고
      // popularity rank가 6+(=광고 약함)인 제품. 매칭 후보가 없으면 카드
      // 자체를 표시하지 않고 자연스럽게 떨어집니다.
      if (bestseller != null && picks.length < picksPerNutrient) {
        final value = _pickValueAlternative(
          bestseller: bestseller,
          mainNutrient: n.key,
          isCategoryKey: isCategoryKey,
          scored: scored,
          used: used,
        );
        if (value != null) {
          picks.add(RankedProduct(tier: kTierValue, product: value));
          used.add(value.id);
        }
      }

      // 3. 종합추천 — covers the user's full deficit list the most.
      // Multivitamin / prenatal categories get a small bonus since they're
      // designed for broad coverage. 70% threshold per spec.
      if (deficitNutrients.isNotEmpty && picks.length < picksPerNutrient) {
        final comp = _pickComprehensive(
          scored: scored,
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
///   2. main nutrient 함유량이 판매량 1위와 ±20% 이내
///      (카테고리 키는 함량 비교 대신 카테고리 동일 + 성분 가짓수 비슷)
///   3. popularity_rank ≥ 6 (광고/마케팅 영향 약함 추정)
///   4. 카테고리 포커스가 30점 이상 (종합비타민으로 빠지지 않게)
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

    // popularity rank 6+ 만 (1-5위는 광고 영향 큼).
    final rank = p.popularityRank ?? 9999;
    if (rank < kValueMinPopularityRank) continue;

    // 카테고리 포커스 ≥ 30 (종합비타민이 가성비에 들어가지 않게).
    if (c.focusScore < 30) continue;

    if (isCategoryKey) {
      // 카테고리 페이지(간 건강, 수면 등) — 동일 카테고리 + 성분 가짓수 비슷.
      // (카테고리 키 자체에는 함량 비교 대상이 없음)
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

  // 우선순위: 카테고리 포커스 desc → popularity rank desc(더 무명) → asc.
  candidates.sort((a, b) {
    final f = b.focusScore.compareTo(a.focusScore);
    if (f != 0) return f;
    return b.popRank.compareTo(a.popRank);
  });
  return candidates.first.product;
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

int _popularityScore(Product p) {
  final r = p.popularityRank;
  if (r == null) return 0;
  // 1 → 100, 50 → 50, 100+ → 0
  if (r <= 0) return 100;
  return (100 - r).clamp(0, 100);
}
