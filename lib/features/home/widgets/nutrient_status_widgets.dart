import 'package:flutter/material.dart';

import '../../../core/data/nutrient_evaluation.dart' show softGradeLabel;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/member_analysis_provider.dart';

/// Top deficits — comma-joined single line. Tone is informational, never
/// alarming. Detailed % / reasons live on the recommendation screen the
/// "💊 영양제 사러 가기" CTA opens.
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

    final names = [for (final s in items) s.deficit.displayName];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        boxShadow: AppShadows.card,
      ),
      child: Text(
        formatNutrientList(names),
        style: AppTypography.body2.copyWith(
          fontSize: 14,
          height: 1.45,
          color: AppColors.ink2,
        ),
      ),
    );
  }
}

/// Joins a list of nutrient names into a single comma-separated string.
/// Lists longer than 5 are truncated to "A, B, C 외 N개" so the line fits
/// the calm, single-row treatment on the member screen.
String formatNutrientList(List<String> names) {
  if (names.isEmpty) return '';
  if (names.length <= 5) return names.join(', ');
  return '${names.take(3).join(', ')} 외 ${names.length - 3}개';
}

/// 영양소 한 줄. 기본은 이름 + 등급 라벨만 노출하고, 탭하면 펼쳐서
/// 출처 제품명을 보여줍니다. 시각 노이즈를 줄이면서도 출처 정보는
/// 잃지 않는 패턴.
///
/// PART 9 컨벤션 — 사용자 노출 텍스트에 % / 영문 괄호 금지. 등급은
/// [softGradeLabel]에서 한국어 4단계로 받아옵니다.
class NutrientStatusLine extends StatefulWidget {
  final NutrientDeficit deficit;

  /// `null`이면 출처 비어 있을 때 자동 메시지("아직 섭취 중이 아니에요"
  /// 또는 "식이로 섭취 중") 사용. 외부에서 강제 텍스트 주입 가능.
  final String? sourceFallback;

  const NutrientStatusLine({
    super.key,
    required this.deficit,
    this.sourceFallback,
  });

  @override
  State<NutrientStatusLine> createState() => _NutrientStatusLineState();
}

class _NutrientStatusLineState extends State<NutrientStatusLine> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.deficit;
    final grade = softGradeLabel(d.percentage);
    final sources = d.sourceProductNames;
    final sourceText = sources.isEmpty
        ? (widget.sourceFallback ?? '아직 섭취 중이 아니에요')
        : '${sources.join(' · ')}에서 섭취 중';

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r10),
      onTap: () => setState(() => _open = !_open),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    d.displayName,
                    style: AppTypography.body1.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  grade,
                  style: AppTypography.body2.copyWith(
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _open ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: AppColors.faint,
                ),
              ],
            ),
            if (_open) ...[
              const SizedBox(height: 4),
              Text(
                sourceText,
                style: AppTypography.caption.copyWith(
                  fontSize: 12,
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tier 2 / 3: collapsible bullet list backed by [NutrientDeficit]s.
/// 각 행은 [NutrientStatusLine]으로 렌더되어 탭 expand로 출처를 보여줍니다.
class NutrientCollapsibleSection extends StatefulWidget {
  final String title;
  final List<NutrientDeficit> deficits;
  final bool initiallyOpen;

  /// 각 행의 출처 비어 있을 때 보여줄 폴백 ("식이로 섭취 중" 등).
  /// `null`이면 [NutrientStatusLine] 기본값 사용.
  final String? sourceFallback;

  const NutrientCollapsibleSection({
    super.key,
    required this.title,
    required this.deficits,
    this.initiallyOpen = false,
    this.sourceFallback,
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
                            '${widget.deficits.length}개 영양소',
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
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final d in widget.deficits)
                      NutrientStatusLine(
                        deficit: d,
                        sourceFallback: widget.sourceFallback,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
