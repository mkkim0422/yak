import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/product_model.dart';
import '../../../core/data/nutrient_labels.dart';
import '../../../core/data/product_repository.dart';
import '../../../core/services/nutrient_recommender.dart';
import '../../../core/services/product_targeting.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alyak_card.dart';
import '../../../core/widgets/disclaimer_footer.dart';
import '../../../core/widgets/intake_timing_badge.dart';
import '../../../core/widgets/product_image.dart';
import '../../../core/widgets/state_views.dart';
import '../../home/providers/member_analysis_provider.dart';
import '../providers/family_provider.dart';

/// "더보기" page for one category — both nutrient deficits (vitamin_d_iu) and
/// lifestyle categories (liver, sleep). Shows the 1·2·3위 추천 row 위쪽,
/// 그리고 카테고리 hard filter 통과 제품 전체 리스트를 판매량 순으로
/// 단일 정렬해 표시합니다. Tapping any card opens the product detail page.
class CategoryDetailScreen extends ConsumerWidget {
  final String memberId;

  /// Either a nutrient key (`vitamin_d_iu`) or a category name (`liver`).
  final String categoryKey;

  const CategoryDetailScreen({
    super.key,
    required this.memberId,
    required this.categoryKey,
  });

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
    final isCategoryKey = !_looksLikeNutrientKey(categoryKey);

    final displayName = _displayNameFor(
      key: categoryKey,
      isCategory: isCategoryKey,
      analysis: analysis,
    );

    final recommended = isCategoryKey
        ? 0.0
        : analysis.deficits
            .firstWhere(
              (d) => d.nutrient == categoryKey,
              orElse: () => analysis.priority
                  .map((p) => p.deficit)
                  .firstWhere(
                    (d) => d.nutrient == categoryKey,
                    orElse: () => NutrientDeficit(
                      nutrient: categoryKey,
                      displayName: displayName,
                      current: 0,
                      recommended: 0,
                      percentage: 0,
                    ),
                  ),
            )
            .recommended;

    final recommender = NutrientRecommender(repo);
    final recos = recommender.recommend(
      member: member,
      nutrients: [
        (
          key: categoryKey,
          displayName: displayName,
          recommended: recommended,
          unit: _unitFor(categoryKey),
        ),
      ],
    );
    final picks = recos.isEmpty ? const <RankedProduct>[] : recos.first.picks;

    // 카테고리 hard filter 통과 제품 전체 — 판매량 순 정렬. 추천 카드의
    // 1·2·3위는 이 리스트의 상위 3개와 동일합니다(분리 X).
    final all = repo.all();
    final matching = all
        .where((p) {
          if (!_categoryHardMatchScreen(p, categoryKey, isCategoryKey)) {
            return false;
          }
          return targetMatchScore(product: p, member: member) >= 0;
        })
        .toList(growable: true);

    matching.sort((a, b) => _popRank(a).compareTo(_popRank(b)));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          '$displayName 추천',
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
          if (picks.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '추천 제품',
              style: AppTypography.title.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '판매량 순',
              style: AppTypography.caption.copyWith(
                fontSize: 11.5,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 10),
            _RecPickGrid(picks: picks, memberId: memberId),
            const SizedBox(height: 24),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '전체 리스트 (${matching.length}개)',
                      style: AppTypography.title.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '판매량 순',
                      style: AppTypography.caption.copyWith(
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (matching.isEmpty)
            const EmptyStateView(
              emoji: '🔎',
              title: '아직 추천할 제품이 없어요',
              message: '검증된 250개 DB에 등록되면 여기에 표시돼요.',
              padding: EdgeInsets.symmetric(horizontal: 0, vertical: 24),
            )
          else
            for (var i = 0; i < matching.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ListRow(
                  product: matching[i],
                  rank: i < 3 ? i + 1 : null,
                  onTap: () => context.push(
                    '/product/${matching[i].id}?member=$memberId',
                  ),
                ),
              ),
          const SizedBox(height: 16),
          const DisclaimerFooter(),
        ],
      ),
    );
  }
}

class _RecPickGrid extends StatelessWidget {
  final List<RankedProduct> picks;
  final String memberId;
  const _RecPickGrid({required this.picks, required this.memberId});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < picks.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _PickTile(
              rank: picks[i].rank,
              product: picks[i].product,
              onTap: () => context.push(
                '/product/${picks[i].product.id}?member=$memberId',
              ),
            ),
          ),
        ],
        if (picks.length < 3)
          for (var i = picks.length; i < 3; i++) ...[
            const SizedBox(width: 8),
            const Expanded(child: SizedBox()),
          ],
      ],
    );
  }
}

