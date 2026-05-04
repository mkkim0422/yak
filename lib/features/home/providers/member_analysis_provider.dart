import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class MemberAnalysis {
  final List<NutrientDeficit> deficits;
  final List<NutrientDeficit> sufficient;
  final int currentProductCount;

  /// Top-3 deficits with reasons, ready to render in the priority card.
  final List<NutrientStatus> priority;

  /// Next 4-5 deficits, shown collapsed by default.
  final List<NutrientStatus> secondary;

  const MemberAnalysis({
    required this.deficits,
    required this.sufficient,
    required this.currentProductCount,
    this.priority = const [],
    this.secondary = const [],
  });

  factory MemberAnalysis.empty() => const MemberAnalysis(
        deficits: [],
        sufficient: [],
        currentProductCount: 0,
      );

  bool get hasDeficits => deficits.isNotEmpty;
  int get sufficientCount => sufficient.length;

  String get statusEmoji {
    if (deficits.isEmpty) return '✅';
    if (deficits.length <= 2) return '⚠️';
    return '🟠';
  }

  String get statusText {
    if (deficits.isEmpty) return '충분히 챙기시는 중';
    return '${deficits.length}개 부족';
  }
}

const Map<String, ({double amount, String label})> _baseRdi = {
  'vitamin_d_iu': (amount: 800, label: '비타민D'),
  'magnesium_mg': (amount: 320, label: '마그네슘'),
  'omega3_total_mg': (amount: 1000, label: '오메가3'),
  'calcium_mg': (amount: 800, label: '칼슘'),
  'iron_mg': (amount: 10, label: '철분'),
  'zinc_mg': (amount: 9, label: '아연'),
  'vitamin_b12_mcg': (amount: 2.4, label: '비타민B12'),
  'vitamin_b9_mcg': (amount: 400, label: '엽산'),
  'vitamin_c_mg': (amount: 90, label: '비타민C'),
  'probiotics_billion_cfu': (amount: 10, label: '유산균'),
  'coenzyme_q10_mg': (amount: 100, label: '코엔자임Q10'),
};

double _ageScale(AgeGroup g) {
  switch (g) {
    case AgeGroup.newborn:
      return 0.25;
    case AgeGroup.toddler:
      return 0.4;
    case AgeGroup.child:
      return 0.6;
    case AgeGroup.teen:
      return 0.85;
    case AgeGroup.adult:
      return 1.0;
    case AgeGroup.middleAged:
      return 1.0;
    case AgeGroup.elderly:
      return 0.95;
  }
}

Map<String, double> _recommendedFor(FamilyMember member) {
  final scale = _ageScale(member.ageGroup);
  return {
    for (final entry in _baseRdi.entries)
      entry.key: entry.value.amount * scale,
  };
}

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
      displayName: _baseRdi[nutrient]!.label,
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

    // Lifestyle boosts (no checkup data — we removed that feature).
    if (member.smokingStatus == SmokingStatus.current) {
      if (d.nutrient == 'vitamin_c_mg' || d.nutrient == 'vitamin_e_mg') {
        score += 30;
        reasons.add('흡연으로 항산화 영양소 손실');
      }
    }
    if (member.drinkingFrequency == DrinkingFrequency.daily) {
      if (d.nutrient == 'vitamin_b12_mcg' ||
          d.nutrient == 'vitamin_b9_mcg' ||
          d.nutrient == 'vitamin_b1_mg') {
        score += 25;
        reasons.add('잦은 음주로 B군 손실');
      }
    }
    if (member.dietQuality == DietQuality.poor) {
      if (d.nutrient == 'vitamin_b9_mcg' ||
          d.nutrient == 'iron_mg' ||
          d.nutrient == 'calcium_mg' ||
          d.nutrient == 'zinc_mg') {
        score += 30;
        reasons.add('식단 부족으로 보충 필요');
      }
    }
    if (member.stressLevel == StressLevel.high) {
      if (d.nutrient == 'magnesium_mg' ||
          d.nutrient == 'vitamin_b1_mg' ||
          d.nutrient == 'vitamin_b9_mcg') {
        score += 20;
        reasons.add('스트레스 시 영양소 소모 증가');
      }
    }
    if (member.sleepHours == SleepHours.less5 &&
        d.nutrient == 'magnesium_mg') {
      score += 20;
      reasons.add('수면 부족 — 근육 이완에 도움');
    }
    // Pregnancy / breastfeeding: very strong boost.
    if (member.isPregnant) {
      if (d.nutrient == 'vitamin_b9_mcg' ||
          d.nutrient == 'iron_mg' ||
          d.nutrient == 'omega3_total_mg') {
        score += 80;
        reasons.add('임신 중 — 꼭 보충해야 해요');
      }
    }
    if (member.isBreastfeeding) {
      if (d.nutrient == 'calcium_mg' ||
          d.nutrient == 'vitamin_d_iu' ||
          d.nutrient == 'omega3_total_mg') {
        score += 80;
        reasons.add('수유 중 — 모유 영양에 도움');
      }
    }
    // Age-based boosts.
    if (member.age >= 50) {
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
  );
}

final memberNutrientAnalysisProvider =
    Provider.family<MemberAnalysis, String>((ref, memberId) {
  final member = ref.watch(familyProvider).getMember(memberId);
  if (member == null) return MemberAnalysis.empty();
  final repo = ref.watch(productRepositoryProvider);
  return analyzeMember(member, repo);
});
