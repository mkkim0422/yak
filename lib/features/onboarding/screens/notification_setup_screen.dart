import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/notification_provider.dart';
import '../../../core/security/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

const String kNotifMorningKey = 'notif.morning.time';
const String kNotifEveningKey = 'notif.evening.time';
const String kNotifEnabledKey = 'notif.enabled';
const String kReorderEnabledKey = 'notif.reorder.enabled';
const String kReorderDaysKey = 'notif.reorder.days';
const String kCheckupEnabledKey = 'notif.checkup.enabled';

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
      await svc.rescheduleDaily(morning: _morning, evening: _evening);
    }
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _save(enabled: false),
        ),
        title: const Text('알림 설정'),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _save(enabled: false),
            child: const Text('건너뛰기'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('📱 알림 설정',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('영양제 챙기실 시간을 알려드릴게요\n나중에 설정에서 바꿀 수 있어요',
              style: AppTypography.body2),
          const SizedBox(height: 20),
          _TimeCard(
            emoji: '🌅',
            title: '아침',
            subtitle: '출발 시간 (예: 출근, 등교)',
            footer: '30분 전에 알려드려요',
            time: _morning,
            onTap: () => _pickTime(true),
          ),
          const SizedBox(height: 12),
          _TimeCard(
            emoji: '🌙',
            title: '저녁',
            subtitle: '저녁 영양제 시간',
            footer: '',
            time: _evening,
            onTap: () => _pickTime(false),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : () => _save(enabled: true),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('알림 켜기 + 시작하기',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _saving ? null : () => _save(enabled: false),
              child: const Text('건너뛰기 (나중에 설정)'),
            ),
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
  final String footer;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.footer,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: AppTypography.caption),
                  if (footer.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(footer, style: AppTypography.caption),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatTime(time),
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          ],
        ),
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
