import '../data/models/product_model.dart';
import '../data/nutrient_labels.dart';
import '../../features/family/models/family_member.dart';

/// Severity ramp for conflict cards.
///   info    — gray, "참고" (e.g. "2시간 분리 권장", 시간대 누적)
///   warning — amber, "주의" (e.g. 권장량 초과, 임신/수유 시 함량 확인)
///   danger  — red, 의학적 위험 (e.g. 임신 + 비타민A 과다)
enum ConflictSeverity { info, warning, danger }

/// One row in the conflict list.
class ConflictItem {
  final ConflictSeverity severity;
  final String emoji;
  final String title;
  final String message;

  /// Names of the products that contributed to this conflict (for the user
  /// to know which bottles to look at). Empty when the conflict is generic.
  final List<String> sourceProductNames;

  const ConflictItem({
    required this.severity,
    required this.emoji,
    required this.title,
    required this.message,
    this.sourceProductNames = const [],
  });
}

/// Daily intake context — one product's contribution to ingredient totals.
/// Both curated `Product` and `ManualProductEntry` collapse into this row.
class _IntakeRow {
  final String displayName;
  final IntakeTiming timing;
  final Map<String, double> dailyAmounts; // ingredient_key -> amount * dailyDose

  /// Whether this row is a multivitamin / multi-ingredient product. Used to
  /// soften overdose detection — a multivitamin alone should never trigger
  /// "비타민E 권장 초과" because its individual amounts are by design within
  /// safe single-product limits. Overdose only fires when the same nutrient
  /// stacks across products.
  final bool isMultivitamin;

  const _IntakeRow({
    required this.displayName,
    required this.timing,
    required this.dailyAmounts,
    this.isMultivitamin = false,
  });
}

bool _isMultivitaminCategory(String category) {
  // Categories that count as "broad spectrum" — ignored for solo overdose.
  const multi = {
    'multivitamin',
    'kids_multivitamin',
    'prenatal',
  };
  return multi.contains(category);
}

bool _looksMultivitamin(Product p) {
  if (_isMultivitaminCategory(p.category)) return true;
  // 8+ distinct ingredients ≈ multivitamin even when category misclassified.
  return p.ingredients.length >= 8;
}

bool _looksMultivitaminManual(ManualProductEntry m) {
  if (_isMultivitaminCategory(m.category)) return true;
  return m.ingredients.length >= 8;
}

_IntakeRow _rowFromProduct(Product p) => _IntakeRow(
      displayName: p.name,
      timing: p.intakeTiming,
      dailyAmounts: {
        for (final entry in p.ingredients.entries)
          entry.key: entry.value * p.dailyDose,
      },
      isMultivitamin: _looksMultivitamin(p),
    );

_IntakeRow _rowFromManual(ManualProductEntry m) => _IntakeRow(
      displayName: m.name,
      timing: m.intakeTiming,
      dailyAmounts: {
        for (final entry in m.ingredients.entries)
          entry.key: entry.value * m.dailyDose,
      },
      isMultivitamin: _looksMultivitaminManual(m),
    );

/// Korean food-standard upper-tolerable-intake levels (UL). Pulls from the
/// same nutrient-key vocabulary the rest of the app uses (`vitamin_d_iu`,
/// `calcium_mg`, etc.) so we can compare totals directly without unit math.
///
/// Nutrients without a UL (B1/B2/B5/B7/B12 — water-soluble) are deliberately
/// absent so they never trigger an overdose card. Magnesium UL applies to
/// supplements only (not dietary intake).
const Map<String, double> _kUpperLimits = {
  'vitamin_a_mcg': 3000,
  'vitamin_a_iu': 10000,
  'vitamin_d_iu': 4000,
  'vitamin_d3_iu': 4000,
  'vitamin_d_mcg': 100,
  'vitamin_e_mg': 540,
  'vitamin_c_mg': 2000,
  'vitamin_b6_mg': 100,
  'vitamin_b9_mcg': 1000,
  'folate_mcg': 1000,
  'folic_acid_mcg': 1000,
  'niacin_mg': 35,
  'calcium_mg': 2500,
  'iron_mg': 45,
  'magnesium_mg': 350,
  'zinc_mg': 35,
  'selenium_mcg': 400,
  'iodine_mcg': 2400,
  'copper_mcg': 10000,
  'copper_mg': 10,
  'caffeine_mg': 400,
};

