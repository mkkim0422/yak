import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/coverage_bar.dart';
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
        child: Text(
          '부족한 영양소가 없어요',
          style: AppTypography.body2,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '🔴 우선 보충 필요',
          style: AppTypography.sectionTitle.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _RecCard(status: items[i]),
        ],
      ],
    );
  }
}

class _RecCard extends StatelessWidget {
  final NutrientStatus status;
  const _RecCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final pct = status.deficit.percentage.clamp(0, 100);
    final hs = pct < 50 ? HealthStatus.alert : HealthStatus.warn;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  status.deficit.displayName,
                  style: AppTypography.title.copyWith(fontSize: 15),
                ),
              ),
              Text(
                '$pct%',
                style: AppTypography.title.copyWith(
                  fontSize: 13,
                  color: hs.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CoverageBar(percent: pct.toDouble(), status: hs),
          const SizedBox(height: 10),
          Text(
            '· 현재 ${status.deficit.current.toStringAsFixed(0)} / '
            '권장 ${status.deficit.recommended.toStringAsFixed(0)}',
            style: AppTypography.caption.copyWith(
              fontSize: 12.5,
              color: AppColors.ink2,
            ),
          ),
          for (final r in status.reasons.take(2))
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '· $r',
                style: AppTypography.caption.copyWith(
                  fontSize: 12.5,
                  color: AppColors.muted,
                ),
              ),
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
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => setState(() => _open = !_open),
              borderRadius: BorderRadius.circular(AppRadius.r16),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: AppTypography.title.copyWith(fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.count}개 영양소',
                            style: AppTypography.micro.copyWith(fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _open ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.muted,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (_open)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
