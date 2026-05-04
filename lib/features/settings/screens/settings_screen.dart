import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/notification_provider.dart';
import '../../../core/security/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../onboarding/screens/notification_setup_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _dailyEnabled = true;
  bool _reorderEnabled = true;
  bool _checkupEnabled = true;
  TimeOfDay _morning = const TimeOfDay(hour: 7, minute: 30);
  TimeOfDay _evening = const TimeOfDay(hour: 20, minute: 0);
  int _reorderLeadDays = 3;
  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) return;
    _loaded = true;
    final morningRaw = await SecureStorage.read(kNotifMorningKey);
    final eveningRaw = await SecureStorage.read(kNotifEveningKey);
    final enabledRaw = await SecureStorage.read(kNotifEnabledKey);
    final reorderRaw = await SecureStorage.read(kReorderEnabledKey);
    final checkupRaw = await SecureStorage.read(kCheckupEnabledKey);
    final reorderDaysRaw = await SecureStorage.read(kReorderDaysKey);
    if (!mounted) return;
    setState(() {
      _morning = parseStoredTime(morningRaw, _morning);
      _evening = parseStoredTime(eveningRaw, _evening);
      _dailyEnabled = enabledRaw != '0';
      _reorderEnabled = reorderRaw != '0';
      _checkupEnabled = checkupRaw != '0';
      _reorderLeadDays = int.tryParse(reorderDaysRaw ?? '') ?? 3;
    });
  }

  Future<void> _persistDaily() async {
    await SecureStorage.write(kNotifMorningKey, formatTimeOfDay(_morning));
    await SecureStorage.write(kNotifEveningKey, formatTimeOfDay(_evening));
    await SecureStorage.write(kNotifEnabledKey, _dailyEnabled ? '1' : '0');
    final svc = ref.read(notificationServiceProvider);
    if (_dailyEnabled) {
      await svc.rescheduleDaily(morning: _morning, evening: _evening);
    } else {
      await svc.rescheduleDaily();
    }
  }

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
    await _persistDaily();
  }

  Future<void> _confirmWipe() async {
    final continueWipe = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('정말로 삭제하시겠어요?'),
        content: const Text(
          '모든 가족 정보, 영양제, 검진 기록이 삭제됩니다.\n되돌릴 수 없어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dctx).pop(true),
            child: const Text('계속'),
          ),
        ],
      ),
    );
    if (continueWipe != true) return;
    if (!mounted) return;
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('확인을 위해 "삭제"를 입력해주세요'),
            const SizedBox(height: 8),
            TextField(
              key: const Key('wipe-confirm-input'),
              controller: controller,
              decoration: const InputDecoration(
                hintText: '삭제',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dctx).pop(controller.text == '삭제'),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(notificationServiceProvider).cancelAll();
    await SecureStorage.wipe();
    if (!mounted) return;
    context.go('/privacy-consent');
  }

  @override
  Widget build(BuildContext context) {
    _load();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _sectionTitle('알림'),
          SwitchListTile(
            title: const Text('매일 알림'),
            value: _dailyEnabled,
            onChanged: (v) async {
              setState(() => _dailyEnabled = v);
              await _persistDaily();
            },
          ),
          if (_dailyEnabled) ...[
            ListTile(
              title: const Text('아침 시간'),
              trailing: Text(formatTimeOfDay(_morning),
                  style: AppTypography.body1),
              onTap: () => _pickTime(true),
            ),
            ListTile(
              title: const Text('저녁 시간'),
              trailing: Text(formatTimeOfDay(_evening),
                  style: AppTypography.body1),
              onTap: () => _pickTime(false),
            ),
          ],
          SwitchListTile(
            title: const Text('재구매 알림'),
            value: _reorderEnabled,
            onChanged: (v) async {
              setState(() => _reorderEnabled = v);
              await SecureStorage.write(
                  kReorderEnabledKey, v ? '1' : '0');
            },
          ),
          if (_reorderEnabled)
            ListTile(
              title: const Text('며칠 전 알림'),
              trailing: Text('$_reorderLeadDays일',
                  style: AppTypography.body1),
              onTap: () async {
                final picked = await _pickInt(
                  context: context,
                  title: '며칠 전 알림',
                  options: const [1, 2, 3, 5, 7],
                  initial: _reorderLeadDays,
                );
                if (picked == null) return;
                setState(() => _reorderLeadDays = picked);
                await SecureStorage.write(
                    kReorderDaysKey, picked.toString());
              },
            ),
          SwitchListTile(
            title: const Text('연 1회 건강검진 알림'),
            subtitle: const Text('가족별 1년에 한 번 알림'),
            value: _checkupEnabled,
            onChanged: (v) async {
              setState(() => _checkupEnabled = v);
              await SecureStorage.write(
                  kCheckupEnabledKey, v ? '1' : '0');
            },
          ),
          const Divider(height: 24),
          _sectionTitle('가족'),
          ListTile(
            title: const Text('가족 관리'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/family-management'),
          ),
          ListTile(
            title: const Text('가족 추가'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/onboarding/family-add'),
          ),
          const Divider(height: 24),
          _sectionTitle('정보'),
          ListTile(
            title: const Text('개인정보 처리방침'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/privacy-policy'),
          ),
          ListTile(
            title: const Text('면책 조항'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/disclaimer'),
          ),
          const ListTile(
            title: Text('버전'),
            trailing: Text('1.0.0'),
          ),
          const Divider(height: 24),
          _sectionTitle('데이터'),
          ListTile(
            key: const Key('wipe-button'),
            title: const Text('⚠️ 모든 데이터 삭제',
                style: TextStyle(color: AppColors.error)),
            onTap: _confirmWipe,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

Widget _sectionTitle(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary)),
    );

Future<int?> _pickInt({
  required BuildContext context,
  required String title,
  required List<int> options,
  required int initial,
}) {
  return showDialog<int>(
    context: context,
    builder: (dctx) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final o in options)
              ListTile(
                title: Text('$o일'),
                trailing: o == initial
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(dctx).pop(o),
              ),
          ],
        ),
      ),
    ),
  );
}
