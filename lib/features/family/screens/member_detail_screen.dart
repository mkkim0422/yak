import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/product_model.dart';
import '../../../core/data/nutrient_labels.dart';
import '../../../core/data/product_repository.dart';
import '../../../core/notifications/notification_provider.dart';
import '../../../core/security/secure_storage.dart';
import '../../../core/services/conflict_checker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alyak_buttons.dart';
import '../../../core/widgets/alyak_card.dart';
import '../../../core/widgets/conflict_section.dart';
import '../../../core/widgets/disclaimer_footer.dart';
import '../../../core/widgets/product_image.dart';
import '../../../core/widgets/product_photo.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/section_header.dart';
import '../../home/providers/member_analysis_provider.dart';
import '../../home/widgets/nutrient_status_widgets.dart';
import '../../onboarding/screens/notification_setup_screen.dart';
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
    final conflicts = ConflictChecker.check(
      member: member,
      products: curatedProducts,
      manuals: member.manualProducts,
    );

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
          if (conflicts.isNotEmpty) ...[
            const SizedBox(height: 20),
            ConflictSection(conflicts: conflicts),
          ],
          const SizedBox(height: 20),
          _CheckupSection(member: member),
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
        GestureDetector(
          onTap: onEdit,
          child: ProfileAvatar(
            member: member,
            size: 72,
            showEditHint: true,
          ),
        ),
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
          action: _AddPill(
            onTap: () => _openAddSheet(context, member.id),
          ),
        ),
        if (taking == 0)
          _AddSupplementCard(
            empty: true,
            onTap: () => _openAddSheet(context, member.id),
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
          const SizedBox(height: 4),
          _AddSupplementCard(
            onTap: () => _openAddSheet(context, member.id),
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

/// Compact teal pill for the section-header "+ 추가" — visually loud
/// enough to read at a glance, unlike the previous tiny text-button.
class _AddPill extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                '추가하기',
                style: AppTypography.title.copyWith(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Big tappable add-supplement card. Used both as the empty-state hero
/// and as the trailing slot below the supplement list — the dashed teal
/// border + central "+" icon make it impossible to miss.
class _AddSupplementCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool empty;
  const _AddSupplementCard({required this.onTap, this.empty = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primarySoft.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(AppRadius.r14),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r14),
        onTap: onTap,
        child: DottedBox(
          radius: AppRadius.r14,
          color: AppColors.primary,
          dash: const [6, 4],
          strokeWidth: 1.5,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: empty ? 24 : 18,
            ),
            child: Row(
              children: [
                Container(
                  width: empty ? 48 : 42,
                  height: empty ? 48 : 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: empty ? 26 : 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        empty ? '영양제 추가하기' : '영양제 더 추가하기',
                        style: AppTypography.title.copyWith(
                          fontSize: 15,
                          color: AppColors.primaryInk,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        empty
                            ? '검증된 250개 DB 검색 또는 직접 입력'
                            : '라벨 검색 또는 직접 입력',
                        style: AppTypography.caption.copyWith(
                          fontSize: 12,
                          color: AppColors.primaryInk
                              .withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lightweight dashed-border container — keeps the dependency graph clean
/// (no extra package) and matches the look DottedBorder gives us.
class DottedBox extends StatelessWidget {
  final Widget child;
  final double radius;
  final Color color;
  final List<double> dash;
  final double strokeWidth;

  const DottedBox({
    super.key,
    required this.child,
    required this.radius,
    required this.color,
    this.dash = const [6, 4],
    this.strokeWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(
        radius: radius,
        color: color,
        dash: dash,
        strokeWidth: strokeWidth,
      ),
      child: child,
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final double radius;
  final Color color;
  final List<double> dash;
  final double strokeWidth;

  _DashedRectPainter({
    required this.radius,
    required this.color,
    required this.dash,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final dashed = _dashedPath(path, dash);
    canvas.drawPath(dashed, paint);
  }

  Path _dashedPath(Path source, List<double> pattern) {
    final result = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      int idx = 0;
      while (distance < metric.length) {
        final len = pattern[idx % pattern.length];
        if (draw) {
          result.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
        idx++;
      }
    }
    return result;
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth;
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

List<String> _allIngredientLines(Map<String, double> ingredients) {
  if (ingredients.isEmpty) return const [];
  final entries =
      ingredients.entries.where((e) => e.value > 0).toList(growable: false);
  return [
    for (final e in entries) formatIngredientLine(e.key, e.value),
  ];
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

class _CheckupSection extends ConsumerStatefulWidget {
  final FamilyMember member;
  const _CheckupSection({required this.member});

  @override
  ConsumerState<_CheckupSection> createState() => _CheckupSectionState();
}

class _CheckupSectionState extends ConsumerState<_CheckupSection> {
  Future<void> _editCheckup() async {
    final result = await showCheckupEditor(
      context: context,
      initialDate: widget.member.lastCheckupDate,
      initialNote: widget.member.checkupNote,
    );
    if (result == null) return;
    final updated = widget.member.copyWith(
      lastCheckupDate: result.date,
      checkupNote: result.note,
    );
    await ref.read(familyControllerProvider).updateMember(updated);
    // Re-anchor the annual checkup notification on the new date — but only
    // when the user has the checkup-reminder toggle enabled.
    final svc = ref.read(notificationServiceProvider);
    await svc.cancelAnnualCheckupReminder(updated.id);
    final checkupOn =
        (await SecureStorage.read(kCheckupEnabledKey)) != '0';
    if (checkupOn) {
      await svc.scheduleAnnualCheckupReminder(
        memberId: updated.id,
        from: result.date,
        memberName: updated.name,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.member.age < 20) return const SizedBox.shrink();
    final date = widget.member.lastCheckupDate;
    final note = widget.member.checkupNote;

    if (date == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '🏥 최근 건강검진'),
          AlyakCard(
            padding: const EdgeInsets.all(16),
            onTap: _editCheckup,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.r10),
                  ),
                  child: const Text('🏥', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '건강검진을 받으셨어요?',
                        style: AppTypography.title.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '검진일을 등록하면 1년 뒤 알려드려요',
                        style: AppTypography.caption.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.faint, size: 18),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: '🏥 최근 건강검진',
          action: AlyakTextButton(
            label: '수정',
            onPressed: _editCheckup,
          ),
        ),
        AlyakCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '검진일 ${_formatCheckupDate(date)}',
                style: AppTypography.title.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (note != null && note.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '메모 · $note',
                  style: AppTypography.body2.copyWith(
                    fontSize: 13,
                    color: AppColors.ink2,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

String _formatCheckupDate(DateTime d) =>
    '${d.year}년 ${d.month}월 ${d.day}일';

class CheckupEditorResult {
  final DateTime date;
  final String? note;
  const CheckupEditorResult({required this.date, this.note});
}

/// Reusable checkup editor — used by the member screen + family-add chat.
/// Returns `null` if the user cancels.
Future<CheckupEditorResult?> showCheckupEditor({
  required BuildContext context,
  DateTime? initialDate,
  String? initialNote,
}) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: initialDate ?? DateTime.now(),
    firstDate: DateTime(DateTime.now().year - 5),
    lastDate: DateTime.now(),
    helpText: '건강검진 받으신 날짜',
  );
  if (picked == null) return null;
  if (!context.mounted) return null;

  final controller = TextEditingController(text: initialNote ?? '');
  final note = await showDialog<String>(
    context: context,
    builder: (dctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.r20),
      ),
      title: const Text('메모 (선택)'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 200,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: '예: 콜레스테롤 200, 정상',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dctx).pop(''),
          child: const Text('건너뛰기'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dctx).pop(controller.text.trim()),
          child: const Text('저장'),
        ),
      ],
    ),
  );
  if (note == null) return null;
  return CheckupEditorResult(
    date: picked,
    note: note.isEmpty ? null : note,
  );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '보충 필요 영양소'),
        NutrientPriorityCard(items: analysis.priority),
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
