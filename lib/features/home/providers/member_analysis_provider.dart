import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/kdris_2025.dart';
import '../../../core/data/models/product_model.dart';
import '../../../core/data/product_repository.dart';
import '../../family/models/family_member.dart';
import '../../family/providers/family_provider.dart';

class NutrientDeficit {
  final String nutrient;
  final String displayName;
  final double current;
  final double recommended;
  final int percentage; // 0..200, clamped
  final List<String> sourceProductNames;

  const NutrientDeficit({
    required this.nutrient,
    required this.displayName,
    required this.current,
    required this.recommended,
    required this.percentage,
    this.sourceProductNames = const [],
  });
}

class NutrientStatus {
  /// Original deficit/sufficient row.
  final NutrientDeficit deficit;

  /// Why this nutrient was prioritised — used to render bullets under
  /// the priority card (e.g. "검진 결과 부족", "흡연으로 손실 큼").
  final List<String> reasons;

  /// Higher == more urgent. Useful only inside a single analysis.
  final int priorityScore;

  const NutrientStatus({
    required this.deficit,
    this.reasons = const [],
    this.priorityScore = 0,
  });
}

/// Lifestyle-driven supplement category suggestion (밀크씨슬 / 멜라토닌 /
/// BCAA 등). Unlike [NutrientDeficit], these aren't tied to a recommended
/// daily allowance — they surface a *category* of products that the user
/// might benefit from based on smoking / drinking / sleep / stress.
class LifestyleSuggestion {
  /// Product category in the curated DB (`liver`, `sleep`, `sports`, ...).
  final String category;

  /// Header label shown in the recommendation list (e.g. "간 건강").
  final String displayName;

  /// Why we suggested this — used as the card's subtitle.
  final String reason;

  const LifestyleSuggestion({
    required this.category,
    required this.displayName,
    required this.reason,
  });
}

class MemberAnalysis {
  final List<NutrientDeficit> deficits;
  final List<NutrientDeficit> sufficient;
  final int currentProductCount;

  /// Top-3 deficits with reasons, ready to render in the priority card.
  final List<NutrientStatus> priority;

  /// Next 4-5 deficits, shown collapsed by default.
  final List<NutrientStatus> secondary;

  /// Persona-driven category suggestions. Surface alongside nutrient
  /// deficits on the recommendation screen. Empty when no lifestyle
  /// signals fire.
  final List<LifestyleSuggestion> lifestyleSuggestions;

  const MemberAnalysis({
    required this.deficits,
    required this.sufficient,
    required this.currentProductCount,
    this.priority = const [],
    this.secondary = const [],
    this.lifestyleSuggestions = const [],
  });

  factory MemberAnalysis.empty() => const MemberAnalysis(
        deficits: [],
        sufficient: [],
        currentProductCount: 0,
      );

  bool get hasDeficits => deficits.isNotEmpty;
  int get sufficientCount => sufficient.length;

  String get statusText {
    if (deficits.isEmpty) return '충분히 섭취중';
    return '${deficits.length}개 부족';
  }
}

/// Nutrient keys the analysis engine compares against KDRIs 2025. Order
/// matters only for deterministic iteration in tests — UI consumers re-sort
/// by deficit %.
const List<String> _kAnalysisKeys = [
  'vitamin_d_iu',
  'magnesium_mg',
  'omega3_total_mg',
  'calcium_mg',
  'iron_mg',
  'zinc_mg',
  'vitamin_b12_mcg',
  'vitamin_b9_mcg',
  'vitamin_c_mg',
  'probiotics_billion_cfu',
  'coenzyme_q10_mg',
  // 2025 신규 — 콜린(choline_mg) AI/UL 동시 설정. 분석 대상에 합류.
  'choline_mg',
];

/// Persona → recommended-amount map keyed by nutrient. KDRIs 2025 표를
/// 단일 진입점으로 사용하며, 표 결측 시 0(=비교 제외)으로 폴백합니다.
/// 임신/수유부 가산치는 KDRIs 표 내부에서 자동 처리됩니다.
Map<String, double> _recommendedFor(FamilyMember member) {
  final out = <String, double>{};
  for (final key in _kAnalysisKeys) {
    final v = recommendedKDRIs2025(
      nutrient: key,
      age: member.age,
      isMale: member.sex == Sex.male,
      isPregnant: member.isPregnant,
      isLactating: member.isBreastfeeding,
    );
    if (v != null) out[key] = v;
  }
  return out;
}

