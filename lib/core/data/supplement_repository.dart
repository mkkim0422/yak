import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/region_config.dart';
import 'models/conflict_warning.dart';
import 'models/family_input.dart';
import 'models/recommendation_result.dart';
import 'models/schedule_result.dart';
import 'models/supplement_guide_model.dart';
import 'models/symptom_result.dart';
import 'product_repository.dart';

class SupplementRepository {
  SupplementRepository();

  final List<SupplementGuide> _supplements = [];
  final List<SymptomResult> _symptoms = [];
  Map<String, dynamic> _combinations = const {};
  List<Map<String, dynamic>> _ageProfiles = const [];
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final supplementRaw =
        await rootBundle.loadString('assets/data/supplement_guide.json');
    final symptomRaw =
        await rootBundle.loadString('assets/data/symptom_guide.json');
    final comboRaw =
        await rootBundle.loadString('assets/data/combination_optimizer.json');
    final ageRaw = await rootBundle.loadString(
      'assets/data/age_group_recommendations.json',
    );

    final supplementJson = jsonDecode(supplementRaw) as Map<String, dynamic>;
    _supplements
      ..clear()
      ..addAll(((supplementJson['supplements'] as List?) ?? const [])
          .map((e) => SupplementGuide.fromJson(e as Map<String, dynamic>)));

    final symptomJson = jsonDecode(symptomRaw) as Map<String, dynamic>;
    _symptoms
      ..clear()
      ..addAll(((symptomJson['symptoms'] as List?) ?? const [])
          .map((e) => SymptomResult.fromJson(e as Map<String, dynamic>)));

    _combinations = jsonDecode(comboRaw) as Map<String, dynamic>;

    final ageJson = jsonDecode(ageRaw) as Map<String, dynamic>;
    _ageProfiles = ((ageJson['profiles'] as List?) ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(growable: false);

    _loaded = true;
  }

  Future<void> loadCache() async {
    // Reserved for future cache file (recommendation_cache.json).
  }

  List<SupplementGuide> allSupplements() => List.unmodifiable(_supplements);

  SupplementGuide? getSupplementGuide(String name) {
    for (final s in _supplements) {
      if (s.koreanName == name || s.englishName == name) return s;
    }
    return null;
  }

  List<SymptomResult> allSymptoms() => List.unmodifiable(_symptoms);

  /// Top 12 type-A symptoms for the symptom selection UI.
  List<SymptomResult> getTopSymptoms() {
    return _symptoms
        .where((s) => s.type == SymptomType.typeA)
        .take(12)
        .toList(growable: false);
  }