class _PickTile extends StatelessWidget {
  final int rank;
  final Product product;
  final VoidCallback onTap;
  const _PickTile({
    required this.rank,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.r12),
            border: Border.all(color: AppColors.hairline, width: 1),
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
                  '$rank위',
                  style: AppTypography.micro.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryInk,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(child: ProductImage(product: product, size: 64)),
              const SizedBox(height: 6),
              Text(
                product.name,
                style: AppTypography.title.copyWith(fontSize: 12.5),
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

class _ListRow extends StatelessWidget {
  final Product product;
  final int? rank;
  final VoidCallback onTap;
  const _ListRow({
    required this.product,
    required this.onTap,
    this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final ingredients =
        product.ingredients.keys.take(3).map(nutrientLabel).join(', ');
    return AlyakCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          ProductImage(product: product, size: 60),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (rank != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$rank위',
                          style: AppTypography.micro.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryInk,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        product.name,
                        style: AppTypography.title.copyWith(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      product.scheduleLabel,
                      style: AppTypography.caption.copyWith(
                        fontSize: 12,
                        color: AppColors.ink2,
                      ),
                    ),
                    IntakeTimingBadge(timing: product.intakeTiming),
                  ],
                ),
                if (ingredients.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    ingredients,
                    style: AppTypography.caption.copyWith(
                      fontSize: 11.5,
                      color: AppColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              size: 20, color: AppColors.faint),
        ],
      ),
    );
  }
}

bool _looksLikeNutrientKey(String key) {
  return key.endsWith('_mg') ||
      key.endsWith('_iu') ||
      key.endsWith('_mcg') ||
      key.endsWith('_g') ||
      key.endsWith('_billion_cfu');
}

String _unitFor(String key) {
  if (key.endsWith('_iu')) return 'IU';
  if (key.endsWith('_mcg')) return 'mcg';
  if (key.endsWith('_billion_cfu')) return '억CFU';
  if (key.endsWith('_g')) return 'g';
  if (key.endsWith('_mg')) return 'mg';
  return '';
}

String _displayNameFor({
  required String key,
  required bool isCategory,
  required MemberAnalysis analysis,
}) {
  if (!isCategory) {
    final found = analysis.deficits.firstWhere(
      (d) => d.nutrient == key,
      orElse: () => analysis.priority.map((p) => p.deficit).firstWhere(
            (d) => d.nutrient == key,
            orElse: () => NutrientDeficit(
              nutrient: key,
              displayName: key,
              current: 0,
              recommended: 0,
              percentage: 0,
            ),
          ),
    );
    return found.displayName;
  }
  final ls = analysis.lifestyleSuggestions
      .where((s) => s.category == key)
      .toList(growable: false);
  if (ls.isNotEmpty) return ls.first.displayName;
  return _categoryDisplayFallback(key);
}

String _categoryDisplayFallback(String category) {
  return switch (category) {
    'multivitamin' => '종합비타민',
    'vitamin_d' => '비타민D',
    'vitamin_c' => '비타민C',
    'vitamin_b' => '비타민B군',
    'omega3' => '오메가3',
    'magnesium' => '마그네슘',
    'calcium' => '칼슘',
    'iron' => '철분',
    'probiotics' => '유산균',
    'liver' => '간 건강',
    'sleep' => '수면 보조',
    'sports' => '운동 보조',
    'eye' => '눈 건강',
    'lutein' => '루테인',
    'collagen' => '콜라겐',
    'prenatal' => '임산부 종합',
    'kids_multivitamin' => '어린이 종합',
    _ => category,
  };
}

/// 화면 측에서 전체 리스트를 거를 때 쓰는 hard filter — 추천 엔진과 동일
/// 규칙을 재현해 카드 1·2·3위와 전체 리스트 1·2·3위가 일치하도록 보장.
/// 엔진의 private `_categoryHardMatch`을 화면에서도 호출할 수 있게 그대로
/// 옮겨둡니다.
bool _categoryHardMatchScreen(Product p, String key, bool isCategoryKey) {
  if (isCategoryKey) return p.category == key;

  final amount = p.ingredients[key] ?? 0;
  if (amount <= 0) return false;

  final keyBase = _baseFromNutrientKey(key);
  if (keyBase != null) {
    if (p.category == keyBase) return true;
    if (p.category.startsWith(keyBase)) return true;
    if (keyBase == 'omega3' &&
        (p.category == 'omega3' || p.category == 'krill_oil')) {
      return true;
    }
  }

  final ingredientCount = p.ingredients.values.where((v) => v > 0).length;
  if (ingredientCount <= 2) return true;

  return false;
}

String? _baseFromNutrientKey(String key) {
  for (final suffix in const [
    '_billion_cfu',
    '_mcg',
    '_mg',
    '_iu',
    '_g',
  ]) {
    if (key.endsWith(suffix)) {
      return key.substring(0, key.length - suffix.length);
    }
  }
  return null;
}

int _popRank(Product p) => p.popularityRank ?? 9999;
