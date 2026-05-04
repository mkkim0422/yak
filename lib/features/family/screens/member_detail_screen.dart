import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/product_model.dart';
import '../../../core/data/product_repository.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/notifications/notification_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(member.name),
        actions: [
          TextButton(
            onPressed: () => context.push('/family/$memberId/edit'),
            child: const Text(AppStrings.edit),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileHeader(member: member),
          const SizedBox(height: 20),
          _CurrentSupplementsSection(
            member: member,
            curatedProducts: curatedProducts,
          ),
          const SizedBox(height: 20),
          _NutritionStatusCard(analysis: analysis),
          const SizedBox(height: 20),
          _RecommendationCta(memberId: memberId),
          const SizedBox(height: 20),
          Text(
            AppStrings.disclaimerNotMedicalAdvice,
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final FamilyMember member;
  const _ProfileHeader({required this.member});

  @override
  Widget build(BuildContext context) {
    final genderLabel = member.sex.label;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(member.avatarEmoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              Text(member.name, style: AppTypography.heading2),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${member.ageLabel} $genderLabel · ${member.relationship.label}',
            style: AppTypography.body2,
          ),
        ],
      ),
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
    final isEmpty =
        curatedProducts.isEmpty && member.manualProducts.isEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💊 지금 드시는 영양제', style: AppTypography.heading3),
          const SizedBox(height: 12),
          if (isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '복용 중인 영양제가 없어요',
                style: AppTypography.body2,
              ),
            )
          else ...[
            for (final p in curatedProducts)
              _CuratedSupplementCard(
                product: p,
                onRemove: () => _removeCurated(ref, member, p.id),
              ),
            for (final m in member.manualProducts)
              _ManualSupplementCard(
                entry: m,
                onRemove: () => _removeManual(ref, member, m.id),
              ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('영양제 추가'),
              onPressed: () => _openAddSheet(context, member.id),
            ),
          ),
        ],
      ),
    );
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

void _openAddSheet(BuildContext context, String memberId) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetCtx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('영양제 검색'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                sheetCtx.push('/supplement/search?member=$memberId');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('직접 추가'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                sheetCtx.push('/supplement/manual?member=$memberId');
              },
            ),
            const ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: Colors.grey),
              title: Text('라벨 촬영', style: TextStyle(color: Colors.grey)),
              subtitle: Text('Phase 2 예정', style: TextStyle(color: Colors.grey)),
              enabled: false,
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}

class _CuratedSupplementCard extends StatelessWidget {
  final Product product;
  final VoidCallback onRemove;
  const _CuratedSupplementCard({
    required this.product,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final summary = _buildIngredientSummary(product.ingredients);
    final brandLine = [
      if (product.brand.isNotEmpty) product.brand,
      '${product.dailyDose}${product.unit}/일',
      '${product.packageSize}${product.unit}',
    ].join(' · ');

    return _SupplementCardShell(
      title: product.name,
      subtitle: brandLine,
      ingredientCount: product.ingredients.length,
      ingredientLines: summary.topLines,
      extraCount: summary.extraCount,
      onRemove: onRemove,
    );
  }
}

class _ManualSupplementCard extends StatelessWidget {
  final ManualProductEntry entry;
  final VoidCallback onRemove;
  const _ManualSupplementCard({required this.entry, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final summary = _buildIngredientSummary(entry.ingredients);
    final parts = [
      if ((entry.brand ?? '').isNotEmpty) entry.brand!,
      '${entry.dailyDose}/일',
      '${entry.packageSize}',
      '직접 입력',
    ];
    return _SupplementCardShell(
      title: entry.name,
      subtitle: parts.join(' · '),
      ingredientCount: entry.ingredients.length,
      ingredientLines: summary.topLines,
      extraCount: summary.extraCount,
      onRemove: onRemove,
    );
  }
}

class _SupplementCardShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final int ingredientCount;
  final List<String> ingredientLines;
  final int extraCount;
  final VoidCallback onRemove;