/// Korean display label for an analysis key — used by deficit cards.
/// Falls back to the bare key when the nutrient isn't in the KDRIs table
/// (shouldn't happen in normal flow since `_kAnalysisKeys` is a subset).
String _displayLabel(String nutrient) =>
    nameKDRIs2025(nutrient) ?? nutrient;

class _IntakeBreakdown {
  final Map<String, double> totals = <String, double>{};
  final Map<String, List<String>> sources = <String, List<String>>{};

  void add(String nutrient, double amount, String sourceName) {
    if (amount <= 0) return;
    totals.update(nutrient, (e) => e + amount, ifAbsent: () => amount);
    sources.putIfAbsent(nutrient, () => <String>[]).add(sourceName);
  }
}

_IntakeBreakdown _aggregate(FamilyMember member, ProductRepository repo) {
  final breakdown = _IntakeBreakdown();
  for (final id in member.currentProductIds) {
    final Product? product = repo.getById(id);
    if (product == null) continue;
    product.ingredients.forEach((nutrient, amount) {
      breakdown.add(nutrient, amount * product.dailyDose, product.name);
    });
  }
  for (final manual in member.manualProducts) {
    manual.ingredients.forEach((nutrient, amount) {
      breakdown.add(nutrient, amount * manual.dailyDose, manual.name);
    });
  }
  return breakdown;
}

MemberAnalysis analyzeMember(FamilyMember member, ProductRepository repo) {
  final intake = _aggregate(member, repo);
  final recommendations = _recommendedFor(member);

  final deficits = <NutrientDeficit>[];
  final sufficient = <NutrientDeficit>[];

  recommendations.forEach((nutrient, recommended) {
    final current = intake.totals[nutrient] ?? 0;
    final pctRaw = recommended <= 0 ? 0.0 : (current / recommended * 100);
    final pct = pctRaw.clamp(0, 200).toInt();
    final entry = NutrientDeficit(
      nutrient: nutrient,
      displayName: _displayLabel(nutrient),
      current: current,
      recommended: recommended,
      percentage: pct,
      sourceProductNames:
          List.unmodifiable(intake.sources[nutrient] ?? const <String>[]),
    );
    if (pct < 70) {
      deficits.add(entry);
    } else {
      sufficient.add(entry);
    }
  });

  deficits.sort((a, b) => a.percentage.compareTo(b.percentage));
  sufficient.sort((a, b) => b.percentage.compareTo(a.percentage));

  // Score deficits by urgency for priority/secondary split.
  final scored = deficits.map((d) {
    final reasons = <String>[];
    var score = 0;

    if (d.percentage < 30) {
      score += 100;
    } else if (d.percentage < 50) {
      score += 70;
    } else {
      score += 40;
    }

    // KDRIs 2025-aligned boosts only. 라이프스타일 변수(흡연/음주/수면/
    // 스트레스)는 한국 영양소 섭취기준에 별도 권장량이 없으므로 점수
    // 가중을 적용하지 않습니다. 임신·수유는 KDRIs 표 안에 가산치가
    // 정의되어 있고, 본 점수 부스트는 우선순위 노출에만 영향.
    if (member.dietQuality == DietQuality.poor) {
      // 식단 부족 → 종합비타민 일반 권고. 점수 가중은 가벼운 수준.
      if (d.nutrient == 'vitamin_b9_mcg' ||
          d.nutrient == 'iron_mg' ||
          d.nutrient == 'calcium_mg' ||
          d.nutrient == 'zinc_mg') {
        score += 25;
        reasons.add('식단이 불규칙하시면 종합비타민으로 보충하시면 좋아요');
      }
    }
    // 임신 — KDRIs 2025 표의 가산치는 권장량 자체에 이미 반영됨. 본
    // 점수 부스트는 우선순위 정렬용 (먼저 보여주기 위함).
    if (member.isPregnant) {
      if (d.nutrient == 'vitamin_b9_mcg' ||
          d.nutrient == 'iron_mg' ||
          d.nutrient == 'choline_mg' ||
          d.nutrient == 'omega3_total_mg') {
        score += 80;
        reasons.add('임신 중 — 꼭 보충해야 해요 (의사 상담 권장)');
      }
    }
    if (member.isBreastfeeding) {
      if (d.nutrient == 'calcium_mg' ||
          d.nutrient == 'vitamin_d_iu' ||
          d.nutrient == 'choline_mg' ||
          d.nutrient == 'omega3_total_mg') {
        score += 80;
        reasons.add('수유 중 — 모유 영양에 도움 (의사 상담 권장)');
      }
    }
    // KDRIs 2025: 65+ 비타민D AI 15μg(=600IU) / 칼슘 50+ 여성 800.
    if (member.age >= 65) {
      if (d.nutrient == 'calcium_mg' ||
          d.nutrient == 'vitamin_d_iu' ||
          d.nutrient == 'vitamin_b12_mcg') {
        score += 30;
        reasons.add('65세 이상 — 골 건강 / B12 흡수 저하');
      }
    } else if (member.age >= 50) {
      if (d.nutrient == 'calcium_mg' || d.nutrient == 'vitamin_d_iu') {
        score += 25;
        reasons.add('50세 이상 — 골 건강 우선');
      }
    }
    if (member.age < 13) {
      if (d.nutrient == 'vitamin_d_iu' || d.nutrient == 'iron_mg') {
        score += 25;
        reasons.add('성장기 — 우선 보충');
      }
    }
    if (d.current == 0) {
      reasons.add('지금 안 드시는 영양소');
    }

    return NutrientStatus(deficit: d, reasons: reasons, priorityScore: score);
  }).toList();

  scored.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
  final priority = scored.take(3).toList();
  final secondary = scored.skip(3).toList();

  return MemberAnalysis(
    deficits: deficits,
    sufficient: sufficient,
    currentProductCount:
        member.currentProductIds.length + member.manualProducts.length,
    priority: priority,
    secondary: secondary,
    lifestyleSuggestions: _lifestyleSuggestions(member),
  );
}

