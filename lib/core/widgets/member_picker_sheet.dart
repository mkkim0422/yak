import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/alyak_buttons.dart';
import '../widgets/alyak_card.dart';
import '../widgets/profile_avatar.dart';
import '../../features/family/models/family_member.dart';
import '../../features/family/providers/family_provider.dart';

/// Resolves a target memberId for an entry that requires picking a family
/// member first. Behavior:
///   * 0 members → opens an empty-state sheet that lets the user jump to
///     /onboarding/family-add. Returns null.
///   * 1 member → returns that member's id immediately (no UI).
///   * 2+ members → opens a modal sheet with avatars and returns the selected
///     id (or null if dismissed).
///
/// Pass [purpose] to drive the sheet copy ("누구의 영양제를 추천받을까요?",
/// "누구의 복용을 점검할까요?" etc.).
Future<String?> pickMemberId(
  BuildContext context,
  WidgetRef ref, {
  required String purpose,
}) async {
  final family = ref.read(familyProvider);
  final members = family.members;

  if (members.isEmpty) {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) => _EmptyFamilySheet(),
    );
    return null;
  }

  if (members.length == 1) {
    return members.first.id;
  }

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetCtx) => _MemberPicker(purpose: purpose),
  );
}

class _EmptyFamilySheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👨‍👩‍👧', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              '먼저 가족을 추가해주세요',
              style: AppTypography.heading2.copyWith(fontSize: 17),
            ),
            const SizedBox(height: 4),
            Text(
              '추천이나 점검은 가족 정보가 필요해요',
              style: AppTypography.caption.copyWith(fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: '+ 가족 추가하기',
              full: true,
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/onboarding/family-add');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberPicker extends ConsumerWidget {
  final String purpose;
  const _MemberPicker({required this.purpose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(familyProvider).members;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(purpose,
                style: AppTypography.heading2.copyWith(fontSize: 18)),
            const SizedBox(height: 16),
            for (final m in members)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AlyakCard(
                  padding: const EdgeInsets.all(14),
                  onTap: () => Navigator.of(context).pop(m.id),
                  child: Row(
                    children: [
                      ProfileAvatar(member: m, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              m.name,
                              style: AppTypography.title
                                  .copyWith(fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${m.ageLabel} ${m.sex.label} · ${m.relationship.label}',
                              style:
                                  AppTypography.caption.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.faint,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 4),
            SecondaryButton(
              label: '취소',
              full: true,
              size: AlyakButtonSize.md,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

