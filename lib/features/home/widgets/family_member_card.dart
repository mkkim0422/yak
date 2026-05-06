import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/avatar_badge.dart';
import '../../family/models/family_member.dart';
import '../../family/providers/family_provider.dart';
import '../providers/member_analysis_provider.dart';

/// Card variants for the home grid (matches design/screens-home.jsx).
enum FamilyCardVariant { large, compact, mini }

class FamilyMemberCard extends ConsumerWidget {
  final FamilyMember member;
  final FamilyCardVariant variant;

  const FamilyMemberCard({
    super.key,
    required this.member,
    this.variant = FamilyCardVariant.compact,
  });

  // Backwards-compat constructor for existing call sites.
  factory FamilyMemberCard.legacy({
    Key? key,
    required FamilyMember member,
    bool isLarge = false,
  }) =>
      FamilyMemberCard(
        key: key,
        member: member,
        variant:
            isLarge ? FamilyCardVariant.large : FamilyCardVariant.compact,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(memberNutrientAnalysisProvider(member.id));
    final status = statusFromDeficitCount(analysis.deficits.length);

    final body = switch (variant) {
      FamilyCardVariant.large =>
        _LargeBody(member: member, analysis: analysis, status: status),
      FamilyCardVariant.compact =>
        _CompactBody(member: member, analysis: analysis, status: status),
      FamilyCardVariant.mini =>
        _MiniBody(member: member, analysis: analysis, status: status),
    };

    return Material(
      color: AppColors.surface,
      borderRadius:
          BorderRadius.circular(_radiusFor(variant)),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(_radiusFor(variant)),
        onTap: () => context.push('/family/${member.id}'),
        onLongPress: () => _showQuickActions(context, ref, member),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.circular(_radiusFor(variant)),
            // Calm hairline border on every variant — drop the colored
            // status outline that previously dominated the card.
            border: Border.all(color: AppColors.hairline, width: 1),
            boxShadow: AppShadows.card,
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(_radiusFor(variant)),
            child: body,
          ),
        ),
      ),
    );
  }

  static double _radiusFor(FamilyCardVariant v) => switch (v) {
        FamilyCardVariant.large => AppRadius.r20,
        FamilyCardVariant.compact => AppRadius.r16,
        FamilyCardVariant.mini => AppRadius.r14,
      };
}

class _LargeBody extends StatelessWidget {
  final FamilyMember member;
  final MemberAnalysis analysis;
  final HealthStatus status;
  const _LargeBody({
    required this.member,
    required this.analysis,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final defs = analysis.deficits;
    final hasDeficits = defs.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header — avatar + name + meta. No status pill, no top stripe.
          Row(
            children: [
              AvatarBadge(emoji: member.avatarEmoji, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      member.name,
                      style: AppTypography.heading2.copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${member.ageLabel} ${member.sex.label} · ${member.relationship.label}',
                      style:
                          AppTypography.caption.copyWith(fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),
          // Primary info — what they're taking. Plain text, no boxes.
          Row(
            children: [
              const Text('💊', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                '챙기시는 영양제 ${analysis.currentProductCount}개',
                style: AppTypography.title.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink2,
                ),
              ),
            ],
          ),
          if (hasDeficits) ...[
            const SizedBox(height: 12),
            Container(height: 1, color: AppColors.divider),
            const SizedBox(height: 10),
            // Secondary info — deficits, calmly. Greyed body, no badge,
            // no colored box, no exclamation marks.
            Text(
              '보충 필요 영양소',
              style: AppTypography.caption.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _deficitSummary(defs),
              style: AppTypography.body2.copyWith(
                fontSize: 13,
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  static String _deficitSummary(List<NutrientDeficit> deficits) {
    final top = deficits.take(2).map((d) => d.displayName).join(', ');
    final extra = deficits.length - 2;
    return extra > 0 ? '$top 외 $extra개' : top;
  }
}

class _CompactBody extends StatelessWidget {
  final FamilyMember member;
  final MemberAnalysis analysis;
  final HealthStatus status;
  const _CompactBody({
    required this.member,
    required this.analysis,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final taking = analysis.currentProductCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  AvatarBadge(
                    emoji: member.avatarEmoji,
                    size: 40,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          member.name,
                          style: AppTypography.title.copyWith(fontSize: 14.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${member.ageLabel} ${member.sex.label}',
                          style: AppTypography.micro.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '💊 $taking개 복용 중',
                    style: AppTypography.body2.copyWith(
                      fontSize: 13,
                      color: AppColors.ink2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  _StatusDot(status: status, hasProducts: taking > 0),
                ],
              ),
            ],
          ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final HealthStatus status;
  final bool hasProducts;
  const _StatusDot({required this.status, required this.hasProducts});

  @override
  Widget build(BuildContext context) {
    final color = !hasProducts
        ? AppColors.faint
        : status == HealthStatus.ok
            ? AppColors.okBorder
            : AppColors.warnBorder;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _MiniBody extends StatelessWidget {
  final FamilyMember member;
  final MemberAnalysis analysis;
  final HealthStatus status;
  const _MiniBody({
    required this.member,
    required this.analysis,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final taking = analysis.currentProductCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AvatarBadge(emoji: member.avatarEmoji, size: 36),
          const SizedBox(height: 8),
          Text(
            member.name,
            style: AppTypography.title.copyWith(fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${member.age}세 ${member.sex.label}',
            style: AppTypography.micro.copyWith(fontSize: 10.5),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '💊 $taking개',
                style: AppTypography.body2.copyWith(
                  fontSize: 11.5,
                  color: AppColors.ink2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _StatusDot(status: status, hasProducts: taking > 0),
            ],
          ),
        ],
      ),
    );
  }
}

void _showQuickActions(
  BuildContext context,
  WidgetRef ref,
  FamilyMember member,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
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
                  ref.read(familyControllerProvider).removeMember(member.id);
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
        fontFamily: AppTypography.family,
        fontSize: 15,
        color: destructive ? AppColors.alertInk : AppColors.ink,
      ),
    ),
    onTap: onTap,
  );
}
