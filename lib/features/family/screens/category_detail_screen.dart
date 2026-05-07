import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/product_model.dart';
import '../../../core/data/product_repository.dart';
import '../../../core/services/nutrient_recommender.dart';
import '../../../core/services/product_targeting.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alyak_card.dart';
import '../../../core/widgets/disclaimer_footer.dart';
import '../../../core/widgets/product_image.dart';
import '../../../core/widgets/state_views.dart';
import '../../home/providers/member_analysis_provider.dart';
import '../providers/family_provider.dart';

/// "더보기" page for one category — both nutrient deficits (vitamin_d_iu) and
/// lifestyle categories (liver, sleep). Shows the same 3-tier recommendation
/// row up top, then the entire matching product list with a sort toggle
/// (적정함량 / 판매량). Tapping any card opens the product detail page.
enum _SortMode { fit, popularity, value }

extension on _SortMode {
  String get label => switch (this) {
        _SortMode.fit => '적정함량',
        _SortMode.popularity => '판매량',
        _SortMode.value => '가성비',
      };
}

class CategoryDetailScreen extends ConsumerStatefulWidget {
  final String memberId;

  /// Either a nutrient key (`vitamin_d_iu`) or a category name (`liver`).
  final String categoryKey;

  const CategoryDetailScreen({
    super.key,
    required this.memberId,
    required this.categoryKey,
  });

  @override
  ConsumerState<CategoryDetailScreen> createState() =>
      _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  _SortMode _sort = _SortMode.fit;