  const _SupplementCardShell({
    required this.title,
    required this.subtitle,
    required this.ingredientCount,
    required this.ingredientLines,
    required this.extraCount,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💊', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => _confirmDelete(context),
                tooltip: '삭제',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 2),
              child: Text(subtitle, style: AppTypography.caption),
            ),
          if (ingredientCount > 0) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ 채워주는 영양소 ($ingredientCount종)',
                    style: AppTypography.body2.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ingredientLines.join('  ·  '),
                    style: AppTypography.caption,
                  ),
                  if (extraCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '+ 외 $extraCount종',
                        style: AppTypography.caption,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
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

class _NutritionStatusCard extends StatelessWidget {
  final MemberAnalysis analysis;
  const _NutritionStatusCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.memberDetailNutritionStatus,
              style: AppTypography.heading3),
          const SizedBox(height: 12),
          NutrientPriorityCard(items: analysis.priority),
          if (analysis.secondary.isNotEmpty) ...[
            const SizedBox(height: 12),
            NutrientCollapsibleSection(
              title: '🟡 추가로 챙기시면 좋아요',
              count: analysis.secondary.length,
              items: analysis.secondary.map(formatSecondaryLine).toList(),
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
      ),
    );
  }
}

class _RecommendationCta extends StatelessWidget {
  final String memberId;
  const _RecommendationCta({required this.memberId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💊 추천 영양제', style: AppTypography.heading3),
          const SizedBox(height: 4),
          Text(
            '부족한 영양소를 채워줄 제품들을 보여드려요',
            style: AppTypography.body2,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.push('/recommendation/$memberId'),
              child: const Text('추천 영양제 보기 →'),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Ingredient summary helpers
// ──────────────────────────────────────────────────────────────────────

class _IngredientSummary {
  final List<String> topLines;
  final int extraCount;
  const _IngredientSummary(this.topLines, this.extraCount);
}

_IngredientSummary _buildIngredientSummary(
  Map<String, double> ingredients, {
  int top = 5,
}) {
  if (ingredients.isEmpty) return const _IngredientSummary(<String>[], 0);
  final entries = ingredients.entries
      .where((e) => e.value > 0)
      .toList(growable: false);
  if (entries.isEmpty) return const _IngredientSummary(<String>[], 0);
  final lines = <String>[];
  for (final entry in entries.take(top)) {
    lines.add(_formatIngredient(entry.key, entry.value));
  }
  final extra = entries.length - lines.length;
  return _IngredientSummary(lines, extra < 0 ? 0 : extra);
}

String _formatIngredient(String key, double amount) {
  final (base, unit) = _splitNutrientKey(key);
  final label = _nutrientShortLabels[base] ?? _humanizeKey(base);
  final amountStr = _formatAmount(amount);
  if (unit.isEmpty) return '$label $amountStr';
  return '$label $amountStr$unit';
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

String _humanizeKey(String base) {
  return base
      .split('_')
      .map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}')
      .join(' ');
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
  'copper': '구리',
  'manganese': '망간',
  'chromium': '크롬',
  'selenium': '셀레늄',
  'iodine': '요오드',
  'molybdenum': '몰리브덴',
  'phosphorus': '인',
  'potassium': '칼륨',
  'omega3_total': '오메가3',
  'omega3_epa': 'EPA',
  'omega3_dha': 'DHA',
  'probiotics': '유산균',
  'coenzyme_q10': '코엔자임Q10',
  'lutein': '루테인',
  'zeaxanthin': '지아잔틴',
  'milk_thistle': '밀크씨슬',
  'lycopene': '라이코펜',
  'collagen': '콜라겐',
  'glucosamine': '글루코사민',
  'chondroitin': '콘드로이친',
  'curcumin': '커큐민',
  'resveratrol': '레스베라트롤',
  'astaxanthin': '아스타잔틴',
  'taurine': '타우린',
  'arginine': '아르기닌',
  'theanine': '테아닌',
  'glutamine': '글루타민',
  'creatine': '크레아틴',
  'protein': '단백질',
  'fiber': '식이섬유',
  'mct_oil': 'MCT오일',
  'krill_oil': '크릴오일',
  'nac': 'NAC',
  'melatonin': '멜라토닌',
  'biotin': '비오틴',
  'folate': '엽산',
  'choline': '콜린',
  'inositol': '이노시톨',
  'gaba': 'GABA',
  'l_carnitine': '카르니틴',
  'beta_alanine': '베타알라닌',
  'citrulline': '시트룰린',
  'spirulina': '스피루리나',
  'chlorella': '클로렐라',
  'saw_palmetto': '쏘팔메토',
  'ginkgo_biloba': '은행잎',
  'ashwagandha': '아쉬와간다',
  'boswellia': '보스웰리아',
  'cranberry': '크랜베리',
  'red_ginseng': '홍삼',
  'propolis': '프로폴리스',
  'bcaa': 'BCAA',
  'eaa': 'EAA',
  'aakg': 'AAKG',
  '_5htp': '5-HTP',
  'cla': 'CLA',
};
