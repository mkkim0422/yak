import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/family_cards_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
            tooltip: AppStrings.settingsTitle,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Greeting(),
          SizedBox(height: 16),
          FamilyCardsSection(),
          SizedBox(height: 24),
          _HelpSection(),
          SizedBox(height: 24),
          _NotificationsSection(),
          SizedBox(height: 16),
          _Disclaimer(),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.homeGreeting, style: AppTypography.body1),
        const SizedBox(height: 4),
        Text(AppStrings.homeFamilyTitle, style: AppTypography.heading1),
      ],
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection();

  @override
  Widget build(BuildContext context) {
    final entries = <_HelpEntry>[
      _HelpEntry(
        AppStrings.entryBuySupplements,
        () => context.push('/recommendation/select'),
      ),
      _HelpEntry(
        AppStrings.entryCurrentCheck,
        () => context.push('/current-check/select'),
      ),
      _HelpEntry(
        AppStrings.entrySymptomSearch,
        () => context.push('/symptom-search'),
      ),
      _HelpEntry(
        AppStrings.entryFamilyManage,
        () => context.push('/family-management'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.homeHelpTitle, style: AppTypography.heading3),
        const SizedBox(height: 12),
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: e.onTap,
                child: Row(
                  children: [
                    Expanded(child: Text(e.label, style: AppTypography.body1)),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HelpEntry {
  final String label;
  final VoidCallback onTap;
  _HelpEntry(this.label, this.onTap);
}

class _NotificationsSection extends ConsumerWidget {
  const _NotificationsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Notifications source not wired up yet — render only when populated.
    final notifications = const <String>[];
    if (notifications.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.homeNotificationsTitle, style: AppTypography.heading3),
        const SizedBox(height: 8),
        for (final note in notifications)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('· $note', style: AppTypography.body1),
          ),
      ],
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppStrings.disclaimerText,
      style: AppTypography.caption,
      textAlign: TextAlign.center,
    );
  }
}
