import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/models/symptom_result.dart';
import '../../../core/data/supplement_repository.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class SymptomSearchScreen extends ConsumerStatefulWidget {
  const SymptomSearchScreen({super.key});

  @override
  ConsumerState<SymptomSearchScreen> createState() =>
      _SymptomSearchScreenState();
}

class _SymptomSearchScreenState extends ConsumerState<SymptomSearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  bool _showAll = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(supplementRepositoryProvider);
    final all = repo.allSymptoms();
    final top = repo.getTopSymptoms();
    final filtered = _query.isEmpty
        ? (_showAll ? all : top)
        : all
            .where((s) =>
                s.symptom.contains(_query) ||
                s.keywords.any((k) => k.contains(_query)))
            .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('증상 검색')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('🤒 어떤 증상이 있으세요?', style: AppTypography.heading2),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            decoration: const InputDecoration(
              hintText: '증상 검색',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in filtered)
                ActionChip(
                  label: Text(s.symptom),
                  onPressed: () => _showResult(context, s),
                ),
            ],
          ),
          if (_query.isEmpty && !_showAll && all.length > top.length) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _showAll = true),
              child: Text('전체 보기 (${all.length}개) →'),
            ),
          ],
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text('검색 결과가 없어요',
                  style: AppTypography.body2,
                  textAlign: TextAlign.center),
            ),
          const SizedBox(height: 24),
          Text(
            AppStrings.disclaimerNotMedicalAdvice,
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showResult(BuildContext context, SymptomResult symptom) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => _SymptomResultBody(
          symptom: symptom,
          scrollController: scrollCtrl,
        ),
      ),
    );
  }
}

class _SymptomResultBody extends StatelessWidget {
  final SymptomResult symptom;
  final ScrollController scrollController;
  const _SymptomResultBody({
    required this.symptom,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final isTypeB = symptom.type == SymptomType.typeB;
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        Text(symptom.symptom, style: AppTypography.heading2),
        const SizedBox(height: 8),
        if (isTypeB)
          _typeBBody(symptom)
        else
          _typeABody(context, symptom),
        const SizedBox(height: 16),
        Text(
          AppStrings.disclaimerNotMedicalAdvice,
          style: AppTypography.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

Widget _typeABody(BuildContext context, SymptomResult symptom) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _section('💊 추천 영양제'),
      if (symptom.relatedSupplements.isEmpty)
        const Text('추천할 영양제가 없어요')
      else
        for (final r in symptom.relatedSupplements)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(' · ${r.supplement} — ${r.safeExpression}',
                style: AppTypography.body1),
          ),
      const SizedBox(height: 16),
      _section('🥗 생활 습관 팁'),
      if (symptom.lifestyleTips.isEmpty)
        const Text('등록된 팁이 없어요')
      else
        for (final t in symptom.lifestyleTips)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(' · $t', style: AppTypography.body1),
          ),
      const SizedBox(height: 16),
      _section('⚠️ 다음 증상 시 병원 방문'),
      Text(
        symptom.medicalMessage ??
            '증상이 2주 이상 지속되거나 일상생활에 큰 지장이 있다면 의사 상담을 권합니다.',
        style: AppTypography.body1,
      ),
    ],
  );
}

Widget _typeBBody(SymptomResult symptom) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warningLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          symptom.medicalMessage ??
              '이 증상은 영양제보다는 의사의 진단이 필요해요',
          style: AppTypography.body1,
        ),
      ),
      const SizedBox(height: 16),
      _section('💊 영양제는 보조적 역할'),
      if (symptom.relatedSupplements.isEmpty)
        const Text('보조적으로 도움이 될 수 있는 영양제 목록이 없어요')
      else
        for (final r in symptom.relatedSupplements)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(' · ${r.supplement}', style: AppTypography.body1),
          ),
    ],
  );
}

Widget _section(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: AppTypography.heading3),
    );
