import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/models/family_input.dart';
import '../../../core/data/models/product_model.dart';
import '../../../core/data/product_repository.dart';
import '../../family/models/family_member.dart';
import '../../family/providers/family_provider.dart';

/// Per-nutrient deficit detail used to render card content.
class NutrientDeficit {
  final String nutrient; // canonical key, e.g. 'vitamin_d_iu'
  final String displayName; // Korean label
  final double current;
  final double recommended;
  final int percentage; // 0..200, clamped

  const NutrientDeficit({
    required this.nutrient,
    required this.displayName,
    required this.current,
    required this.recommended,
    required this.percentage,
  });
}

class MemberAnalysis {
  final List<NutrientDeficit> deficits;
  final List<NutrientDeficit> sufficient;
  final int currentProductCount;
  final DateTime? lastCheckupDate;

  const MemberAnalysis({
    required this.deficits,
    required this.sufficient,
    required this.currentProductCount,
    required this.lastCheckupDate,
  });

  factory MemberAnalysis.empty() => const MemberAnalysis(
        deficits: [],
        sufficient: [],
        currentProductCount: 0,
        lastCheckupDate: null,
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

/// Recommended daily intake (RDI) targets used for deficit detection.
/// Conservative adult targets; scaled down for younger age groups.
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

Map<String, double> _aggregateIntake(
  List<String> currentProductIds,
  ProductRepository repo,
) {
  final totals = <String, double>{};
  for (final id in currentProductIds) {
    final Product? product = repo.getById(id);
    if (product == null) continue;
    product.ingredients.forEach((nutrient, amount) {
      totals.update(
        nutrient,
        (existing) => existing + amount * product.dailyDose,
        ifAbsent: () => amount * product.dailyDose,
      );
    });
  }
  return totals;
}

MemberAnalysis analyzeMember(FamilyMember member, ProductRepository repo) {
  final intake = _aggregateIntake(member.currentProductIds, repo);
  final recommendations = _recommendedFor(member);

  final deficits = <NutrientDeficit>[];
  final sufficient = <NutrientDeficit>[];

  recommendations.forEach((nutrient, recommended) {
    final current = intake[nutrient] ?? 0;
    final pctRaw = recommended <= 0 ? 0.0 : (current / recommended * 100);
    final pct = pctRaw.clamp(0, 200).toInt();
    final entry = NutrientDeficit(
      nutrient: nutrient,
      displayName: _baseRdi[nutrient]!.label,
      current: current,
      recommended: recommended,
      percentage: pct,
    );
    if (pct < 70) {
      deficits.add(entry);
    } else {
      sufficient.add(entry);
    }
  });

  deficits.sort((a, b) => a.percentage.compareTo(b.percentage));
  sufficient.sort((a, b) => b.percentage.compareTo(a.percentage));

  return MemberAnalysis(
    deficits: deficits,
    sufficient: sufficient,
    currentProductCount: member.currentProductIds.length,
    lastCheckupDate: member.lastCheckupDate,
  );
}

/// Sync provider — analysis is pure, so we don't need FutureProvider here.
/// (Analyzer handles repo loading at app boot via productRepositoryLoaderProvider.)
final memberNutrientAnalysisProvider =
    Provider.family<MemberAnalysis, String>((ref, memberId) {
  final member = ref.watch(familyProvider).getMember(memberId);
  if (member == null) return MemberAnalysis.empty();
  final repo = ref.watch(productRepositoryProvider);
  return analyzeMember(member, repo);
});
