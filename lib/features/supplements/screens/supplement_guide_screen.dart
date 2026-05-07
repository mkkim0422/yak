import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/models/supplement_guide_model.dart';
import '../../../core/data/supplement_repository.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/state_views.dart';

class SupplementGuideScreen extends ConsumerStatefulWidget {
  final String supplementId;
  const SupplementGuideScreen({super.key, required this.supplementId});

  @override
  ConsumerState<SupplementGuideScreen> createState() =>
      _SupplementGuideScreenState();
}

class _SupplementGuideScreenState
    extends ConsumerState<SupplementGuideScreen> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(supplementRepositoryProvider);
    final SupplementGuide? guide = _findGuide(repo, widget.supplementId);
    if (guide == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
        body: const ErrorStateView(
          emoji: '🔎',
          title: '영양소 정보를 찾을 수 없어요',
          message: '데이터에 등록되지 않은 항목입니다.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('${guide.koreanName} 가이드')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('💊 ${guide.koreanName}', style: AppTypography.heading2),
          const SizedBox(height: 8),
          Text(_threeLineSummary(guide), style: AppTypography.body1),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(_expanded
                ? Icons.expand_less
                : Icons.expand_more),
            label: Text(_expanded ? '접기' : '자세히 보기'),
          ),
          if (_expanded) _DetailedSections(guide: guide),
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

SupplementGuide? _findGuide(SupplementRepository repo, String id) {
  // ID may be either the canonical id ('vitamin_d') or the Korean name.
  final byName = repo.getSupplementGuide(id);
  if (byName != null) return byName;
  for (final g in repo.allSupplements()) {
    if (g.id == id) return g;
  }
  return null;
}

String _threeLineSummary(SupplementGuide g) {
  final benefits = g.mainBenefits.take(2).join(', ');
  final timeline =
      g.effectTimeline.isEmpty ? '꾸준한 섭취가 중요해요' : g.effectTimeline;
  return '${g.koreanName}은(는) $benefits에 도움이 돼요.\n'
      '${g.timing.reason.isNotEmpty ? g.timing.reason : '권장 섭취 시간을 지키면 더 좋아요.'}\n'
      '$timeline';
}

class _DetailedSections extends StatelessWidget {
  final SupplementGuide guide;
  const _DetailedSections({required this.guide});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _section('1. 효능'),
        if (guide.mainBenefits.isEmpty)
          const Text('등록된 효능 정보가 없어요')
        else
          for (final b in guide.mainBenefits)
            _bullet(b),
        const SizedBox(height: 16),
        _section('2. 섭취 방법'),
        _bullet('성인 권장량: ${guide.dosage.adult.amount} ${guide.dosage.adult.unit}'),
        if (guide.dosage.child7to12 != null)
          _bullet(
              '7-12세: ${guide.dosage.child7to12!.amount} ${guide.dosage.child7to12!.unit}'),
        if (guide.dosage.elderly60plus != null)
          _bullet(
              '60세 이상: ${guide.dosage.elderly60plus!.amount} ${guide.dosage.elderly60plus!.unit}'),
        if (guide.dosage.upperLimit != null)
          _bullet('상한 섭취량: ${guide.dosage.upperLimit}'),
        _bullet('복용 시간: ${_bestTimeLabel(guide.timing.bestTime)}'),
        _bullet('식사 관계: ${_mealLabel(guide.timing.mealRelation)}'),
        if (guide.timing.reason.isNotEmpty)
          _bullet('이유: ${guide.timing.reason}'),
        const SizedBox(height: 16),
        _section('3. 좋은 조합'),
        if (guide.goodCombinations.isEmpty)
          const Text('등록된 시너지 정보가 없어요')
        else
          for (final c in guide.goodCombinations)
            _bullet('${c.with_} — ${c.reason}'),
        const SizedBox(height: 16),
        _section('4. 함께 먹으면 안 되는 것'),
        if (guide.badCombinations.isEmpty)
          const Text('충돌 정보가 없어요')
        else
          for (final c in guide.badCombinations)
            _bullet('${c.with_} — ${c.reason}'),
        const SizedBox(height: 16),
        _section('5. 주의사항'),
        if (guide.warnings == null || guide.warnings!.isEmpty)
          const Text('특별한 주의사항이 없어요')
        else ...[
          for (final c in guide.warnings!.contraindications)
            _bullet('금기: $c'),
          for (final s in guide.warnings!.sideEffects)
            _bullet('부작용: $s'),
        ],
        if (guide.drugInteractions.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final d in guide.drugInteractions)
            _bullet('약물: ${d.drugCategory} → ${d.interaction}'),
        ],
        const SizedBox(height: 16),
        _section('6. 음식으로'),
        if (guide.foodAlternatives.isEmpty)
          const Text('대체 음식 정보가 없어요')
        else
          for (final f in guide.foodAlternatives)
            _bullet(f.name),
      ],
    );
  }
}

String _bestTimeLabel(BestTime t) {
  switch (t) {
    case BestTime.morning:
      return '아침';
    case BestTime.afternoon:
      return '점심';
    case BestTime.evening:
      return '저녁';
    case BestTime.beforeSleep:
      return '취침 전';
    case BestTime.anytime:
      return '아무 때나';
  }
}

String _mealLabel(String raw) {
  switch (raw) {
    case 'with_food':
      return '식사 중';
    case 'before_food':
      return '식사 전';
    case 'after_food':
      return '식사 후';
    case 'empty_stomach':
      return '공복';
    default:
      return raw;
  }
}

Widget _section(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    );

Widget _bullet(String text) => Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 3),
      child: Text(' · $text', style: AppTypography.body1),
    );
