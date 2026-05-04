import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/member_analysis_provider.dart';

/// Tier 1: top deficits with reasons + progress bars. Always expanded.
class NutrientPriorityCard extends StatelessWidget {
  final List<NutrientStatus> items;
  const NutrientPriorityCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('부족한 영양소가 없어요', style: AppTypography.body2),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.attentionLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.attention.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔴 우선 보충 필요',
              style:
                  TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          for (final s in items) _PriorityRow(status: s),
        ],
      ),
    );
  }
}

class _PriorityRow extends StatelessWidget {
  final NutrientStatus status;
  const _PriorityRow({required this.status});

  @override
  Widget build(BuildContext context) {
    final pct = status.deficit.percentage.clamp(0, 100);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(status.deficit.displayName,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 6,
              backgroundColor: Colors.white,
              color: AppColors.attention,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$pct% (현재 ${status.deficit.current.toStringAsFixed(0)} / '
            '권장 ${status.deficit.recommended.toStringAsFixed(0)})',
            style: AppTypography.caption,
          ),
          for (final r in status.reasons.take(3))
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child:
                  Text('  • $r', style: AppTypography.caption),
            ),
        ],
      ),
    );
  }
}

/// Tier 2 / 3: collapsible bullet list.
class NutrientCollapsibleSection extends StatefulWidget {
  final String title;
  final int count;
  final List<String> items;
  final bool initiallyOpen;
  const NutrientCollapsibleSection({
    super.key,
    required this.title,
    required this.count,
    required this.items,
    this.initiallyOpen = false,
  });

  @override
  State<NutrientCollapsibleSection> createState() =>
      _NutrientCollapsibleSectionState();
}

class _NutrientCollapsibleSectionState
    extends State<NutrientCollapsibleSection> {
  late bool _open;

  @override
  void initState() {
    super.initState();
    _open = widget.initiallyOpen;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${widget.title} (${widget.count}개)',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                  Icon(_open ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.items
                    .map((line) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(line, style: AppTypography.body2),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

/// Helpers to build secondary/sufficient line strings in a uniform way.
String formatSecondaryLine(NutrientStatus s) {
  final source = s.deficit.sourceProductNames.isEmpty
      ? '안 드심'
      : s.deficit.sourceProductNames.join(', ');
  return ' · ${s.deficit.displayName}  ${s.deficit.percentage}% ($source)';
}

String formatSufficientLine(NutrientDeficit d) {
  final source =
      d.sourceProductNames.isEmpty ? '식이' : d.sourceProductNames.join(', ');
  return ' · ${d.displayName}  ${d.percentage}% ($source)';
}
