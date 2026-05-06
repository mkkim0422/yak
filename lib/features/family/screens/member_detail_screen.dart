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
import '../../../core/widgets/product_image.dart';
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
        title: Text(
          '${member.name}의 영양제 관리',
          style: AppTypography.heading3.copyWith(fontSize: 16),
        ),
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
          const SizedBox(height: 20),
          _CurrentSupplementsSection(
            member: member,
            curatedProducts: curatedProducts,
          ),
          const SizedBox(height: 20),
          _NutritionStatusSection(
            analysis: analysis,
            memberId: memberId,
          ),
          const SizedBox(height: 20),
          _BuyCta(memberId: memberId),
          const SizedBox(height: 12),
          const _IntakeSourceDisclaimer(),
          const DisclaimerFooter(),
        ],
      ),
    );
  }
}

class _IntakeSourceDisclaimer extends StatelessWidget {
  const _IntakeSourceDisclaimer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(
        '표시된 복용 정보는 라벨 또는 사용자 입력 기반입니다.\n'
        '정확한 정보는 제품 라벨과 의사·약사 지시를 우선하세요.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          height: 1.55,
          color: AppColors.muted.withValues(alpha: 0.85),
          fontWeight: FontWeight.w500,
        ),
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
              child: _CuratedProductCard(
                product: p,
                onRemove: () => _removeCurated(context, ref, member, p),
              ),
            ),
          for (final m in member.manualProducts)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ManualProductCard(
                entry: m,
                onEdit: () => context.push(
                  '/supplement/manual/edit/${m.id}?member=${member.id}',
                ),
                onRemove: () => _removeManual(context, ref, member, m),
              ),
            ),
        ],
      ],
    );
  }

  Future<void> _removeCurated(
    BuildContext context,
    WidgetRef ref,
    FamilyMember member,
    Product product,
  ) async {
    final updated = member.copyWith(
      currentProductIds:
          member.currentProductIds.where((id) => id != product.id).toList(),
    );
    await ref.read(familyControllerProvider).updateMember(updated);
    await ref.read(notificationServiceProvider).cancelReorderReminder(
          memberId: member.id,
          productId: product.id,
        );
    if (context.mounted) _toastDeleted(context, product.name);
  }

  Future<void> _removeManual(
    BuildContext context,
    WidgetRef ref,
    FamilyMember member,
    ManualProductEntry manual,
  ) async {
    final updated = member.copyWith(
      manualProducts:
          member.manualProducts.where((m) => m.id != manual.id).toList(),
    );
    await ref.read(familyControllerProvider).updateMember(updated);
    await ref.read(notificationServiceProvider).cancelReorderReminder(
          memberId: member.id,
          productId: manual.id,
        );
    if (context.mounted) _toastDeleted(context, manual.name);
  }
}

void _toastDeleted(BuildContext context, String name) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text('$name이(가) 삭제됐어요'),
      backgroundColor: AppColors.muted,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Card for products from the curated 250-product DB.
/// Shows scheduleLabel, "검증된 정보" badge, top ingredients.
class _CuratedProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onRemove;

  const _CuratedProductCard({required this.product, required this.onRemove});

  @override
  State<_CuratedProductCard> createState() => _CuratedProductCardState();
}