/// Pregnancy / lactation thresholds. Anything not listed defers to UL or RDI.
class _PregLactRule {
  final String key;
  final double threshold;
  final ConflictSeverity severity;
  final String emoji;
  final String title;
  final String message;
  const _PregLactRule({
    required this.key,
    required this.threshold,
    required this.severity,
    required this.emoji,
    required this.title,
    required this.message,
  });
}

const List<_PregLactRule> _kPregnantRules = [
  _PregLactRule(
    key: 'vitamin_a_mcg',
    threshold: 3000,
    severity: ConflictSeverity.danger,
    emoji: '⚠️',
    title: '임신 중 비타민A 과다',
    message: '비타민A 합산 함량이 안전 기준을 넘어요. 의사 상담 필수.',
  ),
  _PregLactRule(
    key: 'vitamin_d_iu',
    threshold: 4000,
    severity: ConflictSeverity.warning,
    emoji: '⚠️',
    title: '임신 중 비타민D 함량 확인',
    message: '비타민D 합산 함량이 높아요. 의사·약사와 함량을 확인해 보세요.',
  ),
  _PregLactRule(
    key: 'caffeine_mg',
    threshold: 200,
    severity: ConflictSeverity.warning,
    emoji: '⚠️',
    title: '임신 중 카페인 함량 확인',
    message: '카페인 합산 200mg 이상이에요. 임신 중에는 줄여 드세요.',
  ),
];

const List<_PregLactRule> _kLactatingRules = [
  _PregLactRule(
    key: 'vitamin_b6_mg',
    threshold: 100,
    severity: ConflictSeverity.warning,
    emoji: '⚠️',
    title: '수유 중 비타민B6 함량 확인',
    message: '비타민B6 합산 함량이 높아요. 함량을 다시 확인해 보세요.',
  ),
];

class ConflictChecker {
  /// Public entry-point. Build the list of cards to render for [member]'s
  /// current supplement set.
  ///
  /// Pass [candidateProduct] / [candidateManual] when previewing what would
  /// happen if the user adds a new product — they're folded into the totals
  /// alongside the member's existing supplements. If both are null, it just
  /// audits the current set.
  static List<ConflictItem> check({
    required FamilyMember member,
    required List<Product> products,
    required List<ManualProductEntry> manuals,
    Product? candidateProduct,
    ManualProductEntry? candidateManual,
  }) {
    final rows = <_IntakeRow>[
      ...products.map(_rowFromProduct),
      ...manuals.map(_rowFromManual),
      if (candidateProduct != null) _rowFromProduct(candidateProduct),
      if (candidateManual != null) _rowFromManual(candidateManual),
    ];

    final out = <ConflictItem>[];
    // Order matters — most-severe rules surface first so the UI's "first
    // card" reads as the most urgent for the persona.
    out.addAll(_pregnancyConflicts(member, rows));
    out.addAll(_overdoseConflicts(rows));
    out.addAll(_absorptionConflicts(rows));
    out.addAll(_timingPileupConflicts(rows));
    // Drug interactions (Phase 2) — placeholder hook so we can extend later
    // without changing call sites. No surfaced rows for now.
    out.addAll(_drugInteractionConflicts(member, rows));
    return out;
  }

  /// Test-only: count the conflicts a single new product would add.
  static List<ConflictItem> diff({
    required FamilyMember member,
    required List<Product> products,
    required List<ManualProductEntry> manuals,
    required Product candidate,
  }) {
    final before = check(member: member, products: products, manuals: manuals);
    final after = check(
      member: member,
      products: products,
      manuals: manuals,
      candidateProduct: candidate,
    );
    return after.skip(before.length).toList();
  }
}

