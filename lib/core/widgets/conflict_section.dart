import 'package:flutter/material.dart';

import '../services/conflict_checker.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import 'alyak_card.dart';
import 'section_header.dart';

/// "⚠️ 주의 사항" — renders a list of [ConflictItem]s, hiding the section
/// entirely when [conflicts] is empty. Severity drives the colour ramp:
/// info=gray, warning=amber, danger=red.
class ConflictSection extends StatelessWidget {
  final List<ConflictItem> conflicts;
  final bool showDisclaimer;

  const ConflictSection({
    super.key,
    required this.conflicts,
    this.showDisclaimer = true,
  });

  @override
  Widget build(BuildContext context) {
    if (conflicts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: '⚠️ 주의 사항 · ${conflicts.length}개'),
        for (final c in conflicts)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ConflictCard(item: c),
          ),
        if (showDisclaimer) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '표시된 주의사항은 일반 정보이며, 의학적 진단을 대체하지 않습니다.',
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                color: AppColors.muted,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class ConflictCard extends StatelessWidget {
  final ConflictItem item;
  const ConflictCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final palette = _palette(item.severity);
    return AlyakCard(
      padding: const EdgeInsets.all(14),
      background: palette.bg,
      border: Border.all(color: palette.border, width: 1),
      shadow: const [],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  style: AppTypography.title.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.titleInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.message,
                  style: AppTypography.body2.copyWith(
                    fontSize: 13,
                    color: AppColors.ink2,
                    height: 1.4,
                  ),
                ),
                if (item.sourceProductNames.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.sourceProductNames.join(' · '),
                    style: AppTypography.caption.copyWith(
                      fontSize: 11.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Palette {
  final Color bg;
  final Color border;
  final Color titleInk;
  const _Palette(this.bg, this.border, this.titleInk);
}

_Palette _palette(ConflictSeverity s) {
  switch (s) {
    case ConflictSeverity.info:
      return _Palette(
        AppColors.surfaceMuted,
        AppColors.hairline,
        AppColors.ink2,
      );
    case ConflictSeverity.warning:
      return _Palette(
        AppColors.warnBg,
        AppColors.warnBorder.withValues(alpha: 0.4),
        AppColors.warnInk,
      );
    case ConflictSeverity.danger:
      return _Palette(
        AppColors.dangerBg,
        AppColors.danger.withValues(alpha: 0.4),
        AppColors.danger,
      );
  }
}

/// Surface used in dialogs / inline previews — single big icon header.
class ConflictAddDialog extends StatelessWidget {
  final List<ConflictItem> conflicts;
  final String productName;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const ConflictAddDialog({
    super.key,
    required this.conflicts,
    required this.productName,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.r20),
      ),
      title: const Text('⚠️ 확인이 필요해요'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
          maxWidth: 360,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"$productName"을(를) 추가하면 다음을 확인해 주세요:',
                style: AppTypography.body1.copyWith(fontSize: 13.5),
              ),
              const SizedBox(height: 10),
              for (final c in conflicts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${c.title} — ${c.message}',
                          style: AppTypography.body2.copyWith(fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                '확인 후 추가하시겠어요?',
                style: AppTypography.body2.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: onConfirm,
          child: const Text('확인했어요, 추가'),
        ),
      ],
    );
  }
}
