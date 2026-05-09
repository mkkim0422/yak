import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/data/kdris_2025.dart';
import '../../../core/data/models/product_model.dart';
import '../../../core/data/nutrient_evaluation.dart';
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
import '../../family/models/family_member.dart';
import '../../family/providers/family_provider.dart';

/// Detail page for a curated product (250-DB entry). Renders photo,
/// dosage, category benefit, ingredients table, cautions and external
/// price-search links. The route is `/product/:productId` with an optional
/// `?member=ID` query parameter — when supplied, the ingredients section
/// renders KDRIs 2025 권장량 대비 % alongside each row.
class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  final String? memberId;
  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.memberId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(productRepositoryProvider);
    final product = repo.getById(productId);
    final member = (memberId == null || memberId!.isEmpty)
        ? null
        : ref.watch(familyControllerProvider).getMember(memberId!);
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
            _IngredientsSection(product: product, member: member),
          ],
          if (meta.cautions.isNotEmpty) ...[
            const SizedBox(height: 16),
            _CautionSection(cautions: meta.cautions),
          ],
          const SizedBox(height: 16),
          _PriceLinksSection(product: product),
          if (!isDeadSourceUrl(product.dataSource)) ...[
            const SizedBox(height: 16),
            _SourceSection(url: product.dataSource!),
          ],
          const SizedBox(height: 12),
          const ProductInfoDisclaimer(),
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
    // 라벨 정보 유무 — 검증된 250개 DB 중 26개는 ingredients가 비어 있어
    // 영양 분석 비교 대상에서 제외됩니다. 사용자가 그 사실을 인지할 수
    // 있도록 뱃지를 분기.
    final hasLabel = product.ingredients.isNotEmpty;
    final pillColor = hasLabel ? AppColors.okBg : AppColors.warnBg;
    final pillInk = hasLabel ? AppColors.okInk : AppColors.warnInk;
    final pillText =
        hasLabel ? '✅ 라벨 검증 / 분석 가능' : '📋 라벨 정보 없음';

    return AlyakCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionTitle('📋 복용 정보'),
          const SizedBox(height: 10),
          _kvRow('시간', product.intakeTiming.koreanLabel),
          _kvRow('복용량', _doseLine(product)),
          if (product.intakeNote != null && product.intakeNote!.isNotEmpty)
            _kvRow('참고', product.intakeNote!),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: pillColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              pillText,
              style: AppTypography.micro.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: pillInk,
              ),
            ),
          ),
          if (!hasLabel) ...[
            const SizedBox(height: 8),
            Text(
              '본 제품은 공개 라벨에서 영양 성분을 확보하지 못했습니다. '
              '추천·충돌 분석에는 제외되며, 정확한 함량은 제품 라벨을 직접 '
              '확인해 주세요.',
              style: AppTypography.caption.copyWith(
                fontSize: 11.5,
                color: AppColors.warnInk,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "1일 N회 X정씩" 단일 줄 — n=1이면 "1일 1회 X정", n>=2면 "씩" 접미사로
/// 분복임을 명시. 이전엔 "1회 복용 / 1일 횟수"로 분리됐던 두 줄을 하나로.
String _doseLine(Product p) {
  final unit = p.unit.isEmpty ? '정' : p.unit;
  final n = p.intakesPerDay;
  final dose = p.dosePerIntake;
  if (n <= 1) return '1일 1회 $dose$unit';
  return '1일 $n회 $dose$unit씩';
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
  final FamilyMember? member;
  const _IngredientsSection({required this.product, this.member});

  @override
  Widget build(BuildContext context) {
    final entries = product.ingredients.entries
        .where((e) => e.value > 0)
        .toList(growable: false);
    final m = member;
    final headerSuffix =
        m != null ? ' (${m.name}님 권장량 대비)' : '';

    // 베타카로틴 → 비타민A 환산. β-carotene 12 μg = 비타민A 1 μg RAE
    // (식이 기준, 보수적). 비타민A 행에 합산해 표시합니다.
    final dailyAmounts = <String, double>{
      for (final e in entries) e.key: e.value * product.dailyDose,
    };
    final betaCaroteneMg = dailyAmounts['beta_carotene_mg'] ?? 0;
    final vitaminAFromBeta = betaCaroteneMg * 1000 / 12; // mg → μg / 12
    final hasVitaminA = (dailyAmounts['vitamin_a_mcg'] ?? 0) > 0;
    final hasBetaCarotene = betaCaroteneMg > 0;

    return AlyakCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionTitle('📊 영양 성분 (${entries.length}종)$headerSuffix'),
          const SizedBox(height: 8),
          for (final e in entries)
            _IngredientRow(
              nutrientKey: e.key,
              dailyAmount: e.value * product.dailyDose,
              // 비타민A 행에는 베타카로틴 환산 추가량을 더함.
              extraAmount: e.key == 'vitamin_a_mcg' && hasBetaCarotene
                  ? vitaminAFromBeta
                  : 0,
              extraNote: e.key == 'vitamin_a_mcg' && hasBetaCarotene
                  ? '+ β-카로틴 환산 ${vitaminAFromBeta.toStringAsFixed(0)} mcg'
                  : null,
              member: m,
            ),
          // 베타카로틴만 있고 비타민A는 없는 경우 — 환산값을 별도 가상행으로
          // 노출해 사용자가 "이 제품의 비타민A 활성도"를 인지하도록.
          if (!hasVitaminA && hasBetaCarotene)
            _IngredientRow(
              nutrientKey: 'vitamin_a_mcg',
              dailyAmount: vitaminAFromBeta,
              extraNote: '※ β-카로틴 $betaCaroteneMg mg 환산',
              member: m,
              isDerived: true,
            ),
          if (m != null) ...[
            const SizedBox(height: 12),
            const _ExcessiveExplainer(),
          ],
          const SizedBox(height: 8),
          Text(
            m == null
                ? '※ 권장량 비교는 가족 멤버 화면에서 영양제 카드를 탭해 확인하세요.'
                : '※ ${m.name}님 만 ${m.age}세 ${m.sex.label} 기준\n'
                    '※ 권장량 출처: 2025 한국인 영양소 섭취기준',
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// "💡 권장량보다 많은 이유" 펼침 카드 — 사용자가 '많아요' / 충분 표시를
/// 보고 위험 인식을 가지지 않도록 친근한 안내. 식약처 인정 안전 함량
/// 사실 + 의사 상담 권고 한 줄.
class _ExcessiveExplainer extends StatefulWidget {
  const _ExcessiveExplainer();

  @override
  State<_ExcessiveExplainer> createState() => _ExcessiveExplainerState();
}

class _ExcessiveExplainerState extends State<_ExcessiveExplainer> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        onTap: () => setState(() => _open = !_open),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '권장량보다 많은 이유',
                      style: AppTypography.title.copyWith(
                        fontSize: 13,
                        color: AppColors.primaryInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: AppColors.primaryInk,
                  ),
                ],
              ),
              if (_open) ...[
                const SizedBox(height: 8),
                Text(
                  '영양제는 권장량보다 많이 들어 있어요. '
                  '식약처가 인정한 안전한 함량이지만, '
                  '복용 결정 전 의사·약사와 상담하세요.',
                  style: AppTypography.body2.copyWith(
                    fontSize: 12.5,
                    color: AppColors.ink2,
                    height: 1.55,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 영양 성분 한 줄 — 4단계 평가 + 쉬운 표현.
///
/// 모토: 30-40대 엄마가 1초에 이해. % / 전문 용어 / 영문 약어 X.
///   * ✅ 충분해요 (권장량 90% 이상, UL 이내)
///   * ⚠️ N mg 부족해요 (권장량 90% 미만)
///   * ⚠️ N mg 많아요 (UL 초과)
///   * ℹ️ 정보 없음 (KDRIs 매트릭스 외 영양소)
class _IngredientRow extends StatelessWidget {
  final String nutrientKey;
  final double dailyAmount;
  final double extraAmount; // 베타카로틴 환산 등 추가 합산.
  final String? extraNote;
  final FamilyMember? member;
  final bool isDerived; // 베타카로틴→비타민A 같은 파생 행

  const _IngredientRow({
    required this.nutrientKey,
    required this.dailyAmount,
    this.extraAmount = 0,
    this.extraNote,
    required this.member,
    this.isDerived = false,
  });

  @override
  Widget build(BuildContext context) {
    final m = member;
    final totalAmount = dailyAmount + extraAmount;
    final base = isDerived
        ? '· (환산) ${formatIngredientLine(nutrientKey, totalAmount)}'
        : '· ${formatIngredientLine(nutrientKey, totalAmount)}';

    // 멤버 컨텍스트 X — 함량만 표시 (영양제 검색에서 직접 진입 케이스).
    if (m == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: _rowOnlyAmount(base, extraNote: extraNote),
      );
    }

    final recommended = recommendedKDRIs2025(
      nutrient: nutrientKey,
      age: m.age,
      isMale: m.sex == Sex.male,
      isPregnant: m.isPregnant,
      isLactating: m.isBreastfeeding,
    );
    final upperLimit = upperLimitKDRIs2025(nutrientKey);
    final eval = evaluateNutrient(
      amount: totalAmount,
      recommended: recommended,
      upperLimit: upperLimit,
    );
    final unit = _unitForKey(nutrientKey);
    final statusText = statusLabelFor(eval, unit);
    final statusColor = _colorFor(eval.status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 영양소 + 함량 (단위 단순화).
          Text(
            base,
            style: AppTypography.body2.copyWith(
              fontSize: 13.5,
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          // 4단계 평가 라벨.
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              statusText,
              style: AppTypography.body2.copyWith(
                fontSize: 12.5,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (extraNote != null) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                extraNote!,
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _rowOnlyAmount(String base, {String? extraNote}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          base,
          style: AppTypography.body2.copyWith(
            fontSize: 13.5,
            color: AppColors.ink2,
          ),
        ),
        if (extraNote != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 2),
            child: Text(
              extraNote,
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                color: AppColors.muted,
              ),
            ),
          ),
      ],
    );
  }
}

/// 영양소 키 → 사용자 친화 단위 (α-TE / RAE / NE / DFE 제거).
String _unitForKey(String key) {
  if (key.endsWith('_iu')) return 'IU';
  if (key.endsWith('_mcg')) return 'mcg';
  if (key.endsWith('_billion_cfu')) return '억CFU';
  if (key.endsWith('_g')) return 'g';
  if (key.endsWith('_mg')) return 'mg';
  return '';
}

/// NutrientStatus → 색상.
///   * sufficient   → 녹색 (success)
///   * insufficient → 주황 (warning)
///   * excessive    → 빨강 (danger)
///   * unknown      → 회색 (muted)
Color _colorFor(NutrientStatus status) {
  switch (status) {
    case NutrientStatus.sufficient:
      return AppColors.okInk;
    case NutrientStatus.insufficient:
      return AppColors.warnInk;
    case NutrientStatus.excessive:
      return AppColors.danger;
    case NutrientStatus.unknown:
      return AppColors.muted;
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
