import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../home/providers/member_analysis_provider.dart';
import '../../home/widgets/nutrient_status_widgets.dart';
import '../models/family_member.dart';
import '../providers/family_provider.dart';

class MemberDetailScreen extends ConsumerWidget {
  final String memberId;
  const MemberDetailScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(familyProvider).getMember(memberId);

    if (member == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('가족 멤버를 찾을 수 없어요')),
      );
    }

    final analysis = ref.watch(memberNutrientAnalysisProvider(memberId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(member.name),
        actions: [
          TextButton(
            onPressed: () => context.push('/family/$memberId/edit'),
            child: const Text(AppStrings.edit),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileHeader(member: member, analysis: analysis),
          const SizedBox(height: 20),
          _QuickActionsCard(memberId: memberId),
          const SizedBox(height: 20),
          _NutritionStatusCard(analysis: analysis),
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

class _ProfileHeader extends StatelessWidget {
  final FamilyMember member;
  final MemberAnalysis analysis;
  const _ProfileHeader({required this.member, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final genderLabel = member.sex.label;
    final lastCheckup = analysis.lastCheckupDate != null
        ? DateFormat('yyyy년 M월', 'ko').format(analysis.lastCheckupDate!)
        : '없음';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(member.avatarEmoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              Text(member.name, style: AppTypography.heading2),
            ],
          ),
          const SizedBox(height: 4),
          Text('${member.age}세 $genderLabel · ${member.relationship.label}',
              style: AppTypography.body2),
          const SizedBox(height: 12),
          _summaryLine('⚠️', '${analysis.deficits.length}개 영양소 부족'),
          _summaryLine('✅', '${analysis.sufficientCount}개 충분히 챙기시는 중'),
          _summaryLine('💊', '${analysis.currentProductCount}개 영양제 복용 중'),
          _summaryLine('📅', '검진: $lastCheckup'),
        ],
      ),
    );
  }
}

Widget _summaryLine(String emoji, String label) {
  return Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: AppTypography.body1)),
      ],
    ),
  );
}

class _QuickActionsCard extends StatelessWidget {
  final String memberId;
  const _QuickActionsCard({required this.memberId});

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
          Text(AppStrings.memberDetailQuickActions,
              style: AppTypography.heading3),
          const SizedBox(height: 12),
          _ActionButton(
            label: '💊 영양제 새로 추천받기',
            onTap: () => context.push('/recommendation/$memberId'),
          ),
          _ActionButton(
            label: '⚠️ 지금 먹는 것 점검',
            onTap: () => context.push('/current-check/$memberId'),
          ),
          _ActionButton(
            label: '🔍 검진 결과 보기/수정',
            onTap: () => context.push('/health-checkup/$memberId'),
          ),
          _ActionButton(
            label: '💊 현재 복용 영양제 관리',
            onTap: () => context.push('/family/$memberId/products'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            foregroundColor: AppColors.textPrimary,
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onTap,
          child: Row(
            children: [
              Expanded(child: Text(label, style: AppTypography.body1)),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _NutritionStatusCard extends StatelessWidget {
  final MemberAnalysis analysis;
  const _NutritionStatusCard({required this.analysis});

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
          Text(AppStrings.memberDetailNutritionStatus,
              style: AppTypography.heading3),
          const SizedBox(height: 12),
          NutrientPriorityCard(items: analysis.priority),
          if (analysis.secondary.isNotEmpty) ...[
            const SizedBox(height: 12),
            NutrientCollapsibleSection(
              title: '🟡 추가로 챙기시면 좋아요',
              count: analysis.secondary.length,
              items: analysis.secondary.map(formatSecondaryLine).toList(),
            ),
          ],
          if (analysis.sufficient.isNotEmpty) ...[
            const SizedBox(height: 12),
            NutrientCollapsibleSection(
              title: '✅ 잘 챙기시는 영양소',
              count: analysis.sufficient.length,
              items: analysis.sufficient
                  .take(8)
                  .map(formatSufficientLine)
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
