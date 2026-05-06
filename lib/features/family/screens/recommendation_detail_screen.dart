import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/models/product_model.dart';
import '../../../core/data/models/recommendation_result.dart';
import '../../../core/data/product_repository.dart';
import '../../../core/data/supplement_repository.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/services/conflict_checker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/conflict_section.dart';
import '../../home/providers/member_analysis_provider.dart';
import '../providers/family_provider.dart';

class RecommendationDetailScreen extends ConsumerWidget {
  final String memberId;
  const RecommendationDetailScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(familyControllerProvider).getMember(memberId);
    if (member == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('가족 멤버를 찾을 수 없어요')),
      );
    }
    final repo = ref.watch(productRepositoryProvider);
    final supplementRepo = ref.watch(supplementRepositoryProvider);
    final analysis = ref.watch(memberNutrientAnalysisProvider(memberId));

    final reco = supplementRepo.getRecommendations(
      member.toFamilyInput(),
      productRepo: repo,
    );

    final picks = <_NutrientPick>[];
    for (final d in analysis.deficits.take(3)) {
      picks.add(_NutrientPick(
        nutrient: d,
        suggestions: _findCandidates(repo, d.nutrient),
      ));
    }

    final productNames = reco.allRecommended.map((r) => r.name).toList();
    final conflicts = supplementRepo.checkConflicts(
      productNames,
      member.medications,
    );

    // Existing supplements vs the top recommended pick — preview what would
    // happen if the user added it, so the screen can show "추가 시 주의".
    final currentProducts = member.currentProductIds
        .map(repo.getById)
        .whereType<Product>()
        .toList(growable: false);
    final addedConflicts = <String, List<ConflictItem>>{};
    for (final pick in picks) {
      if (pick.suggestions.isEmpty) continue;
      final candidate = pick.suggestions.first;
      addedConflicts[candidate.id] = ConflictChecker.diff(
        member: member,
        products: currentProducts,
        manuals: member.manualProducts,
        candidate: candidate,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('${member.name}님 추천')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(
            sufficient: analysis.sufficientCount,
            deficits: analysis.deficits.length,
            recommended: reco.allRecommended.length,
          ),
          const SizedBox(height: 20),
          _section('❌ 부족한 영양소'),
          if (analysis.deficits.isEmpty)
            Text('부족한 영양소가 없어요', style: AppTypography.body2)
          else
            for (final d in analysis.deficits)
              _DeficitCard(deficit: d, member: member),
          const SizedBox(height: 20),
          _section('✅ 현재 잘 챙기시는 것'),
          if (analysis.sufficient.isEmpty)
            Text('아직 분석할 데이터가 없어요', style: AppTypography.body2)
          else
            for (final s in analysis.sufficient.take(8))
              _SufficientLine(line: s),
          const SizedBox(height: 20),
          _section('💊 추천 제품'),
          if (picks.isEmpty)
            Text('추천할 항목이 없어요', style: AppTypography.body2)
          else
            for (final p in picks)
              _NutrientPickCard(
                pick: p,
                addedConflicts: p.suggestions.isEmpty
                    ? const []
                    : addedConflicts[p.suggestions.first.id] ?? const [],
              ),
          const SizedBox(height: 20),
          _section('⚠️ 충돌 / 시너지'),
          if (conflicts.isEmpty)
            Text('충돌 없음', style: AppTypography.body2)
          else
            for (final c in conflicts)
              _WarningLine(title: c.title, body: c.description),
          const SizedBox(height: 16),
          Text(
            AppStrings.disclaimerNotMedicalAdvice,
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NutrientPick {
  final NutrientDeficit nutrient;
  final List<Product> suggestions;
  const _NutrientPick({required this.nutrient, required this.suggestions});
}

List<Product> _findCandidates(ProductRepository repo, String nutrientKey) {
  final all = repo.all();
  final hits = all.where((p) => p.ingredients.containsKey(nutrientKey)).toList();
  hits.sort((a, b) =>
      (a.popularityRank ?? 999).compareTo(b.popularityRank ?? 999));
  return hits.take(3).toList(growable: false);
}

extension on RecommendationResult {
  List<RecommendedSupplement> get allRecommended =>
      [...mustTake, ...highlyRecommended, ...considerIf];
}

Widget _section(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: AppTypography.heading3),
    );

class _SummaryCard extends StatelessWidget {
  final int sufficient;
  final int deficits;
  final int recommended;
  const _SummaryCard({
    required this.sufficient,
    required this.deficits,
    required this.recommended,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📊 영양 상태 요약', style: AppTypography.heading3),
          const SizedBox(height: 8),
          Text('✅ 잘 챙기는 것: $sufficient종', style: AppTypography.body1),
          Text('⚠️ 부족한 것: $deficits종', style: AppTypography.body1),
          Text('💊 추천 영양제: $recommended개', style: AppTypography.body1),
        ],
      ),
    );
  }
}

class _DeficitCard extends StatelessWidget {
  final NutrientDeficit deficit;
  final dynamic member;
  const _DeficitCard({required this.deficit, required this.member});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(deficit.displayName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          Text(
            '현재 ${deficit.current.toStringAsFixed(0)} / 권장 '
            '${deficit.recommended.toStringAsFixed(0)} (${deficit.percentage}%)',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}

class _SufficientLine extends StatelessWidget {
  final NutrientDeficit line;
  const _SufficientLine({required this.line});
  @override
  Widget build(BuildContext context) {
    final source =
        line.sourceProductNames.isEmpty ? '-' : line.sourceProductNames.join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(' · ${line.displayName}  ${line.percentage}% ($source)',
          style: AppTypography.body1),
    );
  }
}

class _NutrientPickCard extends StatelessWidget {
  final _NutrientPick pick;
  final List<ConflictItem> addedConflicts;
  const _NutrientPickCard({
    required this.pick,
    this.addedConflicts = const [],
  });
  @override
  Widget build(BuildContext context) {
    if (pick.suggestions.isEmpty) return const SizedBox.shrink();
    final categories = ['적정 함량', '판매량', '가성비'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💊 ${pick.nutrient.displayName} 추천',
              style: AppTypography.heading3),
          const SizedBox(height: 8),
          for (var i = 0; i < pick.suggestions.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${categories[i.clamp(0, categories.length - 1)]} · '
                '${pick.suggestions[i].name}',
                style: AppTypography.body1,
              ),
            ),
          if (addedConflicts.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '✅ 추가 시 충돌 없음',
                style: AppTypography.caption.copyWith(
                  fontSize: 12,
                  color: AppColors.okInk,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else ...[
            const SizedBox(height: 8),
            Text(
              '⚠️ 추가 시 주의',
              style: AppTypography.caption.copyWith(
                fontSize: 12,
                color: AppColors.warnInk,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            for (final c in addedConflicts)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: ConflictCard(item: c),
              ),
          ],
        ],
      ),
    );
  }
}

class _WarningLine extends StatelessWidget {
  final String title;
  final String body;
  const _WarningLine({required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⚠️ $title',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(body, style: AppTypography.caption),
        ],
      ),
    );
  }
}
