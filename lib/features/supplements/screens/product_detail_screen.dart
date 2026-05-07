import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/data/kdris_2025.dart';
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
          const SizedBox(height: 6),
          Text(
            m == null
                ? '※ 권장량 비교는 가족 멤버 화면에서 영양제 카드를 탭해 확인하세요. '
                    '기준은 2025 한국인 영양소 섭취기준(KDRIs)을 따릅니다.'
                : '※ 권장량은 ${m.name}님(${m.ageLabel} ${m.sex.label}) 기준이며, '
                    '2025 한국인 영양소 섭취기준(KDRIs)을 따릅니다.',
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

/// 영양 성분 한 줄. 멤버 컨텍스트가 있으면 KDRIs 권장량 대비 % 표시.
///
/// UX 가드:
///   * 200% 초과 → "충분 (200%+)" 회색으로 캡 — "999%" 같은 충격 노출 차단.
///   * UL 초과 → "주의 (UL 초과)" 빨강으로 강조.
///   * KDRIs에 없는 영양소(콜라겐·진세노사이드 등) → 함량만 + "권장량 정보
///     없음" 회색.
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

    // 파생 행은 nutrientKey의 함량 라벨이 아닌 "비타민A 환산" 형태로 표시.
    final base = isDerived
        ? '· (환산) ${formatIngredientLine(nutrientKey, totalAmount)}'
        : '· ${formatIngredientLine(nutrientKey, totalAmount)}';

    if (m == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: _rowText(
          base,
          extraNote: extraNote,
          extraNoteColor: AppColors.muted,
        ),
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

    // 권장량 정보 없음 — 함량만 + 안내.
    if (recommended == null || recommended <= 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: _rowText(
          base,
          tail: ' · 권장량 정보 없음',
          tailColor: AppColors.faint,
          extraNote: extraNote,
          extraNoteColor: AppColors.muted,
        ),
      );
    }

    // UL 초과 우선 — 빨강 "주의".
    if (upperLimit != null && totalAmount > upperLimit) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: _rowText(
          base,
          tail: ' · 주의 (UL 초과)',
          tailColor: AppColors.danger,
          tailBold: true,
          extraNote: extraNote,
          extraNoteColor: AppColors.muted,
        ),
      );
    }

    final pctRaw = totalAmount / recommended * 100;
    final unit = _splitUnit(nutrientKey);
    final recStr = _formatRec(recommended, unit);

    // 200% 초과 캡 — "충분 (200%+)" 회색 (수용성 비타민에서 999% 노출 방지).
    if (pctRaw > 200) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: _rowText(
          base,
          tail: ' / $recStr 권장 · 충분 (200%+)',
          tailColor: AppColors.muted,
          tailBold: false,
          extraNote: extraNote,
          extraNoteColor: AppColors.muted,
        ),
      );
    }

    final pct = pctRaw.round();
    final pctColor = _percentColor(pct);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text.rich(
        TextSpan(
          style: AppTypography.body2.copyWith(
            fontSize: 13,
            color: AppColors.ink2,
          ),
          children: [
            TextSpan(text: base),
            TextSpan(
              text: ' / $recStr 권장',
              style: const TextStyle(color: AppColors.muted),
            ),
            TextSpan(
              text: ' ($pct%)',
              style: TextStyle(
                color: pctColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (extraNote != null)
              TextSpan(
                text: '\n  $extraNote',
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  color: AppColors.muted,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _rowText(
    String base, {
    String? tail,
    Color? tailColor,
    bool tailBold = false,
    String? extraNote,
    Color? extraNoteColor,
  }) {
    return Text.rich(
      TextSpan(
        style: AppTypography.body2.copyWith(
          fontSize: 13,
          color: AppColors.ink2,
        ),
        children: [
          TextSpan(text: base),
          if (tail != null)
            TextSpan(
              text: tail,
              style: TextStyle(
                color: tailColor ?? AppColors.muted,
                fontWeight:
                    tailBold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          if (extraNote != null)
            TextSpan(
              text: '\n  $extraNote',
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                color: extraNoteColor ?? AppColors.muted,
              ),
            ),
        ],
      ),
    );
  }
}

/// % → 색상 5단계.
///   * 50% 미만 = 주황 (보충 필요)
///   * 50-99% = 녹색 (적정 진입)
///   * 100% = 청록 (정상)
///   * 101-200% = 청록 (충분)
///   * 200%+ = 회색 (캡 표시, 별도 처리됨)
///
/// UL 초과는 본 함수 호출 전 별도 분기에서 빨강으로 처리.
Color _percentColor(int pct) {
  if (pct >= 100) return AppColors.primary;
  if (pct >= 50) return AppColors.okInk;
  return AppColors.warnInk;
}

String _splitUnit(String key) {
  if (key.endsWith('_iu')) return 'IU';
  if (key.endsWith('_mcg')) return 'mcg';
  if (key.endsWith('_billion_cfu')) return '억CFU';
  if (key.endsWith('_g')) return 'g';
  if (key.endsWith('_mg')) return 'mg';
  return '';
}

String _formatRec(double v, String unit) {
  final str =
      v >= 100 || v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  return unit.isEmpty ? str : '$str$unit';
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
