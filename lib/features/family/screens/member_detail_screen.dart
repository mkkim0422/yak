import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/product_model.dart';
import '../../../core/data/product_repository.dart';
import '../../../core/notifications/notification_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alyak_buttons.dart';
import '../../../core/widgets/alyak_card.dart';
import '../../../core/widgets/avatar_badge.dart';
import '../../../core/widgets/disclaimer_footer.dart';
import '../../../core/widgets/product_photo.dart';
import '../../../core/widgets/section_header.dart';
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
    final repo = ref.watch(productRepositoryProvider);
    final curatedProducts = member.currentProductIds
        .map(repo.getById)
        .whereType<Product>()
        .toList(growable: false);
    final status = statusFromDeficitCount(analysis.deficits.length);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const SizedBox.shrink(),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          _ProfileHero(
            member: member,
            status: status,
            onEdit: () => context.push('/family/$memberId/edit'),
          ),
          const SizedBox(height: 16),
          _StatusBanner(status: status, analysis: analysis),
          const SizedBox(height: 16),
          _QuickActions(memberId: memberId),
          const SizedBox(height: 16),
          _CurrentSupplementsSection(
            member: member,
            curatedProducts: curatedProducts,
          ),
          const SizedBox(height: 16),
          _NutritionStatusSection(analysis: analysis),
          const SizedBox(height: 8),
          const DisclaimerFooter(),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final FamilyMember member;
  final HealthStatus status;
  final VoidCallback onEdit;
  const _ProfileHero({
    required this.member,
    required this.status,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AvatarBadge(emoji: member.avatarEmoji, status: status, size: 72),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.name,
                style: AppTypography.heading1.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${member.ageLabel} ${member.sex.label} · ${member.relationship.label}',
                style: AppTypography.caption.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.r10),
          child: InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(AppRadius.r10),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.r10),
                boxShadow: AppShadows.card,
              ),
              child: const Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.ink),
            ),
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
    final isOk = status == HealthStatus.ok;
    final title = isOk
        ? '충분히 챙기시는 중'
        : '${analysis.deficits.length}개의 영양소가 부족해요';
    final sub =
        isOk ? '권장 영양소 모두 섭취 중' : '오늘 추천을 확인해 보세요';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: status.bg,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: status.border.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: Text(status.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.title.copyWith(
                    fontSize: 15,
                    color: status.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: AppTypography.caption.copyWith(
                    fontSize: 12.5,
                    color: AppColors.ink2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final String memberId;
  const _QuickActions({required this.memberId});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: PrimaryButton(
            label: '💊 영양제 새로 사기',
            full: true,
            size: AlyakButtonSize.md,
            onPressed: () => context.push('/recommendation/$memberId'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SecondaryButton(
            label: '⚠️ 지금 점검하기',
            full: true,
            size: AlyakButtonSize.md,
            onPressed: () => context.push('/current-check/$memberId'),
          ),
        ),
      ],
    );
  }
}

