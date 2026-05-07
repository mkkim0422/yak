import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/product_model.dart';
import '../../../core/data/product_repository.dart';
import '../../../core/notifications/notification_provider.dart';
import '../../../core/services/conflict_checker.dart';
import '../../../core/services/nutrient_recommender.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alyak_buttons.dart';
import '../../../core/widgets/alyak_card.dart';
import '../../../core/widgets/conflict_section.dart';
import '../../../core/widgets/disclaimer_footer.dart';
import '../../../core/widgets/product_image.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../home/providers/member_analysis_provider.dart';
import '../models/family_member.dart';
import '../providers/family_provider.dart';

/// Recommendation surface — positive-tone redesign.
///   * "💊 추천 영양제" cards drive the screen (top of fold).
///   * Each card lists 적정 함량 / 판매량 / 가성비 picks for one nutrient.
///   * The "추천 영양소" rollup is collapsed by default (no 0% pressure).
///   * Conflict messages live in the add-confirmation dialog, NOT inline
///     on the recommendation cards.
class RecommendationDetailScreen extends ConsumerWidget {
  final String memberId;
  const RecommendationDetailScreen({super.key, required this.memberId});

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

    // Recommendation is built off the member's deficits (anything < 70% of
    // recommended). If they have no deficits we still show the priority
    // nutrients for that persona so the screen is never empty.
    final nutrientList = analysis.deficits.isNotEmpty
        ? analysis.deficits
        : analysis.priority.map((p) => p.deficit).toList();

    final recommender = NutrientRecommender(repo);
    final recos = recommender.recommend(
      member: member,
      nutrients: [
        for (final d in nutrientList)
          (
            key: d.nutrient,
            displayName: d.displayName,
            recommended: d.recommended,
            unit: _unitFor(d.nutrient),
          ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          '${member.name}님 추천',
          style: AppTypography.heading3.copyWith(fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          if (recos.isEmpty)
            _EmptyHero(member: member)
          else ...[
            const SectionHeader(title: '💊 추천 영양제'),
            for (final r in recos)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _NutrientRecommendationCard(
                  reco: r,
                  member: member,
                ),
              ),
          ],
          const SizedBox(height: 12),
          _NutrientRollup(nutrients: nutrientList),
          const SizedBox(height: 16),
          const _RecommendationDisclaimer(),
          const DisclaimerFooter(),
        ],
      ),
    );
  }
}

class _EmptyHero extends StatelessWidget {
  final FamilyMember member;
  const _EmptyHero({required this.member});

  @override
  Widget build(BuildContext context) {
    return AlyakCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🎉', style: AppTypography.heading1.copyWith(fontSize: 32)),
          const SizedBox(height: 6),
          Text(
            '${member.name}님은 영양 상태가 충분해요',
            style: AppTypography.heading2.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            '지금처럼 식단 + 영양제로 잘 챙기시면 충분합니다.',
            style: AppTypography.body2.copyWith(
              fontSize: 13,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _NutrientRecommendationCard extends ConsumerStatefulWidget {
  final NutrientRecommendation reco;
  final FamilyMember member;
  const _NutrientRecommendationCard({
    required this.reco,
    required this.member,
  });

  @override
  ConsumerState<_NutrientRecommendationCard> createState() =>
      _NutrientRecommendationCardState();
}

class _NutrientRecommendationCardState
    extends ConsumerState<_NutrientRecommendationCard> {
  Future<void> _add(Product product) async {
    final controller = ref.read(familyControllerProvider);
    final repo = ref.read(productRepositoryProvider);
    final freshMember =
        controller.getMember(widget.member.id) ?? widget.member;
    if (freshMember.currentProductIds.contains(product.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 추가된 영양제예요')),
      );
      return;
    }
    final currentProducts = freshMember.currentProductIds
        .map(repo.getById)
        .whereType<Product>()
        .toList(growable: false);
    final added = ConflictChecker.diff(
      member: freshMember,
      products: currentProducts,
      manuals: freshMember.manualProducts,
      candidate: product,
    );
    if (added.isNotEmpty && mounted) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dctx) => ConflictAddDialog(
          conflicts: added,
          productName: product.name,
          onCancel: () => Navigator.of(dctx).pop(false),
          onConfirm: () => Navigator.of(dctx).pop(true),
        ),
      );
      if (ok != true) return;
    }
    if (!mounted) return;

    final updated = freshMember.copyWith(
      currentProductIds: [...freshMember.currentProductIds, product.id],
    );
    await controller.updateMember(updated);
    final dailyDose = product.dailyDose <= 0 ? 1 : product.dailyDose;
    final daysOfStock = product.packageSize ~/ dailyDose;
    final remind = (daysOfStock - 5).clamp(7, 365);
    await ref.read(notificationServiceProvider).scheduleProductReorderReminder(
          memberId: widget.member.id,
          productId: product.id,
          daysFromNow: remind,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name}이(가) 추가됐어요'),
        backgroundColor: AppColors.okInk,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reco;
    return AlyakCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            r.displayName,
            style: AppTypography.title.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          for (final pick in r.picks)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PickRow(
                tier: pick.tier,
                product: pick.product,
                onAdd: () => _add(pick.product),
              ),
            ),
        ],
      ),
    );
  }
}