// ── Rule 1: nutrient overdose vs UL only ────────────────────────────────
//
// Threshold: UL (Korean MFDS upper-tolerable). RDI×2 was removed after the
// UX review — multivitamins routinely run at ~2× RDI by design and the old
// rule was firing "주의" cards on perfectly safe products.
//
// Soft rule: a multivitamin contributing alone is *not* counted toward the
// overdose total. The card only fires when a multivitamin stacks with a
// single-nutrient product on top, OR when single-nutrient products stack
// past UL on their own. In practice this means a user can take "센트룸
// 우먼" without seeing a single warning unless they add an extra single-
// nutrient bottle that pushes the combined total past UL.
List<ConflictItem> _overdoseConflicts(List<_IntakeRow> rows) {
  final totals = <String, double>{};
  final sources = <String, List<String>>{};
  // Track whether any single-nutrient product contributed to a key. If only
  // multivitamins contribute, we skip the warning even when totals cross UL.
  final hasNonMulti = <String, bool>{};

  for (final r in rows) {
    r.dailyAmounts.forEach((key, amount) {
      if (amount <= 0) return;
      totals.update(key, (e) => e + amount, ifAbsent: () => amount);
      sources.putIfAbsent(key, () => <String>[]).add(r.displayName);
      if (!r.isMultivitamin) {
        hasNonMulti[key] = true;
      }
    });
  }

  final out = <ConflictItem>[];
  totals.forEach((key, total) {
    final ul = _kUpperLimits[key];
    if (ul == null) return; // No UL → never warn (B12, K, B1/2/5/7 etc.)
    if (total <= ul) return;

    // Skip when only multivitamins contribute to this nutrient — by spec
    // those are within safe per-product limits, even if a user happens to
    // own multiple multis.
    final stackedFromSingle = hasNonMulti[key] ?? false;
    final productCount = sources[key]?.length ?? 0;
    if (!stackedFromSingle && productCount <= 1) return;

    final label = nutrientLabel(key);
    final amountStr = _formatAmount(total);
    final unit = _displayUnit(key);
    final src = sources[key] ?? const [];

    out.add(ConflictItem(
      severity: ConflictSeverity.warning,
      emoji: '⚠️',
      title: '$label 과다',
      message: '합산 $amountStr$unit (안전 상한 ${_formatAmount(ul)}$unit)',
      sourceProductNames: src,
    ));
  });
  return out;
}

// ── Rule 2: absorption interference (시간 분리 권장) ──────────────────────
List<ConflictItem> _absorptionConflicts(List<_IntakeRow> rows) {
  // Group rows by intake timing so we can detect "same-time" pairs.
  final byTiming = <IntakeTiming, List<_IntakeRow>>{};
  for (final r in rows) {
    byTiming.putIfAbsent(r.timing, () => <_IntakeRow>[]).add(r);
  }

  // Pair definitions: (key A, key B, title, message).
  const pairs = <(String, String, String, String)>[
    (
      'calcium_mg',
      'iron_mg',
      '칼슘 + 철분 동시 섭취',
      '같이 드시면 흡수가 떨어져요. 2시간 분리 권장.',
    ),
    (
      'calcium_mg',
      'magnesium_mg',
      '칼슘 + 마그네슘 동시 섭취',
      '같이 드시면 흡수가 일부 줄어요. 가능하면 분리 복용.',
    ),
    (
      'vitamin_c_mg',
      'vitamin_b12_mcg',
      '비타민C + B12 동시 섭취',
      '비타민C가 B12를 분해할 수 있어요. 2시간 분리 권장.',
    ),
  ];

  final out = <ConflictItem>[];
  byTiming.forEach((timing, group) {
    if (group.length < 2) return;
    for (final pair in pairs) {
      final aSrc = <String>[];
      final bSrc = <String>[];
      for (final r in group) {
        if ((r.dailyAmounts[pair.$1] ?? 0) > 0) aSrc.add(r.displayName);
        if ((r.dailyAmounts[pair.$2] ?? 0) > 0) bSrc.add(r.displayName);
      }
      if (aSrc.isEmpty || bSrc.isEmpty) continue;
      // Skip when all hits land on the same single product (no conflict).
      final uniqueProducts = {...aSrc, ...bSrc};
      if (uniqueProducts.length < 2) continue;
      out.add(ConflictItem(
        severity: ConflictSeverity.info,
        emoji: 'ℹ️',
        title: pair.$3,
        message: pair.$4,
        sourceProductNames: uniqueProducts.toList(),
      ));
    }
  });
  return out;
}