class _CuratedProductCardState extends State<_CuratedProductCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final allLines = _allIngredientLines(product.ingredients);
    final ingredientCount = product.ingredients.length;

    return AlyakCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProductImage(product: product, size: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: AppTypography.title.copyWith(fontSize: 14.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.scheduleLabel,
                      style: AppTypography.body2.copyWith(
                        fontSize: 13,
                        color: AppColors.ink2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const _SourceBadge(
                      label: '✅ 검증된 정보',
                      bg: AppColors.okBg,
                      fg: AppColors.okInk,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.muted,
                onPressed: () =>
                    _confirmDelete(context, product.name, widget.onRemove),
                tooltip: '삭제',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (ingredientCount > 0) ...[
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.r10),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.r10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '영양소 $ingredientCount종',
                          style: AppTypography.caption.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink2,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: AppColors.muted,
                          size: 18,
                        ),
                      ],
                    ),
                    if (_expanded) ...[
                      const SizedBox(height: 6),
                      for (final line in allLines)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '· $line',
                            style: AppTypography.body2.copyWith(
                              fontSize: 12,
                              color: AppColors.ink2,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Card for user-input products. Shows scheduleLabel, "직접 입력한 정보"
/// badge, and exposes both edit + delete buttons.
class _ManualProductCard extends StatelessWidget {
  final ManualProductEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _ManualProductCard({
    required this.entry,
    required this.onEdit,
    required this.onRemove,
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
              const ProductPhoto(label: '직접', verified: false),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.name,
                      style: AppTypography.title.copyWith(fontSize: 14.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.scheduleLabel,
                      style: AppTypography.body2.copyWith(
                        fontSize: 13,
                        color: AppColors.ink2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const _SourceBadge(
                      label: '📝 직접 입력한 정보',
                      bg: AppColors.surfaceMuted,
                      fg: AppColors.ink2,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: AppColors.muted,
                onPressed: onEdit,
                tooltip: '수정',
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.muted,
                onPressed: () => _confirmDelete(context, entry.name, onRemove),
                tooltip: '삭제',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.warnBg,
              borderRadius: BorderRadius.circular(AppRadius.r10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '정확한 함량 정보 없음',
                        style: AppTypography.caption.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warnInk,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.intakeNote ?? '정확한 영양 분석이 어려워요',
                        style: AppTypography.caption.copyWith(
                          fontSize: 11.5,
                          color: AppColors.ink2,
                        ),
                      ),
                    ],
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

class _SourceBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _SourceBadge({
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.micro.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

const _knownUnitSuffixes = <String>[
  'billion_cfu',
  'mcg',
  'mg',
  'iu',
  'g',
];

(String base, String unit) _splitNutrientKey(String key) {
  for (final u in _knownUnitSuffixes) {
    if (key.endsWith('_$u')) {
      return (key.substring(0, key.length - u.length - 1), _unitDisplay(u));
    }
  }
  return (key, '');
}

String _unitDisplay(String raw) {
  switch (raw) {
    case 'iu':
      return 'IU';
    case 'billion_cfu':
      return '억CFU';
    default:
      return raw;
  }
}

String _formatAmount(double amount) {
  if (amount >= 100 || amount == amount.roundToDouble()) {
    return amount.toStringAsFixed(0);
  }
  if (amount >= 10) return amount.toStringAsFixed(1);
  return amount.toStringAsFixed(2);
}

const Map<String, String> _nutrientShortLabels = {
  'vitamin_a': '비타민A',
  'vitamin_b1': '비타민B1',
  'vitamin_b2': '비타민B2',
  'vitamin_b3': '비타민B3',
  'vitamin_b5': '비타민B5',
  'vitamin_b6': '비타민B6',
  'vitamin_b7': '비오틴',
  'vitamin_b9': '엽산',
  'vitamin_b12': '비타민B12',
  'vitamin_c': '비타민C',
  'vitamin_d': '비타민D',
  'vitamin_e': '비타민E',
  'vitamin_k': '비타민K',
  'calcium': '칼슘',
  'magnesium': '마그네슘',
  'iron': '철분',
  'zinc': '아연',
  'omega3_total': '오메가3',
  'omega3_epa': 'EPA',
  'omega3_dha': 'DHA',
  'probiotics': '유산균',
  'coenzyme_q10': '코엔자임Q10',
  'lutein': '루테인',
  'zeaxanthin': '지아잔틴',
  'milk_thistle': '밀크씨슬',
  'collagen': '콜라겐',
  'curcumin': '커큐민',
  'selenium': '셀레늄',
  'biotin': '비오틴',
  'folate': '엽산',
  'choline': '콜린',
  'taurine': '타우린',
  'arginine': '아르기닌',
  'theanine': '테아닌',
  'creatine': '크레아틴',
  'protein': '단백질',
  'fiber': '식이섬유',
  'glucosamine': '글루코사민',
  'chondroitin': '콘드로이친',
  'astaxanthin': '아스타잔틴',
  'resveratrol': '레스베라트롤',
  'red_ginseng': '홍삼',
};

List<String> _allIngredientLines(Map<String, double> ingredients) {
  if (ingredients.isEmpty) return const [];
  final entries =
      ingredients.entries.where((e) => e.value > 0).toList(growable: false);
  return [
    for (final e in entries) _formatIngredientLine(e.key, e.value),
  ];
}

String _formatIngredientLine(String key, double value) {
  final (base, unit) = _splitNutrientKey(key);
  final label = _nutrientShortLabels[base] ?? base;
  final amount = _formatAmount(value);
  return unit.isEmpty ? '$label $amount' : '$label $amount$unit';
}

Future<void> _confirmDelete(
  BuildContext context,
  String title,
  VoidCallback onRemove,
) async {
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

class _NutritionStatusSection extends StatelessWidget {
  final MemberAnalysis analysis;
  final String memberId;
  const _NutritionStatusSection({
    required this.analysis,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context) {
    final hasSecondary = analysis.secondary.isNotEmpty;
    final hasSufficient = analysis.sufficient.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '보충 필요 영양소'),
        NutrientPriorityCard(items: analysis.priority),
        if (hasSecondary) ...[
          const SizedBox(height: 12),
          NutrientCollapsibleSection(
            title: '추가로 챙기시면 좋아요',
            count: analysis.secondary.length,
            items: analysis.secondary.map(formatSecondaryLine).toList(),
          ),
        ],
        if (hasSufficient) ...[
          const SizedBox(height: 12),
          NutrientCollapsibleSection(
            title: '잘 챙기시는 영양소',
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

/// Big buy-supplements CTA for the bottom of the member screen. Always
/// rendered (whether or not the user has deficits) — that's the primary
/// action the screen drives toward.
class _BuyCta extends StatelessWidget {
  final String memberId;
  const _BuyCta({required this.memberId});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: InkWell(
        onTap: () => context.push('/recommendation/$memberId'),
        borderRadius: BorderRadius.circular(AppRadius.r16),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.r16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2200ACC1),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                ),
                child: const Text('💊', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '영양제 사러 가기',
                      style: AppTypography.title.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '부족한 영양소와 추천 제품을 알려드려요',
                      style: AppTypography.caption.copyWith(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
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
