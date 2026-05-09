import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/symptom_result.dart';
import '../../../core/data/supplement_repository.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alyak_card.dart';
import '../../../core/widgets/disclaimer_footer.dart';

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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: const Text('컨디션별 영양 가이드'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          Container(
            key: const Key('condition-legal-disclaimer'),
            margin: const EdgeInsets.only(
              top: AppSpacing.m,
              bottom: AppSpacing.sm,
            ),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ℹ️', style: TextStyle(fontSize: 14)),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    AppStrings.conditionScreenLegalDisclaimer,
                    style: AppTypography.body2.copyWith(
                      fontSize: 12.5,
                      color: AppColors.primaryInk,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '어떤 컨디션이세요?',
            style: AppTypography.heading1.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _SearchBar(
            controller: _ctrl,
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in filtered)
                _SymptomTile(
                  label: s.symptom,
                  onTap: () => _showResult(context, s),
                ),
            ],
          ),
          if (_query.isEmpty && !_showAll && all.length > top.length) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _showAll = true),
              child: Text(
                '전체 보기 (${all.length}개) →',
                style: AppTypography.title.copyWith(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                '검색 결과가 없어요',
                style: AppTypography.body2,
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 16),
          AlyakCard(
            padding: const EdgeInsets.all(14),
            background: AppColors.primarySoft,
            shadow: const [],
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15)),
            child: Text(
              'ℹ️ 2주 이상 지속되거나 심한 증상은 병원 진료를 받으세요. '
              '영양제는 보조 수단이에요.',
              style: AppTypography.body2.copyWith(
                fontSize: 13,
                color: AppColors.primaryInk,
              ),
            ),
          ),
          const DisclaimerFooter(),
        ],
      ),
    );
  }

  void _showResult(BuildContext context, SymptomResult symptom) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r14),
        boxShadow: AppShadows.card,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTypography.body1.copyWith(fontSize: 14.5),
        decoration: InputDecoration(
          hintText: '증상을 검색해 보세요',
          hintStyle: AppTypography.body1.copyWith(
            fontSize: 14.5,
            color: AppColors.faint,
          ),
          prefixIcon:
              const Icon(Icons.search, size: 20, color: AppColors.muted),
          border: const OutlineInputBorder(borderSide: BorderSide.none),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide.none),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _SymptomTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SymptomTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.r14),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r14),
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.r14),
            border: Border.all(color: AppColors.hairline, width: 1.5),
          ),
          child: Text(
            label,
            style: AppTypography.title.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
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
        Text(symptom.symptom,
            style: AppTypography.heading2.copyWith(fontSize: 18)),
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
          color: AppColors.warnBg,
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: Text(
          symptom.medicalMessage ?? '이 증상은 영양제보다는 의사의 진단이 필요해요',
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