  SymptomResult? getSymptomsInfo(String query) {
    final q = query.trim();
    if (q.isEmpty) return null;
    for (final s in _symptoms) {
      if (s.symptom == q || s.id == q) return s;
      if (s.keywords.contains(q)) return s;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Recommendations
  // ---------------------------------------------------------------------------

  RecommendationResult getRecommendations(
    FamilyInput input, {
    ProductRepository? productRepo,
  }) {
    final mustTake = <RecommendedSupplement>[];
    final highly = <RecommendedSupplement>[];
    final consider = <RecommendedSupplement>[];

    final profile = _findProfile(input);
    if (profile != null) {
      for (final entry in (profile['must_take'] as List? ?? const [])) {
        final m = entry as Map<String, dynamic>;
        mustTake.add(RecommendedSupplement(
          name: (m['name'] as String?) ?? '',
          category: RecommendationCategory.mustTake,
          priority: (m['priority'] as num?)?.toInt() ?? 1,
          reason: (m['reason'] as String?) ?? '',
        ));
      }
      for (final entry
          in (profile['highly_recommended'] as List? ?? const [])) {
        final m = entry as Map<String, dynamic>;
        highly.add(RecommendedSupplement(
          name: (m['name'] as String?) ?? '',
          category: RecommendationCategory.highlyRecommended,
          priority: (m['priority'] as num?)?.toInt() ?? 2,
          reason: (m['reason'] as String?) ?? '',
        ));
      }
      for (final entry in (profile['consider_if'] as List? ?? const [])) {
        final m = entry as Map<String, dynamic>;
        consider.add(RecommendedSupplement(
          name: (m['name'] as String?) ?? '',
          category: RecommendationCategory.considerIf,
          priority: (m['priority'] as num?)?.toInt() ?? 3,
          reason: (m['condition'] as String?) ?? '',
        ));
      }
    }

    _applyLifestyleBoosts(input, mustTake, highly, consider);
    _applySymptomBoosts(input, mustTake, highly, consider);
    _applyChildrenFocus(input, mustTake, highly, consider);
    _applyPregnancyBoosts(input, mustTake, highly, consider);
    _applyRegionAdjustments(mustTake, highly);
    _resolvePersonalizedReasons(input, mustTake);
    _resolvePersonalizedReasons(input, highly);
    _resolvePersonalizedReasons(input, consider);

    final filteredMust = _dedupAcross([], mustTake);
    final filteredHighly =
        _dedupAcross(filteredMust, highly);
    final filteredConsider =
        _dedupAcross([...filteredMust, ...filteredHighly], consider);

    final cap = _nutrientCap(input.ageGroup);
    final cappedMust = _capList(filteredMust, cap);
    final remainingCap = (cap - cappedMust.length).clamp(0, cap);
    final cappedHighly = _capList(filteredHighly, remainingCap);
    final remainingCap2 =
        (cap - cappedMust.length - cappedHighly.length).clamp(0, cap);
    final cappedConsider = _capList(filteredConsider, remainingCap2);

    final alreadyTaking = <RecommendedSupplement>[];
    final coveredNames = _coveredFromCurrent(input, productRepo);
    final finalMust = <RecommendedSupplement>[];
    final finalHighly = <RecommendedSupplement>[];
    final finalConsider = <RecommendedSupplement>[];

    for (final r in cappedMust) {
      if (coveredNames.contains(r.name) ||
          input.currentSupplements.contains(r.name)) {
        alreadyTaking
            .add(r.copyWith(category: RecommendationCategory.alreadyTaking));
      } else {
        finalMust.add(r);
      }
    }
    for (final r in cappedHighly) {
      if (coveredNames.contains(r.name) ||
          input.currentSupplements.contains(r.name)) {
        alreadyTaking
            .add(r.copyWith(category: RecommendationCategory.alreadyTaking));
      } else {
        finalHighly.add(r);
      }
    }
    for (final r in cappedConsider) {
      if (coveredNames.contains(r.name) ||
          input.currentSupplements.contains(r.name)) {
        alreadyTaking
            .add(r.copyWith(category: RecommendationCategory.alreadyTaking));
      } else {
        finalConsider.add(r);
      }
    }

    return RecommendationResult(
      mustTake: finalMust,
      highlyRecommended: finalHighly,
      considerIf: finalConsider,
      alreadyTaking: alreadyTaking,
      regionNote: RegionConfig.current().notes,
    );
  }

  Map<String, dynamic>? _findProfile(FamilyInput input) {
    final ageStr = _ageGroupKey(input.ageGroup);
    final genderStr = input.gender == Gender.male ? 'male' : 'female';

    if (input.ageGroup == AgeGroup.child && input.pickyEating == true) {
      final picky = _ageProfiles.firstWhere(
        (p) => p['gender'] == 'picky_eater' && p['age_group'] == 'child',
        orElse: () => const {},
      );
      if (picky.isNotEmpty) return picky;
    }

    if (input.isVegetarian && input.ageGroup == AgeGroup.adult) {
      final veg = _ageProfiles.firstWhere(
        (p) => p['gender'] == 'vegetarian' && p['age_group'] == 'adult',
        orElse: () => const {},
      );
      if (veg.isNotEmpty) return veg;
    }

    final match = _ageProfiles.firstWhere(
      (p) => p['age_group'] == ageStr && p['gender'] == genderStr,
      orElse: () => const {},
    );
    return match.isEmpty ? null : match;
  }

  String _ageGroupKey(AgeGroup g) {
    switch (g) {
      case AgeGroup.newborn:
        return 'newborn';
      case AgeGroup.toddler:
        return 'toddler';
      case AgeGroup.child:
        return 'child';
      case AgeGroup.teen:
        return 'teen';
      case AgeGroup.adult:
        return 'adult';
      case AgeGroup.elderly:
        return 'elderly';
    }
  }

  int _nutrientCap(AgeGroup g) {
    switch (g) {
      case AgeGroup.newborn:
        return 3;
      case AgeGroup.toddler:
        return 3;
      case AgeGroup.child:
        return 4;
      case AgeGroup.teen:
        return 5;
      case AgeGroup.adult:
        return 6;
      case AgeGroup.elderly:
        return 5;
    }
  }

  void _applyLifestyleBoosts(
    FamilyInput input,
    List<RecommendedSupplement> must,
    List<RecommendedSupplement> highly,
    List<RecommendedSupplement> consider,
  ) {
    if (input.smoker == true) {
      _ensure(highly, '비타민C', '흡연으로 손상된 항산화 시스템 회복에 좋아요',
          RecommendationCategory.highlyRecommended, 2);
      _ensure(highly, '비타민E', '항산화 보강에 좋아요',
          RecommendationCategory.highlyRecommended, 2);
      _ensure(consider, '베타카로틴', '폐 점막 보호에 도움이 돼요',
          RecommendationCategory.considerIf, 3);
      _ensure(consider, 'NAC', '호흡기 점액 정화에 도움이 돼요',
          RecommendationCategory.considerIf, 3);
    }
    if (input.isHeavyDrinker) {
      _ensure(highly, '밀크씨슬', '음주로 부담된 간 회복에 좋아요',
          RecommendationCategory.highlyRecommended, 2);
      _ensure(highly, '비타민B군 종합', '음주로 손실된 B군 보충에 좋아요',
          RecommendationCategory.highlyRecommended, 2);
    }
    // Poor diet → bring a multivitamin into the mix.
    if (input.diet == Diet.western) {
      _ensure(must, '종합비타민', '식단 보완에 도움이 돼요',
          RecommendationCategory.mustTake, 1);
    }
    if (input.isHighStress) {
      _ensure(highly, '마그네슘', '스트레스 완화에 좋아요',
          RecommendationCategory.highlyRecommended, 2);
      _ensure(highly, '비타민B군 종합', '스트레스 시 B군 소모 증가',
          RecommendationCategory.highlyRecommended, 2);
      _ensure(consider, 'L-테아닌', '긴장 완화에 도움이 돼요',
          RecommendationCategory.considerIf, 3);
    }
    if (input.sleepLevel == SleepLevel.poor) {
      _ensure(highly, '마그네슘', '근육 이완과 수면에 좋아요',
          RecommendationCategory.highlyRecommended, 2);
      _ensure(consider, '멜라토닌', '수면 유도에 도움이 돼요',
          RecommendationCategory.considerIf, 3);
    }
    if (input.isVegetarian) {
      _ensure(must, '비타민B12', '채식으로 부족한 B12 보충에 좋아요',
          RecommendationCategory.mustTake, 1);
    }
  }

  void _applySymptomBoosts(
    FamilyInput input,
    List<RecommendedSupplement> must,
    List<RecommendedSupplement> highly,
    List<RecommendedSupplement> consider,
  ) {
    for (final id in input.symptomIds) {
      final sym =
          _symptoms.firstWhere((s) => s.id == id, orElse: () => _emptySymptom);
      if (sym.id.isEmpty) continue;
      for (final link in sym.relatedSupplements) {
        if (link.relevance == 'primary') {
          _ensure(highly, link.supplement, link.safeExpression,
              RecommendationCategory.highlyRecommended, 2);
        } else {
          _ensure(consider, link.supplement, link.safeExpression,
              RecommendationCategory.considerIf, 3);
        }
      }
    }
  }

  /// Stage 5 (no-checkup) compensation: when the user is pregnant or
  /// breastfeeding, several supplements move into 꼭 챙겨야 해요.
  void _applyPregnancyBoosts(
    FamilyInput input,
    List<RecommendedSupplement> must,
    List<RecommendedSupplement> highly,
    List<RecommendedSupplement> consider,
  ) {
    if (input.isPregnant) {
      _ensure(must, '엽산', '임신 중 신경관 발달에 필수예요',
          RecommendationCategory.mustTake, 1);
      _ensure(must, '철분', '임신 중 빈혈 예방에 좋아요',
          RecommendationCategory.mustTake, 1);
      _ensure(must, 'DHA', '태아 두뇌 발달에 도움이 돼요',
          RecommendationCategory.mustTake, 1);
    }
    if (input.isBreastfeeding) {
      _ensure(must, '칼슘', '수유 중 뼈 건강에 좋아요',
          RecommendationCategory.mustTake, 1);
      _ensure(must, '비타민D', '수유 중 칼슘 흡수에 좋아요',
          RecommendationCategory.mustTake, 1);
      _ensure(must, '오메가3', '수유 중 모유 영양에 좋아요',
          RecommendationCategory.mustTake, 1);
    }
  }

  void _applyChildrenFocus(
    FamilyInput input,
    List<RecommendedSupplement> must,
    List<RecommendedSupplement> highly,
    List<RecommendedSupplement> consider,
  ) {
    if (input.ageGroup == AgeGroup.child ||
        input.ageGroup == AgeGroup.toddler) {
      _ensure(must, '유산균', '장 건강에 좋아요',
          RecommendationCategory.mustTake, 1);
      _ensure(must, '비타민D', '성장기 뼈 건강에 좋아요',
          RecommendationCategory.mustTake, 1);
      _ensure(must, '철분', '성장기 산소 운반에 좋아요',
          RecommendationCategory.mustTake, 2);
    }
  }

  void _applyRegionAdjustments(
    List<RecommendedSupplement> must,
    List<RecommendedSupplement> highly,
  ) {
    final region = RegionConfig.current();
    if (region.vitaminDPriority == NutrientPriority.high) {
      final inMust = must.any((r) => r.name == '비타민D');
      if (!inMust) {
        final fromHighly = highly.indexWhere((r) => r.name == '비타민D');
        if (fromHighly >= 0) {
          must.add(highly.removeAt(fromHighly).copyWith(
                category: RecommendationCategory.mustTake,
                priority: 1,
              ));
        }
      }
    }
  }

  void _resolvePersonalizedReasons(
    FamilyInput input,
    List<RecommendedSupplement> list,
  ) {
    for (var i = 0; i < list.length; i++) {
      final guide = getSupplementGuide(list[i].name);
      if (guide == null) continue;
      final reasonKey = _personaKey(input);
      if (reasonKey == null) continue;
      final personalized = guide.personalizedReasons[reasonKey];
      if (personalized != null && personalized.isNotEmpty) {
        list[i] = list[i].copyWith(personalizedReason: personalized);
      }
    }
  }

  String? _personaKey(FamilyInput input) {
    if (input.smoker == true) return 'smoker';
    if (input.isHeavyDrinker) return 'heavy_drinker';
    if (input.ageGroup == AgeGroup.elderly) return 'elderly';
    if (input.ageGroup == AgeGroup.child ||
        input.ageGroup == AgeGroup.toddler) {
      return 'child';
    }
    if (input.gender == Gender.female &&
        input.ageGroup == AgeGroup.adult &&
        input.age >= 30 &&
        input.age < 40) {
      return 'female_30s';
    }
    if (input.isVegetarian) return 'vegetarian';
    if (input.isHighStress) return 'high_stress';
    return null;
  }

  void _ensure(
    List<RecommendedSupplement> list,
    String name,
    String reason,
    RecommendationCategory category,
    int priority,
  ) {
    if (list.any((r) => r.name == name)) return;
    list.add(RecommendedSupplement(
      name: name,
      category: category,
      priority: priority,
      reason: reason,
    ));
  }

  List<RecommendedSupplement> _dedupAcross(
    List<RecommendedSupplement> existing,
    List<RecommendedSupplement> incoming,
  ) {
    final names = existing.map((e) => e.name).toSet();
    final result = <RecommendedSupplement>[];
    for (final r in incoming) {
      if (names.add(r.name)) result.add(r);
    }
    result.sort((a, b) => a.priority.compareTo(b.priority));
    return result;
  }

  List<RecommendedSupplement> _capList(
    List<RecommendedSupplement> list,
    int cap,
  ) {
    if (list.length <= cap) return list;
    return list.take(cap).toList(growable: false);
  }

  Set<String> _coveredFromCurrent(
    FamilyInput input,
    ProductRepository? productRepo,
  ) {
    final result = <String>{};
    if (productRepo == null || input.currentProductIds.isEmpty) return result;
    final intake = input.getCurrentNutrientIntake(productRepo);
    if (intake.containsKey('vitamin_d_iu') &&
        (intake['vitamin_d_iu'] ?? 0) >= 600) {
      result.add('비타민D');
    }
    if (intake.containsKey('omega3_total_mg') &&
        (intake['omega3_total_mg'] ?? 0) >= 500) {
      result.add('오메가3');
    }
    if (intake.containsKey('calcium_mg') &&
        (intake['calcium_mg'] ?? 0) >= 500) {
      result.add('칼슘');
    }
    if (intake.containsKey('iron_mg') && (intake['iron_mg'] ?? 0) >= 8) {
      result.add('철분');
    }
    if (intake.containsKey('magnesium_mg') &&
        (intake['magnesium_mg'] ?? 0) >= 200) {
      result.add('마그네슘');
    }
    if (intake.containsKey('zinc_mg') && (intake['zinc_mg'] ?? 0) >= 7) {
      result.add('아연');
    }
    if (intake.containsKey('vitamin_b12_mcg') &&
        (intake['vitamin_b12_mcg'] ?? 0) >= 2.4) {
      result.add('비타민B12');
    }
    if (intake.containsKey('vitamin_b9_mcg') &&
        (intake['vitamin_b9_mcg'] ?? 0) >= 200) {
      result.add('엽산');
    }
    if (intake.containsKey('probiotics_billion_cfu') &&
        (intake['probiotics_billion_cfu'] ?? 0) >= 30) {
      result.add('유산균');
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Schedule
  // ---------------------------------------------------------------------------

  ScheduleResult getSchedule(List<String> supplements) {
    final bySlot = <ScheduleSlot, List<String>>{
      ScheduleSlot.morning: <String>[],
      ScheduleSlot.lunch: <String>[],
      ScheduleSlot.evening: <String>[],
      ScheduleSlot.beforeSleep: <String>[],
    };

    final morning =
        ((_combinations['time_slot_optimization'] as Map?)?['morning'] as List?)
                ?.map((e) => e.toString())
                .toSet() ??
            const <String>{};
    final lunch =
        ((_combinations['time_slot_optimization'] as Map?)?['lunch'] as List?)
                ?.map((e) => e.toString())
                .toSet() ??
            const <String>{};
    final evening =
        ((_combinations['time_slot_optimization'] as Map?)?['evening'] as List?)
                ?.map((e) => e.toString())
                .toSet() ??
            const <String>{};
    final beforeSleep = ((_combinations['time_slot_optimization']
                    as Map?)?['before_sleep']
                as List?)
            ?.map((e) => e.toString())
            .toSet() ??
        const <String>{};

    final separationRules =
        (_combinations['separation_required'] as List?) ?? const [];

    for (final s in supplements) {
      if (beforeSleep.contains(s)) {
        bySlot[ScheduleSlot.beforeSleep]!.add(s);
      } else if (morning.contains(s)) {
        bySlot[ScheduleSlot.morning]!.add(s);
      } else if (evening.contains(s)) {
        bySlot[ScheduleSlot.evening]!.add(s);
      } else if (lunch.contains(s)) {
        bySlot[ScheduleSlot.lunch]!.add(s);
      } else {
        bySlot[ScheduleSlot.morning]!.add(s);
      }
    }

    for (final rule in separationRules) {
      final m = rule as Map<String, dynamic>;
      final a = (m['a'] as String?) ?? '';
      final b = (m['b'] as String?) ?? '';
      if (a.isEmpty || b.isEmpty) continue;
      bySlot.forEach((slot, items) {
        if (items.contains(a) && items.contains(b)) {
          if (slot == ScheduleSlot.morning) {
            items.remove(b);
            bySlot[ScheduleSlot.evening]!.add(b);
          } else {
            items.remove(a);
            bySlot[ScheduleSlot.morning]!.add(a);
          }
        }
      });
    }

    final conflicts = <ScheduleConflict>[];
    for (final rule in separationRules) {
      final m = rule as Map<String, dynamic>;
      final a = (m['a'] as String?) ?? '';
      final b = (m['b'] as String?) ?? '';
      if (supplements.contains(a) && supplements.contains(b)) {
        conflicts.add(ScheduleConflict(
          a: a,
          b: b,
          reason: (m['reason'] as String?) ?? '',
          separateMinutes: (m['minutes'] as num?)?.toInt() ?? 60,
        ));
      }
    }

    final synergies = <ScheduleSynergy>[];
    final synergyRules = (_combinations['synergy'] as List?) ?? const [];
    for (final rule in synergyRules) {
      final m = rule as Map<String, dynamic>;
      final a = (m['a'] as String?) ?? '';
      final b = (m['b'] as String?) ?? '';
      if (supplements.contains(a) && supplements.contains(b)) {
        synergies.add(ScheduleSynergy(
          a: a,
          b: b,
          benefit: (m['benefit'] as String?) ?? '',
        ));
      }
    }

    return ScheduleResult(
      bySlot: bySlot,
      conflicts: conflicts,
      synergies: synergies,
    );
  }

  // ---------------------------------------------------------------------------
  // Conflict checks
  // ---------------------------------------------------------------------------

  List<ConflictWarning> checkConflicts(
    List<String> supplements,
    List<String> medications,
  ) {
    final warnings = <ConflictWarning>[];

    for (final s in supplements) {
      final guide = getSupplementGuide(s);
      if (guide == null) continue;

      for (final bad in guide.badCombinations) {
        if (supplements.contains(bad.with_) || medications.contains(bad.with_)) {
          warnings.add(ConflictWarning(
            kind: medications.contains(bad.with_)
                ? ConflictKind.supplementDrug
                : ConflictKind.supplementSupplement,
            severity: conflictSeverityFrom(bad.severity),
            title: '$s + ${bad.with_}',
            description: bad.reason,
            solution: bad.solution,
          ));
        }
      }

      for (final drug in guide.drugInteractions) {
        for (final med in medications) {
          if (drug.drugCategory.contains(med) ||
              med.contains(drug.drugCategory)) {
            warnings.add(ConflictWarning(
              kind: ConflictKind.supplementDrug,
              severity: ConflictSeverity.caution,
              title: '$s + ${drug.drugCategory}',
              description: drug.interaction,
              solution: '의사 또는 약사와 상의하세요',
            ));
          }
        }
      }
    }

    final overdoseRules =
        (_combinations['overdose_warnings'] as List?) ?? const [];
    for (final rule in overdoseRules) {
      final m = rule as Map<String, dynamic>;
      final overlap = ((m['common_overlap'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(growable: false);
      var matchCount = 0;
      for (final name in overlap) {
        if (supplements.contains(name)) matchCount++;
      }
      if (matchCount >= 2) {
        warnings.add(ConflictWarning(
          kind: ConflictKind.overdose,
          severity: ConflictSeverity.caution,
          title: overlap.join(' + '),
          description: (m['warning'] as String?) ?? '',
          solution: '한 가지로 통합하는 것을 고려하세요',
        ));
      }
    }

    return warnings;
  }

  static const _emptySymptom = SymptomResult(
    id: '',
    symptom: '',
    type: SymptomType.typeA,
    keywords: [],
    relatedSupplements: [],
    lifestyleTips: [],
    urgency: SymptomUrgency.low,
  );
}

final supplementRepositoryProvider = Provider<SupplementRepository>((ref) {
  return SupplementRepository();
});

final supplementRepositoryLoaderProvider =
    FutureProvider<SupplementRepository>((ref) async {
  final repo = ref.watch(supplementRepositoryProvider);
  await repo.load();
  await repo.loadCache();
  return repo;
});