class _PickRow extends StatelessWidget {
  final String tier;
  final Product product;
  final VoidCallback onAdd;
  const _PickRow({
    required this.tier,
    required this.product,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Row(
        children: [
          ProductImage(product: product, size: 48),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tier,
                    style: AppTypography.micro.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryInk,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  product.name,
                  style: AppTypography.title.copyWith(fontSize: 13.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PrimaryButton(
            label: '+ 추가',
            size: AlyakButtonSize.sm,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _NutrientRollup extends StatefulWidget {
  final List<NutrientDeficit> nutrients;
  const _NutrientRollup({required this.nutrients});

  @override
  State<_NutrientRollup> createState() => _NutrientRollupState();
}

class _NutrientRollupState extends State<_NutrientRollup> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    if (widget.nutrients.isEmpty) return const SizedBox.shrink();
    return AlyakCard(
      padding: EdgeInsets.zero,
      shadow: AppShadows.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.r16),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '추천 영양소 (${widget.nutrients.length}종)',
                      style: AppTypography.title.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),
          if (_open) ...[
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final n in widget.nutrients)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '· ${n.displayName} (권장 ${_formatRecommended(n)})',
                        style: AppTypography.body2.copyWith(
                          fontSize: 13,
                          color: AppColors.ink2,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    '※ 식단으로도 섭취 가능합니다',
                    style: AppTypography.caption.copyWith(fontSize: 11.5),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _formatRecommended(NutrientDeficit d) {
  final unit = _unitFor(d.nutrient);
  final n = d.recommended;
  final str = n >= 100 || n == n.roundToDouble()
      ? n.toStringAsFixed(0)
      : n.toStringAsFixed(1);
  return '$str$unit';
}

class _RecommendationDisclaimer extends StatelessWidget {
  const _RecommendationDisclaimer();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '표시된 정보는 일반 권장이며, 의학적 진단을 대체하지 않습니다.\n'
        '복용 결정 전 의사·약사와 상담하세요.',
        textAlign: TextAlign.center,
        style: AppTypography.caption.copyWith(
          fontSize: 11,
          color: AppColors.muted,
          height: 1.5,
        ),
      ),
    );
  }
}

String _unitFor(String key) {
  // Cheap suffix-based unit extraction so we don't have to import the
  // full nutrient_labels helper here.
  if (key.endsWith('_iu')) return 'IU';
  if (key.endsWith('_mcg')) return 'mcg';
  if (key.endsWith('_billion_cfu')) return '억CFU';
  if (key.endsWith('_g')) return 'g';
  if (key.endsWith('_mg')) return 'mg';
  return '';
}