  @override
  Widget build(BuildContext context) {
    final member = ref.watch(familyControllerProvider).getMember(widget.memberId);
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
    final analysis = ref.watch(memberNutrientAnalysisProvider(widget.memberId));
    final isCategoryKey = !_looksLikeNutrientKey(widget.categoryKey);

    final displayName = _displayNameFor(
      key: widget.categoryKey,
      isCategory: isCategoryKey,
      analysis: analysis,
    );

    final recommended = isCategoryKey
        ? 0.0
        : analysis.deficits
            .firstWhere(
              (d) => d.nutrient == widget.categoryKey,
              orElse: () => analysis.priority
                  .map((p) => p.deficit)
                  .firstWhere(
                    (d) => d.nutrient == widget.categoryKey,
                    orElse: () => NutrientDeficit(
                      nutrient: widget.categoryKey,
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
          key: widget.categoryKey,
          displayName: displayName,
          recommended: recommended,
          unit: _unitFor(widget.categoryKey),
        ),
      ],
    );
    final picks = recos.isEmpty ? const <RankedProduct>[] : recos.first.picks;

    // Full list of matching products, filtered by persona target match
    // (drops "센트룸 맨" for a female persona, etc.) and sorted.
    final all = repo.all();
    final matching = all
        .where((p) {
          final relevant = isCategoryKey
              ? p.category == widget.categoryKey
              : (p.ingredients[widget.categoryKey] ?? 0) > 0;
          if (!relevant) return false;
          // Honor persona exclusion. The recommender already does this for
          // the top picks; the full list should respect it too.
          return targetMatchScore(product: p, member: member) >= 0;
        })
        .toList(growable: true);

    matching.sort((a, b) => _compare(a, b, _sort, widget.categoryKey, recommended, isCategoryKey));

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
            const SizedBox(height: 10),
            _RecPickGrid(picks: picks),
            const SizedBox(height: 24),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  '전체 리스트 (${matching.length}개)',
                  style: AppTypography.title.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _SortToggle(
                value: _sort,
                onChanged: (v) => setState(() => _sort = v),
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
            for (final p in matching)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ListRow(
                  product: p,
                  onTap: () => context.push('/product/${p.id}'),
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
  const _RecPickGrid({required this.picks});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < picks.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _PickTile(
              tier: picks[i].tier,
              product: picks[i].product,
              onTap: () => context.push('/product/${picks[i].product.id}'),
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
  final String tier;
  final Product product;
  final VoidCallback onTap;
  const _PickTile({
    required this.tier,
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
                  tier,
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

class _SortToggle extends StatelessWidget {
  final _SortMode value;
  final ValueChanged<_SortMode> onChanged;
  const _SortToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_SortMode>(
      tooltip: '정렬',
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final m in _SortMode.values)
          PopupMenuItem(
            value: m,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (m == value)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.check, size: 16, color: AppColors.primary),
                  )
                else
                  const SizedBox(width: 24),
                Text(m.label),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.label,
              style: AppTypography.title.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryInk,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.unfold_more,
                size: 16, color: AppColors.primaryInk),
          ],
        ),
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const _ListRow({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ingredients = product.ingredients.keys.take(3).join(', ');
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
                Text(
                  product.name,
                  style: AppTypography.title.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  product.scheduleLabel,
                  style: AppTypography.caption.copyWith(
                    fontSize: 12,
                    color: AppColors.ink2,
                  ),
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

/// Maps a curated DB category to its "primary" nutrient key. Used by the
/// "적정 함량" sort on category-keyed pages (간 건강 → silymarin_mg etc.) so
/// the result diverges from the popularity sort. Categories not listed here
/// fall back to "ingredient richness" (more distinct nutrients = better
/// balanced product), which suits broad combos like multivitamin / sports.
const Map<String, String> _kCategoryPrimaryNutrient = {
  'liver': 'silymarin_mg',
  'sleep': 'melatonin_mg',
  'magnesium': 'magnesium_mg',
  'calcium': 'calcium_mg',
  'iron': 'iron_mg',
  'vitamin_d': 'vitamin_d_iu',
  'vitamin_c': 'vitamin_c_mg',
  'omega3': 'omega3_total_mg',
  'probiotics': 'probiotics_billion_cfu',
  'probiotic': 'probiotics_billion_cfu',
  'biotin': 'biotin_mcg',
  'lutein': 'lutein_mg',
  'eye': 'lutein_mg',
  'collagen': 'collagen_mg',
  'prenatal': 'vitamin_b9_mcg',
  'pregnancy': 'vitamin_b9_mcg',
  'circulation': 'omega3_total_mg',
  'immune': 'vitamin_c_mg',
  'immunity': 'vitamin_c_mg',
};

@visibleForTesting
int compareForSortMode({
  required Product a,
  required Product b,
  required SortModeApi mode,
  required String key,
  required double recommended,
  required bool isCategoryKey,
}) {
  switch (mode) {
    case SortModeApi.fit:
      return _fitCompare(a, b, key, recommended, isCategoryKey);
    case SortModeApi.popularity:
      return _popRank(a).compareTo(_popRank(b));
    case SortModeApi.value:
      // Without retail prices we approximate "가성비" by package size per
      // daily dose — bigger bottle = more days of stock = better value.
      final ad = a.dailyDose <= 0 ? 0 : a.packageSize ~/ a.dailyDose;
      final bd = b.dailyDose <= 0 ? 0 : b.packageSize ~/ b.dailyDose;
      return bd.compareTo(ad);
  }
}

int _compare(
  Product a,
  Product b,
  _SortMode mode,
  String key,
  double recommended,
  bool isCategoryKey,
) =>
    compareForSortMode(
      a: a,
      b: b,
      mode: SortModeApi.values[mode.index],
      key: key,
      recommended: recommended,
      isCategoryKey: isCategoryKey,
    );

/// "적정 함량" comparator. Three branches:
///   1. Nutrient-keyed page (vitamin_d_iu) → distance from RDI ascending
///      (closer to recommended = better fit).
///   2. Category page with a known primary nutrient (liver→silymarin_mg) →
///      higher amount per daily dose wins. Ties (or zero amounts) fall back
///      to popularity so the order stays stable.
///   3. Category page without a primary nutrient (sports / kids_multivitamin)
///      → ingredient richness (more distinct nutrients) wins. Ties fall back
///      to popularity.
int _fitCompare(
  Product a,
  Product b,
  String key,
  double recommended,
  bool isCategoryKey,
) {
  if (!isCategoryKey && recommended > 0) {
    final ad = ((a.ingredients[key] ?? 0) * a.dailyDose - recommended).abs();
    final bd = ((b.ingredients[key] ?? 0) * b.dailyDose - recommended).abs();
    if (ad != bd) return ad.compareTo(bd);
    return _popRank(a).compareTo(_popRank(b));
  }

  final primary = _kCategoryPrimaryNutrient[key];
  if (primary != null) {
    final av = (a.ingredients[primary] ?? 0) * a.dailyDose;
    final bv = (b.ingredients[primary] ?? 0) * b.dailyDose;
    if (av != bv) return bv.compareTo(av); // more = better
    return _popRank(a).compareTo(_popRank(b));
  }

  // Broad-spectrum categories — richer ingredient profile wins.
  final ac = a.ingredients.values.where((v) => v > 0).length;
  final bc = b.ingredients.values.where((v) => v > 0).length;
  if (ac != bc) return bc.compareTo(ac);
  return _popRank(a).compareTo(_popRank(b));
}

/// Mirror of the private [_SortMode] enum so tests don't have to depend on
/// the screen's internal enum. Order must stay aligned with [_SortMode].
@visibleForTesting
enum SortModeApi { fit, popularity, value }

int _popRank(Product p) => p.popularityRank ?? 9999;
