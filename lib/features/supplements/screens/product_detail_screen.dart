import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/data/models/product_model.dart';
import '../../../core/data/nutrient_labels.dart';
import '../../../core/data/product_category_meta.dart';
import '../../../core/data/product_repository.dart';
import '../../../core/services/product_search_links.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alyak_card.dart';
import '../../../core/widgets/disclaimer_footer.dart';
import '../../../core/widgets/product_image.dart';
import '../../../core/widgets/state_views.dart';

/// Detail page for a curated product (250-DB entry). Renders photo,
/// dosage, category benefit, ingredients table, cautions and external
/// price-search links. The route is `/product/:productId`.
class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(productRepositoryProvider);
    final product = repo.getById(productId);
    if (product == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: const Text('영양제 상세'),
        ),
        body: const ErrorStateView(
          emoji: '🔎',
          title: '제품 정보를 찾을 수 없어요',
          message: '데이터에 등록되지 않았거나 삭제됐을 수 있어요.',
        ),
      );
    }

    final meta = categoryMeta(product.category);

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
        title: Text(
          '영양제 상세',
          style: AppTypography.heading3.copyWith(fontSize: 16),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          _Header(product: product),
          const SizedBox(height: 16),
          _IntakeSection(product: product),
          const SizedBox(height: 16),
          _CategoryBenefitSection(meta: meta, category: product.category),
          if (product.ingredients.isNotEmpty) ...[
            const SizedBox(height: 16),
            _IngredientsSection(product: product),
          ],
          if (meta.cautions.isNotEmpty) ...[
            const SizedBox(height: 16),
            _CautionSection(cautions: meta.cautions),
          ],
          const SizedBox(height: 16),
          _PriceLinksSection(product: product),
          if (product.dataSource != null && product.dataSource!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SourceSection(url: product.dataSource!),
          ],
          const SizedBox(height: 12),
          const DisclaimerFooter(),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Product product;
  const _Header({required this.product});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(child: ProductImage(product: product, size: 220)),
        const SizedBox(height: 14),
        Text(
          product.name,
          textAlign: TextAlign.center,
          style: AppTypography.heading1.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          product.brand,
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(
            fontSize: 13,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class _IntakeSection extends StatelessWidget {
  final Product product;
  const _IntakeSection({required this.product});

  @override
  Widget build(BuildContext context) {
    return AlyakCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionTitle('📋 복용 정보'),
          const SizedBox(height: 10),
          _kvRow('시간', product.intakeTiming.koreanLabel),
          _kvRow(
            '1회 복용',
            '${product.dosePerIntake}${product.unit.isEmpty ? '정' : product.unit}',
          ),
          _kvRow('1일 횟수', '${product.intakesPerDay}회'),
          if (product.intakeNote != null && product.intakeNote!.isNotEmpty)
            _kvRow('참고', product.intakeNote!),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.okBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '✅ 검증된 정보',
              style: AppTypography.micro.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.okInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBenefitSection extends StatelessWidget {
  final ProductCategoryMeta meta;
  final String category;
  const _CategoryBenefitSection({required this.meta, required this.category});

  @override
  Widget build(BuildContext context) {
    return AlyakCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionTitle('💪 효능 / 카테고리'),
          const SizedBox(height: 10),
          _kvRow('카테고리', meta.label),
          const SizedBox(height: 4),
          Text(
            meta.benefit,
            style: AppTypography.body2.copyWith(
              fontSize: 13.5,
              height: 1.55,
              color: AppColors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientsSection extends StatelessWidget {
  final Product product;
  const _IngredientsSection({required this.product});

  @override
  Widget build(BuildContext context) {
    final entries = product.ingredients.entries
        .where((e) => e.value > 0)
        .toList(growable: false);
    return AlyakCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionTitle('📊 영양 성분 (${entries.length}종)'),
          const SizedBox(height: 8),
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                '· ${formatIngredientLine(e.key, e.value)}',
                style: AppTypography.body2.copyWith(
                  fontSize: 13,
                  color: AppColors.ink2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CautionSection extends StatelessWidget {
  final List<String> cautions;
  const _CautionSection({required this.cautions});

  @override
  Widget build(BuildContext context) {
    return AlyakCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionTitle('⚠️ 주의사항'),
          const SizedBox(height: 8),
          for (final c in cautions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                '· $c',
                style: AppTypography.body2.copyWith(
                  fontSize: 13,
                  color: AppColors.warnInk,
                  height: 1.45,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PriceLinksSection extends StatelessWidget {
  final Product product;
  const _PriceLinksSection({required this.product});

  @override
  Widget build(BuildContext context) {
    return AlyakCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionTitle('💰 가격 확인하기'),
          const SizedBox(height: 4),
          Text(
            '실제 가격은 사이트에서 확인해주세요',
            style: AppTypography.caption.copyWith(
              fontSize: 11.5,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PriceLinkCard(
                  label: '네이버 쇼핑',
                  sub: '최저가 검색',
                  brandColor: const Color(0xFF03C75A),
                  onTap: () => _openUrl(
                    context,
                    naverShoppingUrl(product.name),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PriceLinkCard(
                  label: '쿠팡',
                  sub: '최저가 검색',
                  brandColor: const Color(0xFFEE2E3E),
                  onTap: () => _openUrl(
                    context,
                    coupangSearchUrl(product.name),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Outline-only price-search button. White surface, branded 2px stroke,
/// branded label — keeps the brand recognition without the heavy filled
/// pill that read as a primary CTA.
class _PriceLinkCard extends StatelessWidget {
  final String label;
  final String sub;
  final Color brandColor;
  final VoidCallback onTap;

  const _PriceLinkCard({
    required this.label,
    required this.sub,
    required this.brandColor,
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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.r12),
            border: Border.all(color: brandColor, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 16, color: brandColor),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: AppTypography.title.copyWith(
                      fontSize: 14,
                      color: brandColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: AppTypography.caption.copyWith(
                  fontSize: 11.5,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceSection extends StatelessWidget {
  final String url;
  const _SourceSection({required this.url});

  @override
  Widget build(BuildContext context) {
    return AlyakCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _openUrl(context, url),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '📋 정보 출처',
                  style: AppTypography.title.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.open_in_new_rounded,
            color: AppColors.primary,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.title.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

Widget _kvRow(String k, String v) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            k,
            style: AppTypography.caption.copyWith(
              fontSize: 12.5,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: AppTypography.body2.copyWith(
              fontSize: 13.5,
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

Future<void> _openUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('링크를 열 수 없어요'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
