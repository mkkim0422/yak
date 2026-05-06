import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/avatar_badge.dart';
import '../../../core/widgets/status_pill.dart';
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
            border: Border.all(
              color: variant == FamilyCardVariant.mini
                  ? AppColors.hairline
                  : status.border.withValues(alpha: 0.2),
              width: variant == FamilyCardVariant.mini ? 1 : 1.5,
            ),
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
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(height: 4, color: status.border),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  AvatarBadge(
                    emoji: member.avatarEmoji,
                    status: status,
                    size: 56,
                  ),
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
                          '${member.ageLabel} ${member.sex.label}',
                          style:
                              AppTypography.caption.copyWith(fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  StatusPill(status: status),
                ],
              ),
              const SizedBox(height: 14),
              _StatusBanner(status: status, analysis: analysis),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('💊', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    '${analysis.currentProductCount}개 복용 중',
                    style: AppTypography.caption.copyWith(
                      fontSize: 12.5,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final HealthStatus status;
  final MemberAnalysis analysis;
  const _StatusBanner({required this.status, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final defs = analysis.deficits;
    final isOk = status == HealthStatus.ok;
    final label = isOk ? '충분히 챙기시는 중' : '${defs.length}개 부족';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: status.bg,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.title.copyWith(
              fontSize: 14,
              color: status.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            isOk
                ? '권장 영양소를 모두 섭취 중'
                : _deficitSummary(defs),
            style: AppTypography.caption.copyWith(
              fontSize: 12,
              color: AppColors.ink2,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  static String _deficitSummary(List<NutrientDeficit> deficits) {
    if (deficits.isEmpty) return '오늘 점검이 필요해요';
    final top = deficits.take(2).map((d) => d.displayName).join(', ');
    final extra = deficits.length - 2;
    return extra > 0 ? '$top  +$extra개 더' : top;
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
    final defs = analysis.deficits;
    final isOk = status == HealthStatus.ok;
    final label = isOk ? '충분' : '${defs.length}개 부족';
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Container(width: 3, color: status.border),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  AvatarBadge(
                    emoji: member.avatarEmoji,
                    status: status,
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
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: status.bg,
                  borderRadius: BorderRadius.circular(AppRadius.r8),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: status.ink,
                  ),
                ),
              ),
              if (!isOk && defs.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _topDeficits(defs),
                  style: AppTypography.body2.copyWith(
                    fontSize: 11.5,
                    color: AppColors.ink2,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Text(
                '💊 ${analysis.currentProductCount}개 복용 중',
                style: AppTypography.micro.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _topDeficits(List<NutrientDeficit> defs) {
    final top = defs.take(2).map((d) => d.displayName).join(', ');
    final extra = defs.length - 2;
    return extra > 0 ? '$top +$extra' : top;
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
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(height: 3, color: status.border),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AvatarBadge(
                emoji: member.avatarEmoji,
                status: status,
                size: 36,
              ),
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
              const SizedBox(height: 6),
              Text(
                status == HealthStatus.ok
                    ? '✅ 충분'
                    : '${analysis.deficits.length}개 부족',
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: status.ink,
                ),
              ),
            ],
          ),
        ),
      ],
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
