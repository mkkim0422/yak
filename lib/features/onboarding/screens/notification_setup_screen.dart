import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/notification_provider.dart';
import '../../../core/security/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alyak_buttons.dart';
import '../../../core/widgets/alyak_card.dart';
import '../../family/providers/family_provider.dart';

const String kNotifMorningKey = 'notif.morning.time';
const String kNotifEveningKey = 'notif.evening.time';
const String kNotifEnabledKey = 'notif.enabled';
const String kReorderEnabledKey = 'notif.reorder.enabled';
const String kReorderDaysKey = 'notif.reorder.days';

String _formatTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

TimeOfDay _parseTime(String? raw, TimeOfDay fallback) {
  if (raw == null || !raw.contains(':')) return fallback;
  final parts = raw.split(':');
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return fallback;
  return TimeOfDay(hour: h, minute: m);
}

class NotificationSetupScreen extends ConsumerStatefulWidget {
  const NotificationSetupScreen({super.key});

  @override
  ConsumerState<NotificationSetupScreen> createState() =>
      _NotificationSetupScreenState();
}

class _NotificationSetupScreenState
    extends ConsumerState<NotificationSetupScreen> {
  TimeOfDay _morning = const TimeOfDay(hour: 7, minute: 30);
  TimeOfDay _evening = const TimeOfDay(hour: 20, minute: 0);
  bool _reorderEnabled = true;
  bool _doseEnabled = false;
  bool _saving = false;

  Future<void> _pickTime(bool morning) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: morning ? _morning : _evening,
    );
    if (picked == null) return;
    setState(() {
      if (morning) {
        _morning = picked;
      } else {
        _evening = picked;
      }
    });
  }

  Future<void> _save({required bool enabled}) async {
    if (_saving) return;
    setState(() => _saving = true);
    await SecureStorage.write(kNotifMorningKey, _formatTime(_morning));
    await SecureStorage.write(kNotifEveningKey, _formatTime(_evening));
    await SecureStorage.write(kNotifEnabledKey, enabled ? '1' : '0');
    if (enabled) {
      final svc = ref.read(notificationServiceProvider);
      await svc.requestPermission();
      if (_doseEnabled) {
        final familyCount = ref.read(familyMembersProvider).length;
        await svc.rescheduleDaily(
          morning: _morning,
          evening: _evening,
          familyCount: familyCount,
        );
      }
    }
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => _save(enabled: false),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Text(
                      '알림은 가볍게,\n꼭 필요한 것만 알려드려요',
                      style: AppTypography.heading1.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '매일 챙기라고 재촉하지 않아요.\n결정이 필요한 순간에만 살짝 알려드려요.',
                      style: AppTypography.body1.copyWith(
                        fontSize: 13.5,
                        color: AppColors.muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _NotifToggle(
                      emoji: '📦',
                      title: '영양제가 곧 떨어질 때',
                      sub: '3일 전쯤 한 번 알려드려요',
                      value: _reorderEnabled,
                      onChanged: (v) =>
                          setState(() => _reorderEnabled = v),
                    ),
                    const SizedBox(height: 10),
                    _NotifToggle(
                      emoji: '💊',
                      title: '복용 시간 알림',
                      sub: '편하실 때 챙기세요',
                      value: _doseEnabled,
                      onChanged: (v) => setState(() => _doseEnabled = v),
                    ),
                    if (_doseEnabled) ...[
                      const SizedBox(height: 14),
                      _TimeCard(
                        emoji: '🌅',
                        title: '아침',
                        subtitle: '아침 영양제 시간',
                        time: _morning,
                        onTap: () => _pickTime(true),
                      ),
                      const SizedBox(height: 8),
                      _TimeCard(
                        emoji: '🌙',
                        title: '저녁',
                        subtitle: '저녁 영양제 시간',
                        time: _evening,
                        onTap: () => _pickTime(false),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: '알림 받을게요',
                full: true,
                onPressed: _saving ? null : () => _save(enabled: true),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: _saving ? null : () => _save(enabled: false),
                  child: Text(
                    '나중에 설정할게요',
                    style: AppTypography.title.copyWith(
                      fontSize: 14,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotifToggle extends StatelessWidget {
  final String emoji;
  final String title;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _NotifToggle({
    required this.emoji,
    required this.title,
    required this.sub,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AlyakCard(
      padding: const EdgeInsets.all(14),
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.r10),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.title.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(sub, style: AppTypography.caption.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.hairline,
          ),
        ],
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AlyakCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.title.copyWith(fontSize: 14),
                ),
                Text(subtitle,
                    style: AppTypography.caption.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.r8),
            ),
            child: Text(
              _formatTime(time),
              style: AppTypography.title.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Convenience for tests: read back what was stored.
Future<Map<String, String?>> readStoredNotificationSettings() async {
  return {
    kNotifMorningKey: await SecureStorage.read(kNotifMorningKey),
    kNotifEveningKey: await SecureStorage.read(kNotifEveningKey),
    kNotifEnabledKey: await SecureStorage.read(kNotifEnabledKey),
  };
}

/// Test helper exposed for parsing assertions.
TimeOfDay parseStoredTime(String? raw, TimeOfDay fallback) =>
    _parseTime(raw, fallback);

String formatTimeOfDay(TimeOfDay t) => _formatTime(t);
