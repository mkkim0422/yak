import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/product_model.dart';
import '../../../core/data/product_repository.dart';
import '../../../core/notifications/notification_provider.dart';
import '../../../core/services/conflict_checker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/conflict_section.dart';
import '../../../core/widgets/disclaimer_footer.dart';
import '../../../core/widgets/intake_timing_badge.dart';
import '../../../core/widgets/product_image.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../home/providers/member_analysis_provider.dart';
import '../../home/widgets/nutrient_status_widgets.dart';
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
          _NutritionStatusSection(
            analysis: analysis,
            memberId: memberId,
            member: member,
          ),
          const SizedBox(height: 20),
          _BuyCta(memberId: memberId),
          const SizedBox(height: 12),
          const DisclaimerFooter(),
        ],
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

    final manualCount = member.manualProducts.length;
    // CTA 중복 제거: 영양제 0개일 때는 큰 점선 박스만 노출(우상단 pill 숨김),
    // 1개 이상일 때는 우상단 pill만 노출(점선 박스 숨김). 둘 다 노출하던
    // 기존 패턴은 시각 정보가 과다해 사용자 시선을 분산시켰음.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: '💊 섭취중인 영양제 · $taking개',
          action: taking == 0
              ? null
              : _AddPill(
                  onTap: () => context.push('/supplement/search?member=${member.id}'),
                ),
        ),
        // 직접 입력 제품은 사용자가 함량을 입력하지 않으므로 영양 분석에
        // 반영되지 않음을 명시 (V1 한계 — V1.1에서 ingredients 입력 UI).
        if (manualCount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '※ 직접 입력 $manualCount개는 영양 분석에 반영되지 않아요. '
              '추천/충돌 계산은 검증된 제품 기준입니다.',
              style: AppTypography.caption.copyWith(
                fontSize: 11.5,
                color: AppColors.muted,
                height: 1.45,
              ),
            ),
          ),
        if (taking == 0)
          _AddSupplementCard(
            empty: true,
            onTap: () => context.push('/supplement/search?member=${member.id}'),
          )
        else
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
      ],
    );
  }

  void _openOccurrence(
    BuildContext context,
    String memberId,
    IntakeOccurrence occ,
  ) {
    if (occ.isCurated) {
      // 멤버 컨텍스트로 진입 → 상세 화면이 KDRIs 권장량 대비 % 노출.
      context.push('/product/${occ.entryId}?member=$memberId');
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
    final doseLine = '${occ.dose}$unit';

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
              _OccurrenceThumbnail(occ: occ),
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
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          doseLine,
                          style: AppTypography.body2.copyWith(
                            fontSize: 12.5,
                            color: AppColors.ink2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IntakeTimingBadge(timing: occ.timing),
                        _SourcePill(
                          curated: occ.isCurated,
                          hasIngredients:
                              (occ.product?.ingredients.isNotEmpty ?? false) ||
                                  (occ.manual?.ingredients.isNotEmpty ?? false),
                        ),
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
  final bool hasIngredients;
  const _SourcePill({
    required this.curated,
    required this.hasIngredients,
  });

  @override
  Widget build(BuildContext context) {
    // 3분기: ✅ 검증(분석 가능), 📋 라벨 정보 없음(검증 제품인데 성분
    // 비어있음 - DB 26개), 📝 직접(사용자 입력).
    final String label;
    final Color bg;
    final Color fg;
    if (!curated) {
      label = '📝 직접';
      bg = AppColors.surfaceMuted;
      fg = AppColors.ink2;
    } else if (hasIngredients) {
      label = '✅ 검증';
      bg = AppColors.okBg;
      fg = AppColors.okInk;
    } else {
      label = '📋 라벨 정보 없음';
      bg = AppColors.warnBg;
      fg = AppColors.warnInk;
    }
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

/// Time-of-day section header (🌅 아침 · 3개). The screen now hides empty
/// slots entirely (caller-side guard), so this header always renders with
/// at least one product and never carries a "(없음)" fallback.
class _SlotHeader extends StatelessWidget {
  final IntakeSlot slot;
  final int count;
  const _SlotHeader({required this.slot, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4, left: 2),
      child: Row(
        children: [
          Text(slot.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            slot.label,
            style: AppTypography.title.copyWith(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: AppTypography.micro.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
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

class _NutritionStatusSection extends StatelessWidget {
  final MemberAnalysis analysis;
  final String memberId;
  final FamilyMember member;
  const _NutritionStatusSection({
    required this.analysis,
    required this.memberId,
    required this.member,
  });

  @override
  Widget build(BuildContext context) {
    // 영양제 0개 + 직접 입력도 0개 → 일반 KDRIs 권장 안내로 헤더 변경.
    // "보충 필요"는 권장량 대비 부족 계산이 의미를 갖는 경우(=섭취 데이터
    // 존재)에만 노출하고, 그 외에는 사용자에게 "이 연령대에 자주 부족한
    // 영양소"라는 일반 안내로 압박감을 줄입니다.
    final hasIntake = member.currentProductIds.isNotEmpty ||
        member.manualProducts.isNotEmpty;
    // 영양제 0개 상태에서 헤더가 단순히 "이 연령대에 자주 부족한 영양소"
    // 라고만 보이면 사용자가 "내가 부족한 영양소"로 오인하기 쉬움. 본인
    // 입력이 아직 없다는 점을 헤더 자체에 명시해 압박감을 줄입니다.
    final title = hasIntake
        ? '보충 필요 영양소'
        : '아직 입력 전이에요';
    final sexFull = member.sex == Sex.male ? '남성' : '여성';
    final subtitle = hasIntake
        ? '권장량 대비 부족한 영양소입니다'
        : '같은 ${member.ageLabel} $sexFull이 흔히 부족한 영양소예요';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            subtitle,
            style: AppTypography.caption.copyWith(
              fontSize: 12,
              color: AppColors.muted,
            ),
          ),
        ),
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

/// 시간대 카드 좌측 썸네일 — 검증 제품은 ProductImage, 직접 입력은 사용자가
/// 찍은 약통 사진(`imagePath`) 우선 + 없으면 💊 placeholder.
class _OccurrenceThumbnail extends StatelessWidget {
  final IntakeOccurrence occ;
  const _OccurrenceThumbnail({required this.occ});

  @override
  Widget build(BuildContext context) {
    if (occ.isCurated && occ.product != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.r10),
        child: ProductImage(product: occ.product!, size: 60),
      );
    }
    final manualPath = occ.manual?.imagePath;
    if (manualPath != null && manualPath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.r10),
        child: SizedBox(
          width: 60,
          height: 60,
          child: Image.file(
            File(manualPath),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const _ManualThumbFallback(),
          ),
        ),
      );
    }
    return const _ManualThumbFallback();
  }
}

class _ManualThumbFallback extends StatelessWidget {
  const _ManualThumbFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.r10),
      ),
      child: const Text('💊', style: TextStyle(fontSize: 24)),
    );
  }
}

