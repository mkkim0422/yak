import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/member_analysis_provider.dart';

/// Top deficits — flat grey bullet list. Tone is informational, never
/// alarming. Detailed % / reasons are intentionally dropped from this card;
/// they live on the recommendation screen the "💊 영양제 사러 가기" CTA opens.
class NutrientPriorityCard extends StatelessWidget {
  final List<NutrientStatus> items;
  const NutrientPriorityCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          '부족한 영양소가 없어요',
          style: AppTypography.body2.copyWith(color: AppColors.muted),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '• ${items[i].deficit.displayName}',
                style: AppTypography.body2.copyWith(
                  fontSize: 14,
                  color: AppColors.ink2,
                ),
              ),
            ),
          ],
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
