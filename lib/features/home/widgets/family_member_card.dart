import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/data/models/family_input.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../family/models/family_member.dart';
import '../../family/providers/family_provider.dart';
import '../providers/member_analysis_provider.dart';

class FamilyMemberCard extends ConsumerWidget {
  final FamilyMember member;
  final bool isLarge;

  const FamilyMemberCard({
    super.key,
    required this.member,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(memberNutrientAnalysisProvider(member.id));

    return GestureDetector(
      onTap: () => context.push('/family/${member.id}'),
      onLongPress: () => _showQuickActions(context, ref, member),
      child: Container(
        decoration: _cardDecoration(analysis),
        padding: EdgeInsets.all(isLarge ? 20 : 14),
        child: isLarge
            ? _LargeCardLayout(member: member, analysis: analysis)
            : _CompactCardLayout(member: member, analysis: analysis),
      ),
    );
  }

  BoxDecoration _cardDecoration(MemberAnalysis analysis) {
    final palette = _paletteFor(analysis.deficits.length);
    return BoxDecoration(
      color: palette.background,
      border: Border.all(color: palette.border, width: 1.5),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}

class _CardPalette {
  final Color background;
  final Color border;
  const _CardPalette(this.background, this.border);
}

_CardPalette _paletteFor(int deficitCount) {
  if (deficitCount == 0) {
    return _CardPalette(
      AppColors.successLight,
      AppColors.success.withValues(alpha: 0.3),
    );
  }
  if (deficitCount <= 2) {
    return _CardPalette(
      AppColors.warningLight,
      AppColors.warning.withValues(alpha: 0.4),
    );
  }
  return _CardPalette(
    AppColors.attentionLight,
    AppColors.attention.withValues(alpha: 0.4),
  );
}

String _genderLabel(Gender g) => g == Gender.male ? '남' : '여';

class _CompactCardLayout extends StatelessWidget {
  final FamilyMember member;
  final MemberAnalysis analysis;

  const _CompactCardLayout({required this.member, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final topDeficits = analysis.deficits.take(2).toList();
    final extraDeficitCount = analysis.deficits.length - topDeficits.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(member.avatarEmoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                member.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Text(
          '${member.age}세 ${_genderLabel(member.gender)}',
          style: AppTypography.caption,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(analysis.statusEmoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                analysis.statusText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final d in topDeficits)
                Text(
                  '· ${d.displayName}',
                  style: AppTypography.body2.copyWith(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              if (extraDeficitCount > 0)
                Text(
                  AppStrings.moreItemsCountTemplate
                      .replaceFirst('%d', extraDeficitCount.toString()),
                  style: AppTypography.caption.copyWith(fontSize: 11),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '💊 ${AppStrings.cardCurrentlyTakingTemplate.replaceFirst('%d', analysis.currentProductCount.toString())}',
          style: AppTypography.caption.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

class _LargeCardLayout extends StatelessWidget {
  final FamilyMember member;
  final MemberAnalysis analysis;

  const _LargeCardLayout({required this.member, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final topDeficits = analysis.deficits.take(3).toList();
    final relationshipSuffix = ' (${member.relationship.label})';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(member.avatarEmoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${member.name}$relationshipSuffix',
                style: AppTypography.heading2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.settings_outlined,
                size: 20, color: AppColors.textSecondary),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${member.age}세 ${_genderLabel(member.gender)}',
          style: AppTypography.body2,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1),
        ),
        if (topDeficits.isNotEmpty) ...[
          Text(
            '⚠️ ${AppStrings.cardDeficientNutrients} (${analysis.deficits.length}개)',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          for (final d in topDeficits)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(' · ${d.displayName}', style: AppTypography.body1),
            ),
          const SizedBox(height: 12),
        ],
        Text(
          '✅ ${AppStrings.cardSufficientNutrients} (${analysis.sufficientCount}개)',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '💊 현재 복용: ${analysis.currentProductCount}개',
          style: AppTypography.body2,
        ),
        const SizedBox(height: 4),
        Text(
          '📅 ${_lastCheckupLine(analysis.lastCheckupDate)}',
          style: AppTypography.body2,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            AppStrings.cardSeeDetail,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

String _lastCheckupLine(DateTime? date) {
  if (date == null) return AppStrings.cardNoCheckup;
  final formatted = DateFormat('yyyy년 M월', 'ko').format(date);
  return AppStrings.cardLastCheckupTemplate.replaceFirst('%s', formatted);
}

void _showQuickActions(
  BuildContext context,
  WidgetRef ref,
  FamilyMember member,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(member.name, style: AppTypography.heading3),
              ),
              _quickActionTile(
                AppStrings.quickActionRecommend,
                () {
                  Navigator.of(sheetContext).pop();
                  context.push('/recommendation/${member.id}');
                },
              ),
              _quickActionTile(
                AppStrings.quickActionCheck,
                () {
                  Navigator.of(sheetContext).pop();
                  context.push('/current-check/${member.id}');
                },
              ),
              _quickActionTile(
                AppStrings.quickActionCheckup,
                () {
                  Navigator.of(sheetContext).pop();
                  context.push('/health-checkup/${member.id}');
                },
              ),
              _quickActionTile(
                AppStrings.quickActionEdit,
                () {
                  Navigator.of(sheetContext).pop();
                  context.push('/family/${member.id}/edit');
                },
              ),
              const Divider(),
              _quickActionTile(
                AppStrings.quickActionRemove,
                () {
                  Navigator.of(sheetContext).pop();
                  ref.read(familyProvider.notifier).removeMember(member.id);
                },
                destructive: true,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text(AppStrings.cancel),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _quickActionTile(String label, VoidCallback onTap,
    {bool destructive = false}) {
  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    title: Text(
      label,
      style: TextStyle(
        fontSize: 15,
        color: destructive ? AppColors.error : AppColors.textPrimary,
      ),
    ),
    onTap: onTap,
  );
}