class _CurrentSupplementsSection extends ConsumerWidget {
  final FamilyMember member;
  final List<Product> curatedProducts;
  const _CurrentSupplementsSection({
    required this.member,
    required this.curatedProducts,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taking = curatedProducts.length + member.manualProducts.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: '💊 현재 복용 중 · $taking개',
          action: AlyakTextButton(
            label: '+ 추가',
            onPressed: () => _openAddSheet(context, member.id),
          ),
        ),
        if (taking == 0)
          AlyakCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('💊', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text(
                  '아직 등록된 영양제가 없어요',
                  style: AppTypography.title.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '드시는 영양제가 있으면 추가해 주세요',
                  style: AppTypography.caption.copyWith(fontSize: 12.5),
                ),
              ],
            ),
          )
        else ...[
          for (final p in curatedProducts)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SupplementProductCard(
                title: p.name,
                meta: _curatedMeta(p),
                verified: true,
                onRemove: () => _removeCurated(ref, member, p.id),
              ),
            ),
          for (final m in member.manualProducts)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SupplementProductCard(
                title: m.name,
                meta: _manualMeta(m),
                verified: false,
                onRemove: () => _removeManual(ref, member, m.id),
              ),
            ),
        ],
      ],
    );
  }

  static String _curatedMeta(Product p) {
    final parts = <String>[
      '${p.dailyDose}${p.unit}/일',
      if (p.brand.isNotEmpty) p.brand,
    ];
    return parts.join(' · ');
  }

  static String _manualMeta(ManualProductEntry m) {
    final parts = <String>[
      '${m.dailyDose}/일',
      if ((m.brand ?? '').isNotEmpty) m.brand!,
      '함량 정보 없음',
    ];
    return parts.join(' · ');
  }

  Future<void> _removeCurated(
    WidgetRef ref,
    FamilyMember member,
    String productId,
  ) async {
    final updated = member.copyWith(
      currentProductIds:
          member.currentProductIds.where((id) => id != productId).toList(),
    );
    await ref.read(familyControllerProvider).updateMember(updated);
    await ref.read(notificationServiceProvider).cancelReorderReminder(
          memberId: member.id,
          productId: productId,
        );
  }

  Future<void> _removeManual(
    WidgetRef ref,
    FamilyMember member,
    String manualId,
  ) async {
    final updated = member.copyWith(
      manualProducts:
          member.manualProducts.where((m) => m.id != manualId).toList(),
    );
    await ref.read(familyControllerProvider).updateMember(updated);
    await ref.read(notificationServiceProvider).cancelReorderReminder(
          memberId: member.id,
          productId: manualId,
        );
  }
}

class _SupplementProductCard extends StatelessWidget {
  final String title;
  final String meta;
  final bool verified;
  final VoidCallback onRemove;

  const _SupplementProductCard({
    required this.title,
    required this.meta,
    required this.verified,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return AlyakCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ProductPhoto(label: '제품', verified: verified),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.title.copyWith(fontSize: 14.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: AppTypography.caption.copyWith(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: AppColors.muted,
            onPressed: () => _confirmDelete(context),
            tooltip: '삭제',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r20),
        ),
        title: const Text('이 영양제를 삭제할까요?'),
        content: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok == true) onRemove();
  }
}

class _NutritionStatusSection extends StatelessWidget {
  final MemberAnalysis analysis;
  const _NutritionStatusSection({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '📊 영양 상태'),
        NutrientPriorityCard(items: analysis.priority),
        if (analysis.secondary.isNotEmpty) ...[
          const SizedBox(height: 12),
          NutrientCollapsibleSection(
            title: '🟡 추가로 챙기시면 좋아요',
            count: analysis.secondary.length,
            items:
                analysis.secondary.map(formatSecondaryLine).toList(),
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
    );
  }
}

void _openAddSheet(BuildContext context, String memberId) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('영양제 추가',
                  style: AppTypography.heading2.copyWith(fontSize: 18)),
              const SizedBox(height: 4),
              Text(
                '드시는 영양제를 추가해요',
                style: AppTypography.caption.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 16),
              _AddSheetTile(
                emoji: '🔍',
                title: '이름으로 검색',
                sub: '검증된 제품 중 찾기',
                primary: true,
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  sheetCtx.push('/supplement/search?member=$memberId');
                },
              ),
              const SizedBox(height: 8),
              _AddSheetTile(
                emoji: '✏️',
                title: '직접 입력',
                sub: '검증된 DB에 없을 때',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  sheetCtx.push('/supplement/manual?member=$memberId');
                },
              ),
              const SizedBox(height: 16),
              SecondaryButton(
                label: '닫기',
                full: true,
                size: AlyakButtonSize.md,
                onPressed: () => Navigator.of(sheetCtx).pop(),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _AddSheetTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String sub;
  final bool primary;
  final VoidCallback onTap;

  const _AddSheetTile({
    required this.emoji,
    required this.title,
    required this.sub,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary ? AppColors.primarySoft : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.r14),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primary ? AppColors.primarySoft : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.r14),
            border: Border.all(
              color: primary ? AppColors.primary : AppColors.hairline,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.title.copyWith(
                        fontSize: 15,
                        color: primary ? AppColors.primaryInk : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: AppTypography.caption.copyWith(
                        fontSize: 12,
                        color: AppColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: primary ? AppColors.primary : AppColors.faint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
