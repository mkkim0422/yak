import '../data/models/product_model.dart';
import '../data/product_repository.dart';
import '../../features/family/models/family_member.dart';
import 'product_targeting.dart';

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
  /// Why we picked it: "적정 함량", "판매량", "가성비".
  final String tier;
  final Product product;
  const RankedProduct({required this.tier, required this.product});
}

/// Build top-N nutrient recommendations for a persona, drawing from the
/// curated 250 products. Each row gets up to 3 picks with distinct tiers.
class NutrientRecommender {
  final ProductRepository repo;
  NutrientRecommender(this.repo);

  /// Persona-driven nutrient recommendations. [nutrientKeys] is the list of
  /// nutrient ids (e.g. `vitamin_d_iu`) the analysis flagged as worth
  /// recommending, in priority order. Returns one row per nutrient, capped
  /// to the requested products (default 3 picks per row).
  List<NutrientRecommendation> recommend({
    required FamilyMember member,
    required List<({String key, String displayName, double recommended, String unit})>
        nutrients,
    int picksPerNutrient = 3,
  }) {
    final all = repo.all();
    final out = <NutrientRecommendation>[];

    for (final n in nutrients) {
      // Candidates that deliver this nutrient.
      final candidates = all
          .where((p) => (p.ingredients[n.key] ?? 0) > 0)
          .toList(growable: false);
      if (candidates.isEmpty) continue;

      // Score each candidate by:
      //   * persona target match (sex/age)
      //   * popularity (lower rank = better)
      //   * how close their per-day delivery is to the recommendation
      final scored = candidates
          .map((p) {
            final targetScore = targetMatchScore(product: p, member: member);
            return _ScoredCandidate(
              product: p,
              targetScore: targetScore,
              popularityScore: _popularityScore(p),
              fitScore: _fitScore(p, n.key, n.recommended),
            );
          })
          // Drop hard-excluded products (wrong sex / kids product for adult).
          .where((c) => c.targetScore >= 0)
          .toList(growable: true);

      scored.sort((a, b) => b.totalScore.compareTo(a.totalScore));

      // Tier picks — 적정 함량 (best fit), 판매량 (popularity), 가성비 (any other).
      final picks = <RankedProduct>[];
      final used = <String>{};

      Product? takeBy(int Function(_ScoredCandidate) projection) {
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
        if (best == null) return null;
        used.add(best.product.id);
        return best.product;
      }

      final byFit = takeBy((c) => c.fitScore + c.targetScore);
      if (byFit != null) {
        picks.add(RankedProduct(tier: '적정 함량', product: byFit));
      }
      if (picks.length < picksPerNutrient) {
        final byPop = takeBy((c) => c.popularityScore + c.targetScore);
        if (byPop != null) {
          picks.add(RankedProduct(tier: '판매량', product: byPop));
        }
      }
      if (picks.length < picksPerNutrient) {
        // Anything else still ranking high overall.
        final byAny = takeBy((c) => c.totalScore);
        if (byAny != null) {
          picks.add(RankedProduct(tier: '가성비', product: byAny));
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
  final int fitScore;
  _ScoredCandidate({
    required this.product,
    required this.targetScore,
    required this.popularityScore,
    required this.fitScore,
  });
  int get totalScore => targetScore + popularityScore + fitScore;
}

int _popularityScore(Product p) {
  final r = p.popularityRank;
  if (r == null) return 0;
  // 1 → 100, 50 → 50, 100+ → 0
  if (r <= 0) return 100;
  return (100 - r).clamp(0, 100);
}

/// How well a single daily dose of this product covers the recommendation.
/// Within 50–150% of the target → high; far below or far above → lower.
int _fitScore(Product p, String key, double target) {
  if (target <= 0) return 0;
  final delivered = (p.ingredients[key] ?? 0) * p.dailyDose;
  if (delivered <= 0) return 0;
  final ratio = delivered / target;
  if (ratio >= 0.7 && ratio <= 1.5) return 60;
  if (ratio >= 0.4 && ratio <= 2.0) return 30;
  if (ratio < 0.4) return 10;
  return 0; // too high
}
