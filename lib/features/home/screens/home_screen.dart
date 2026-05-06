import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alyak_card.dart';
import '../../../core/widgets/disclaimer_footer.dart';
import '../../../core/widgets/entry_row.dart';
import '../../../core/widgets/member_picker_sheet.dart';
import '../../../core/widgets/section_header.dart';
import '../../family/providers/family_provider.dart';
import '../widgets/family_cards_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasFamily = ref.watch(familyProvider).members.isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _HomeHeader(),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: FamilyCardsSection(),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _EntryList(),
            ),
            if (hasFamily) ...[
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _NotificationsSection(),
              ),
            ],
            const SizedBox(height: 12),
            const DisclaimerFooter(),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '안녕하세요 👋',
                  style: AppTypography.caption.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '우리 가족 영양제',
                  style: AppTypography.heading1.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          _SettingsBell(
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }
}

class _SettingsBell extends StatelessWidget {
  final VoidCallback onTap;
  const _SettingsBell({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.r12),
            boxShadow: AppShadows.card,
          ),
          child: const Icon(Icons.settings_outlined,
              color: AppColors.ink, size: 20),
        ),
      ),
    );
  }
}

class _EntryList extends ConsumerWidget {
  const _EntryList();

  Future<void> _pickAndGo(
    BuildContext context,
    WidgetRef ref, {
    required String purpose,
    required String Function(String memberId) destination,
  }) async {
    final pickedId = await pickMemberId(context, ref, purpose: purpose);
    if (pickedId == null || !context.mounted) return;
    context.push(destination(pickedId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '🎯 무엇을 도와드릴까요?'),
        EntryRow(
          icon: '💊',
          title: '영양제 새로 사고 싶어요',
          sub: '부족한 영양소와 추천 제품을 알려드려요',
          accent: AppColors.primarySoft,
          onTap: () => _pickAndGo(
            context,
            ref,
            purpose: '누구의 영양제를 추천받을까요?',
            destination: (id) => '/recommendation/$id',
          ),
        ),
        const SizedBox(height: 8),
        EntryRow(
          icon: '⚠️',
          title: '지금 먹는 것 점검하기',
          sub: '충돌과 과다 섭취를 체크해드려요',
          accent: AppColors.warnBg,
          onTap: () => _pickAndGo(
            context,
            ref,
            purpose: '누구의 복용을 점검할까요?',
            destination: (id) => '/current-check/$id',
          ),
        ),
        const SizedBox(height: 8),
        EntryRow(
          icon: '🤒',
          title: '증상에 맞는 영양제',
          sub: '어떤 증상이 있으세요?',
          accent: const Color(0xFFFFE8E8),
          onTap: () => context.push('/symptom-search'),
        ),
        const SizedBox(height: 8),
        EntryRow(
          icon: '👨‍👩‍👧',
          title: '가족 관리',
          sub: '가족 추가, 정보 수정',
          accent: AppColors.surfaceMuted,
          onTap: () => context.push('/family-management'),
        ),
      ],
    );
  }
}

class _NotificationsSection extends ConsumerWidget {
  const _NotificationsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Notifications source not wired up yet — show static UI sample only when
    // there is at least one member, matching the design.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '🔔 알림'),
        AlyakCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotifIcon(emoji: '📦', bg: AppColors.warnBg),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '복용 중인 영양제를 확인해 주세요',
                      style: AppTypography.title.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '곧 다 드시거나 떨어진 영양제가 없는지 점검해 주세요',
                      style: AppTypography.caption.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotifIcon extends StatelessWidget {
  final String emoji;
  final Color bg;
  const _NotifIcon({required this.emoji, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.r10),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 16)),
    );
  }
}
