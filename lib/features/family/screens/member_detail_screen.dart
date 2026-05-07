import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/product_model.dart';
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
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../home/providers/member_analysis_provider.dart';
import '../../home/widgets/nutrient_status_widgets.dart';
import '../../onboarding/screens/notification_setup_screen.dart';
import '../models/family_member.dart';
import '../providers/family_provider.dart';
import '../services/intake_grouping.dart';

class MemberDetailScreen extends ConsumerWidget {
  final String memberId;
  const MemberDetailScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(familyProvider).getMember(memberId);

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
    final schedule = buildGroupedSchedule(
      curatedProducts: curatedProducts,
      manuals: member.manualProducts,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: '💊 섭취중인 영양제 · $taking개',
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
          for (final slot in IntakeSlot.values)
            if (schedule.forSlot(slot).isNotEmpty) ...[
              _SlotHeader(slot: slot, count: schedule.forSlot(slot).length),
              const SizedBox(height: 6),
              for (final occ in schedule.forSlot(slot))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _CompactSupplementCard(
                    occurrence: occ,
                    onTap: () => _openOccurrence(context, member.id, occ),
                    onRemove: () =>
                        _removeOccurrence(context, ref, member, occ),
                  ),
                ),
              const SizedBox(height: 10),
            ],
          _AddSupplementCard(
            onTap: () => _openAddSheet(context, member.id),
          ),
        ],
      ],
    );
  }

  void _openOccurrence(
    BuildContext context,
    String memberId,
    IntakeOccurrence occ,
  ) {
    if (occ.isCurated) {
      context.push('/product/${occ.entryId}');
    } else {
      context.push(
        '/supplement/manual/edit/${occ.entryId}?member=$memberId',
      );
    }
  }

  Future<void> _removeOccurrence(
    BuildContext context,
    WidgetRef ref,
    FamilyMember member,
    IntakeOccurrence occ,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r20),
        ),
        title: const Text('이 영양제를 삭제할까요?'),
        content: Text(occ.name),
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
    if (ok != true || !context.mounted) return;

    if (occ.isCurated && occ.product != null) {
      await _removeCurated(context, ref, member, occ.product!);
    } else if (!occ.isCurated && occ.manual != null) {
      await _removeManual(context, ref, member, occ.manual!);
    }
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

/// Compact (≈80px tall) supplement card. Shows the photo, the entry
/// name, and a one-line dose label like "식후 2정". Tap to open the
/// detail page (or the manual-edit screen for user-input entries).
class _CompactSupplementCard extends StatelessWidget {
  final IntakeOccurrence occurrence;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _CompactSupplementCard({
    required this.occurrence,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final occ = occurrence;
    final unit = occ.unit.isEmpty ? '정' : occ.unit;
    final mealLabel = occ.mealRelation.label;
    final doseLine = mealLabel.isEmpty
        ? '${occ.dose}$unit'
        : '$mealLabel ${occ.dose}$unit';

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.r12),
            border: Border.all(color: AppColors.hairline, width: 1),
          ),
          child: Row(
            children: [
              if (occ.isCurated && occ.product != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.r10),
                  child: ProductImage(product: occ.product!, size: 60),
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.r10),
                  ),
                  child: const Text('💊', style: TextStyle(fontSize: 24)),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      occ.name,
                      style: AppTypography.title.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            doseLine,
                            style: AppTypography.body2.copyWith(
                              fontSize: 12.5,
                              color: AppColors.ink2,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _SourcePill(curated: occ.isCurated),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppColors.muted,
                visualDensity: VisualDensity.compact,
                splashRadius: 18,
                tooltip: '삭제',
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourcePill extends StatelessWidget {
  final bool curated;
  const _SourcePill({required this.curated});

  @override
  Widget build(BuildContext context) {
    final label = curated ? '✅ 검증' : '📝 직접';
    final bg = curated ? AppColors.okBg : AppColors.surfaceMuted;
    final fg = curated ? AppColors.okInk : AppColors.ink2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.micro.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}

/// Time-of-day section header (🌅 아침 (3개) etc.). Stays simple even
/// when the slot is empty so the user keeps a sense of the daily
/// rhythm — empty slots render with a faint "(없음)" hint.
class _SlotHeader extends StatelessWidget {
  final IntakeSlot slot;
  final int count;
  const _SlotHeader({required this.slot, required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count == 0
        ? '${slot.emoji} ${slot.label} (없음)'
        : '${slot.emoji} ${slot.label} ($count개)';
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2, left: 2),
      child: Text(
        label,
        style: AppTypography.title.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: count == 0 ? AppColors.faint : AppColors.ink,
        ),
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
                      if (empty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '검증된 250개 DB 검색 또는 직접 입력',
                          style: AppTypography.caption.copyWith(
                            fontSize: 12,
                            color: AppColors.primaryInk
                                .withValues(alpha: 0.85),
                          ),
                        ),
                      ],
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
                      '추천 영양제 보기',
                      style: AppTypography.title.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '내게 필요한 영양제를 알려드려요',
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
