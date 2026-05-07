import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/product_model.dart';
import '../../../core/data/nutrient_labels.dart';
import '../../../core/data/product_repository.dart';
import '../../../core/data/supplement_repository.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/state_views.dart';
import '../../family/providers/family_provider.dart';
import '../../home/providers/member_analysis_provider.dart';
import '../../home/widgets/nutrient_status_widgets.dart';

class CurrentCheckScreen extends ConsumerWidget {
  final String memberId;
  const CurrentCheckScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(familyControllerProvider).getMember(memberId);
    if (member == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
        body: const ErrorStateView(
          emoji: '🔎',
          title: '가족 멤버를 찾을 수 없어요',
          message: '삭제됐거나 잘못된 링크일 수 있어요.',
        ),
      );
    }
    final repo = ref.watch(productRepositoryProvider);
    final analysis = ref.watch(memberNutrientAnalysisProvider(memberId));
    final products = member.currentProductIds
        .map(repo.getById)
        .whereType<Product>()
        .toList();
    final supplementRepo = ref.watch(supplementRepositoryProvider);
    final conflicts = supplementRepo.checkConflicts(
      products.map((p) => p.name).toList(),
      member.medications,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('${member.name}님 영양제 점검')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('섭취중 (${analysis.currentProductCount}개)'),
          if (analysis.currentProductCount == 0)
            _Empty(memberId: memberId)
          else ...[
            for (final p in products)
              _ProductBrief(
                title: p.name,
                summary: '${p.dailyDose}${p.unit}/일 · '
                    '${p.ingredients.keys.take(3).map(nutrientLabel).join(', ')}',
              ),
            for (final m in member.manualProducts)
              _ProductBrief(
                title: m.name,
                summary:
                    '${m.dailyDose}/일 · ${m.ingredients.keys.take(3).map(nutrientLabel).join(', ')}',
              ),
          ],
          const SizedBox(height: 20),
          _section('✅ 잘 섭취중인 영양소'),
          if (analysis.sufficient.isEmpty)
            Text('아직 분석할 데이터가 없어요', style: AppTypography.body2)
          else
            for (final n in analysis.sufficient.take(8))
              _NutrientLine(
                name: n.displayName,
                detail: '${n.percentage}% (${n.sourceProductNames.join(', ')})',
              ),
          const SizedBox(height: 20),
          _section('⚠️ 충돌 / 과다 경고'),
          if (conflicts.isEmpty)
            Text('✨ 잘 드시고 계세요', style: AppTypography.body1)
          else
            for (final c in conflicts)
              _WarningCard(
                title: c.title,
                body: c.description,
                hint: c.solution ?? '',
              ),
          const SizedBox(height: 20),
          _section('❌ 추가로 필요해요'),
          NutrientPriorityCard(items: analysis.priority),
          if (analysis.secondary.isNotEmpty) ...[
            const SizedBox(height: 12),
            NutrientCollapsibleSection(
              title: '🟡 추가로 챙기시면 좋아요',
              count: analysis.secondary.length,
              items: [
                for (final s in analysis.secondary)
                  ' · ${s.deficit.displayName}  ${s.deficit.percentage}%',
              ],
            ),
          ],
          if (analysis.priority.isNotEmpty) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.push('/recommendation/$memberId'),
              child: const Text('영양제 새로 추천받기 →'),
            ),
          ],
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

Widget _section(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: AppTypography.heading3),
    );

class _ProductBrief extends StatelessWidget {
  final String title;
  final String summary;
  const _ProductBrief({required this.title, required this.summary});
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
          Text('💊 $title',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          Text(summary, style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _NutrientLine extends StatelessWidget {
  final String name;
  final String detail;
  const _NutrientLine({required this.name, required this.detail});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(' · $name  $detail', style: AppTypography.body1),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final String title;
  final String body;
  final String hint;
  const _WarningCard({
    required this.title,
    required this.body,
    required this.hint,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⚠️ $title',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(body, style: AppTypography.body2),
          if (hint.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('→ $hint', style: AppTypography.caption),
          ],
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String memberId;
  const _Empty({required this.memberId});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('섭취중인 영양제가 없어요', style: AppTypography.body1),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => context.push('/family/$memberId/products'),
            child: const Text('영양제 추가하기 →'),
          ),
        ],
      ),
    );
  }
}
