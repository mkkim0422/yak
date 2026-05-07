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

/// Ingredient-similarity threshold (Jaccard over the bestseller's ingredient
/// keys) for a candidate to qualify as a 가성비 alternative. Same effect at
/// a different price point — by spec.
const double kValueSimilarityMin = 0.6;

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
              ))
          .where((c) => c.targetScore >= 0)
          .toList(growable: true);
      if (scored.isEmpty) continue;

      final picks = <RankedProduct>[];
      final used = <String>{};

      // 1. 판매량 — most popular product in the persona's eligible set.
      final bestseller = _pickBy(
        scored,
        used,
        (c) => c.popularityScore + c.targetScore,
      );
      if (bestseller != null) {
        picks.add(RankedProduct(tier: kTierBestseller, product: bestseller));
        used.add(bestseller.id);
      }

      // 2. 가성비 — same/similar ingredient profile as the bestseller, but
      // with weaker advertising signal (higher popularity rank = less
      // promoted = typically cheaper). Spec: "광고 X 저렴한 제품".
      if (bestseller != null && picks.length < picksPerNutrient) {
        final value = _pickValueAlternative(
          bestseller: bestseller,
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
  _ScoredCandidate({
    required this.product,
    required this.targetScore,
    required this.popularityScore,
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

/// 가성비 candidate: matches the bestseller's ingredient profile (Jaccard ≥
/// [kValueSimilarityMin]) but is less heavily promoted. Less-popular product
/// is preferred — same effect at a lower price point. Returns null when
/// nothing qualifies (no overlap, or only the bestseller exists).
Product? _pickValueAlternative({
  required Product bestseller,
  required List<_ScoredCandidate> scored,
  required Set<String> used,
}) {
  if (bestseller.ingredients.isEmpty) return null;

  // Build similarity-scored candidate list. Skip the bestseller itself + any
  // product already picked.
  final similar = <({Product product, double similarity, int popRank})>[];
  for (final c in scored) {
    if (used.contains(c.product.id)) continue;
    final s = _ingredientSimilarity(c.product, bestseller);
    if (s < kValueSimilarityMin) continue;
    similar.add((
      product: c.product,
      similarity: s,
      popRank: c.product.popularityRank ?? 9999,
    ));
  }
  if (similar.isEmpty) return null;

  // Order: similarity desc, then popularity rank desc (less popular = less
  // advertising premium). Stable on ties so insertion order survives.
  similar.sort((a, b) {
    final c = b.similarity.compareTo(a.similarity);
    if (c != 0) return c;
    return b.popRank.compareTo(a.popRank);
  });
  return similar.first.product;
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

/// Jaccard-like overlap of [a]'s ingredients vs [b]'s. For each of [b]'s
/// ingredient keys, [a] earns a hit when it carries the same key with an
/// amount within ±50% of [b]'s — close enough that the two products are
/// substitutable for the user's dosing purposes.
double _ingredientSimilarity(Product a, Product b) {
  if (b.ingredients.isEmpty) return 0;
  var match = 0;
  b.ingredients.forEach((key, bAmount) {
    final aAmount = a.ingredients[key] ?? 0;
    if (aAmount <= 0 || bAmount <= 0) return;
    final ratio = aAmount / bAmount;
    if (ratio >= 0.5 && ratio <= 2.0) match++;
  });
  return match / b.ingredients.length;
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