/// Build category-level supplement suggestions from the persona — restricted
/// to KDRIs-grounded cases only.
///
/// 라이프스타일 변수(흡연/음주/수면/스트레스)는 한국 KDRIs에 별도 권장량이
/// 없습니다. 따라서 "간 건강"(음주 → silymarin) / "수면 보조"(sleep →
/// melatonin) 같은 카테고리 추천은 제거합니다. 의학적 근거가 필요한 경우
/// 의사 상담을 권장하도록 면책에서 안내합니다.
///
/// 유지: 임신부 전용(prenatal) — KDRIs 가산치 + 비타민A 안전 함량 이슈,
/// 식단 부족(multivitamin) — KDRIs는 표준 식단을 가정하므로 결식이 잦을
/// 때만 종합비타민을 일반 권고합니다.
List<LifestyleSuggestion> _lifestyleSuggestions(FamilyMember m) {
  final out = <LifestyleSuggestion>[];

  if (m.isPregnant) {
    out.add(const LifestyleSuggestion(
      category: 'prenatal',
      displayName: '임산부 종합',
      reason: '엽산·철분 강화, 비타민A 안전 함량으로 설계된 제품을 권해요.',
    ));
  }

  if (m.dietQuality == DietQuality.poor) {
    out.add(const LifestyleSuggestion(
      category: 'multivitamin',
      displayName: '종합비타민',
      reason: '식단이 불규칙하시면 종합비타민으로 전반 보충이 안전해요.',
    ));
  }

  return out;
}

/// Per-member nutrient analysis with riverpod's auto-cache.
///
/// We `select` only the specific member out of the family list — without
/// this, *any* change to *any* member would invalidate every other
/// member's analysis (since [familyMembersProvider] holds a list that
/// becomes a new instance on every mutation). Selecting narrows the
/// dependency to the specific member, so editing member A leaves the
/// cached analyses for B/C/D untouched.
///
/// Trivial mutations (e.g. profile-photo path change) still produce a
/// new [FamilyMember] instance via copyWith and therefore re-run
/// [analyzeMember] — that's correct, but it's only one analysis instead
/// of N. A more aggressive optimization (skipping analysis when the
/// nutrient-relevant subset hasn't changed) is not worth the complexity
/// at family sizes ≤ 4.
final memberNutrientAnalysisProvider =
    Provider.family<MemberAnalysis, String>((ref, memberId) {
  final member = ref.watch(
    familyMembersProvider.select<FamilyMember?>((list) {
      for (final m in list) {
        if (m.id == memberId) return m;
      }
      return null;
    }),
  );
  if (member == null) return MemberAnalysis.empty();
  final repo = ref.watch(productRepositoryProvider);
  return analyzeMember(member, repo);
});