// ── Rule 3: timing pile-up (5+ products at same time) ───────────────────
List<ConflictItem> _timingPileupConflicts(List<_IntakeRow> rows) {
  if (rows.isEmpty) return const [];
  final byTiming = <IntakeTiming, List<String>>{};
  for (final r in rows) {
    byTiming.putIfAbsent(r.timing, () => <String>[]).add(r.displayName);
  }
  final out = <ConflictItem>[];
  byTiming.forEach((timing, names) {
    if (names.length < 5) return;
    out.add(ConflictItem(
      severity: ConflictSeverity.info,
      emoji: 'ℹ️',
      title: '한 번에 ${names.length}개 영양제',
      message: '여러 영양제를 한 번에 드시네요. 분산 복용도 좋아요.',
      sourceProductNames: names,
    ));
  });
  return out;
}

// ── Rule 4: drug interaction stub (Phase 2) ─────────────────────────────
List<ConflictItem> _drugInteractionConflicts(
  FamilyMember member,
  List<_IntakeRow> rows,
) {
  // Phase 1 ships with the structural hook only — once we add a medication
  // database, this becomes a real check. Keep the function signature stable.
  return const [];
}

// ── Rule 5: pregnancy / lactation ───────────────────────────────────────
List<ConflictItem> _pregnancyConflicts(
  FamilyMember member,
  List<_IntakeRow> rows,
) {
  if (!member.isPregnant && !member.isBreastfeeding) return const [];

  // Build totals & sources for the relevant keys only.
  double totalFor(String key) {
    var t = 0.0;
    for (final r in rows) {
      t += r.dailyAmounts[key] ?? 0;
    }
    return t;
  }

  List<String> sourcesFor(String key) {
    final s = <String>[];
    for (final r in rows) {
      if ((r.dailyAmounts[key] ?? 0) > 0) s.add(r.displayName);
    }
    return s;
  }

  final out = <ConflictItem>[];
  if (member.isPregnant) {
    for (final rule in _kPregnantRules) {
      final t = totalFor(rule.key);
      if (t < rule.threshold) continue;
      out.add(ConflictItem(
        severity: rule.severity,
        emoji: rule.emoji,
        title: rule.title,
        message: rule.message,
        sourceProductNames: sourcesFor(rule.key),
      ));
    }
  }
  if (member.isBreastfeeding) {
    for (final rule in _kLactatingRules) {
      final t = totalFor(rule.key);
      if (t < rule.threshold) continue;
      out.add(ConflictItem(
        severity: rule.severity,
        emoji: rule.emoji,
        title: rule.title,
        message: rule.message,
        sourceProductNames: sourcesFor(rule.key),
      ));
    }
  }
  return out;
}

// ── helpers ─────────────────────────────────────────────────────────────
String _formatAmount(double n) {
  if (n >= 100 || n == n.roundToDouble()) return n.toStringAsFixed(0);
  if (n >= 10) return n.toStringAsFixed(1);
  return n.toStringAsFixed(2);
}

String _displayUnit(String key) {
  final (_, unit) = splitNutrientKey(key);
  return unit;
}
