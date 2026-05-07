import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/product_model.dart';
import '../../../core/data/product_repository.dart';
import '../../../core/services/nutrient_recommender.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alyak_card.dart';
import '../../../core/widgets/disclaimer_footer.dart';
import '../../../core/widgets/product_image.dart';
import '../../../core/widgets/state_views.dart';
import '../../home/providers/member_analysis_provider.dart';
import '../models/family_member.dart';
import '../providers/family_provider.dart';

/// Recommendation surface — exploration-only.
/// Each row = one nutrient deficit or one lifestyle category. Each row shows
/// up to 3 picks tagged 적정 함량 / 판매량 / 가성비. Tapping a card opens
/// the product detail page; the [+ 추가] button has been removed entirely
/// (adding now happens from the product detail page or the search flow).
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

    final nutrientList = analysis.deficits.isNotEmpty
        ? analysis.deficits
        : analysis.priority.map((p) => p.deficit).toList();

    final recommender = NutrientRecommender(repo);
    final nutrientRecos = recommender.recommend(
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

    final lifestyleRecos = recommender.recommend(
      member: member,
      nutrients: [
        for (final s in analysis.lifestyleSuggestions)
          (key: s.category, displayName: s.displayName, recommended: 0.0, unit: ''),
      ],
    );

    final hasContent = nutrientRecos.isNotEmpty || lifestyleRecos.isNotEmpty;

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
          if (!hasContent)
            _EmptyHero(member: member)
          else ...[
            const _SectionLabel(label: '보충이 필요한 영양제'),
            for (final r in nutrientRecos)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _CategoryCard(
                  title: r.displayName,
                  picks: r.picks,
                  onMore: () => context.push(
                    '/recommendation/$memberId/category/${r.nutrient}',
                  ),
                ),
              ),
            if (lifestyleRecos.isNotEmpty) ...[
              const SizedBox(height: 4),
              const _SectionLabel(label: '추가로 챙기시면 좋은 영양제'),
              for (var i = 0; i < lifestyleRecos.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _CategoryCard(
                    title: lifestyleRecos[i].displayName,
                    reason: i < analysis.lifestyleSuggestions.length
                        ? analysis.lifestyleSuggestions[i].reason
                        : null,
                    picks: lifestyleRecos[i].picks,
                    onMore: () => context.push(
                      '/recommendation/$memberId/category/${lifestyleRecos[i].nutrient}',
                    ),
                  ),
                ),
            ],
          ],
          const SizedBox(height: 16),
          const _RecommendationDisclaimer(),
          const DisclaimerFooter(),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Text(
        label,
        style: AppTypography.heading2.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
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

/// One category row (e.g. "비타민D", "간 건강"). Header + 3-tier pick cards.
/// The cards are tap-only — no inline `+ 추가` action — and route to the
/// product detail page. The trailing `더보기 →` button opens
/// [CategoryDetailScreen] for the full list + sort toggle.
class _CategoryCard extends StatelessWidget {
  final String title;
  final String? reason;
  final List<RankedProduct> picks;
  final VoidCallback onMore;

  const _CategoryCard({
    required this.title,
    required this.picks,
    required this.onMore,
    this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return AlyakCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.title.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _MoreButton(onTap: onMore),
            ],
          ),
          if (reason != null) ...[
            const SizedBox(height: 4),
            Text(
              reason!,
              style: AppTypography.caption.copyWith(
                fontSize: 12,
                color: AppColors.ink2,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < picks.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _TierTile(
                    tier: picks[i].tier,
                    product: picks[i].product,
                    onTap: () =>
                        context.push('/product/${picks[i].product.id}'),
                  ),
                ),
              ],
              if (picks.length < 3)
                for (var i = picks.length; i < 3; i++) ...[
                  const SizedBox(width: 8),
                  const Expanded(child: SizedBox()),
                ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  final VoidCallback onTap;
  const _MoreButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '더보기',
                style: AppTypography.title.copyWith(
                  fontSize: 12.5,
                  color: AppColors.primaryInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right,
                  size: 16, color: AppColors.primaryInk),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierTile extends StatelessWidget {
  final String tier;
  final Product product;
  final VoidCallback onTap;

  const _TierTile({
    required this.tier,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tier,
                  style: AppTypography.micro.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryInk,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(child: ProductImage(product: product, size: 56)),
              const SizedBox(height: 6),
              Text(
                product.name,
                style: AppTypography.title.copyWith(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
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
  if (key.endsWith('_iu')) return 'IU';
  if (key.endsWith('_mcg')) return 'mcg';
  if (key.endsWith('_billion_cfu')) return '억CFU';
  if (key.endsWith('_g')) return 'g';
  if (key.endsWith('_mg')) return 'mg';
  return '';
}
