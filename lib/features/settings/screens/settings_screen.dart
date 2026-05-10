import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/services.dart';

import '../../../core/notifications/notification_provider.dart';
import '../../../core/security/admin_auth_service.dart';
import '../../../core/security/secure_storage.dart';
import '../../../core/services/data_export_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/disclaimer_footer.dart';
import '../../family/providers/family_provider.dart';
import '../../onboarding/screens/notification_setup_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _dailyEnabled = true;
  bool _reorderEnabled = true;
  TimeOfDay _morning = const TimeOfDay(hour: 7, minute: 30);
  TimeOfDay _evening = const TimeOfDay(hour: 20, minute: 0);
  int _reorderLeadDays = 3;
  bool _loaded = false;

  /// "앱 정보" 항목 이스터에그 — 7번 연속 탭 시 /admin 라우트 진입.
  /// 빌드에 ADMIN_PASSWORD_HASH 가 주입되지 않은 빌드(소비자용)는 비활성
  /// 토스트 후 무시.
  int _appInfoTaps = 0;
  DateTime? _lastAppInfoTap;

  Future<void> _load() async {
    if (_loaded) return;
    _loaded = true;
    final morningRaw = await SecureStorage.read(kNotifMorningKey);
    final eveningRaw = await SecureStorage.read(kNotifEveningKey);
    final enabledRaw = await SecureStorage.read(kNotifEnabledKey);
    final reorderRaw = await SecureStorage.read(kReorderEnabledKey);
    final reorderDaysRaw = await SecureStorage.read(kReorderDaysKey);
    if (!mounted) return;
    setState(() {
      _morning = parseStoredTime(morningRaw, _morning);
      _evening = parseStoredTime(eveningRaw, _evening);
      _dailyEnabled = enabledRaw != '0';
      _reorderEnabled = reorderRaw != '0';
      _reorderLeadDays = int.tryParse(reorderDaysRaw ?? '') ?? 3;
    });
  }

  Future<void> _persistDaily() async {
    await SecureStorage.write(kNotifMorningKey, formatTimeOfDay(_morning));
    await SecureStorage.write(kNotifEveningKey, formatTimeOfDay(_evening));
    await SecureStorage.write(kNotifEnabledKey, _dailyEnabled ? '1' : '0');
    final svc = ref.read(notificationServiceProvider);
    final familyCount = ref.read(familyMembersProvider).length;
    if (_dailyEnabled) {
      await svc.rescheduleDaily(
        morning: _morning,
        evening: _evening,
        familyCount: familyCount,
      );
    } else {
      await svc.rescheduleDaily();
    }
  }

  /// Toggle the daily-reminder switch with permission gating.
  /// User flips ON → request OS permission → if denied, flip OFF and toast.
  Future<void> _toggleDaily(bool v) async {
    if (v) {
      final granted =
          await ref.read(notificationServiceProvider).requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('알림 권한이 거부되었어요. 설정에서 켜주세요'),
              backgroundColor: AppColors.warnInk,
            ),
          );
        }
        if (mounted) setState(() => _dailyEnabled = false);
        await SecureStorage.write(kNotifEnabledKey, '0');
        return;
      }
    }
    setState(() => _dailyEnabled = v);
    await _persistDaily();
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

  Future<void> _exportData() async {
    final members = ref.read(familyMembersProvider);
    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내보낼 가족 정보가 없어요')),
      );
      return;
    }
    try {
      final path = await DataExportService.writeToExternalStorage(members);
      // 사용자가 파일 경로를 수동 복사할 수 있도록 클립보드에도 같이 적재.
      // share_plus 패키지 추가 시 share sheet으로 교체 예정 (V1.1).
      await Clipboard.setData(ClipboardData(text: path));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('백업 파일 저장됨\n경로: $path\n(클립보드 복사됨)'),
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('내보내기에 실패했어요: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// 7번 연속 탭(2초 이내) → /admin. 비활성 빌드는 묵묵히 무시.
  void _onAppInfoTap() {
    final now = DateTime.now();
    if (_lastAppInfoTap != null &&
        now.difference(_lastAppInfoTap!) > const Duration(seconds: 2)) {
      _appInfoTaps = 0;
    }
    _lastAppInfoTap = now;
    _appInfoTaps++;
    if (_appInfoTaps < 7) return;
    _appInfoTaps = 0;
    if (!AdminAuthService().isEnabled) return;
    context.push('/admin');
  }

  Future<void> _confirmWipe() async {
    final continueWipe = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r20),
        ),
        title: const Text('정말로 삭제하시겠어요?'),
        content: const Text(
          '모든 가족 정보와 영양제 기록이 삭제됩니다.\n되돌릴 수 없어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.alertInk),
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r20),
        ),
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.alertInk),
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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: const Text('설정'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        children: [
          _SectionLabel('알림'),
          _SectionGroup(
            children: [
              _SettingItem(
                emoji: '🔔',
                title: '매일 영양제 알림',
                trailing: Switch(
                  value: _dailyEnabled,
                  onChanged: _toggleDaily,
                ),
              ),
              if (_dailyEnabled) ...[
                _SettingItem(
                  emoji: '🌅',
                  title: '아침 시간',
                  trailing: _TimePill(
                    time: formatTimeOfDay(_morning),
                    onTap: () => _pickTime(true),
                  ),
                ),
                _SettingItem(
                  emoji: '🌙',
                  title: '저녁 시간',
                  trailing: _TimePill(
                    time: formatTimeOfDay(_evening),
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
              _SettingItem(
                emoji: '📦',
                title: '영양제 떨어짐 알림',
                trailing: Switch(
                  value: _reorderEnabled,
                  onChanged: (v) async {
                    setState(() => _reorderEnabled = v);
                    await SecureStorage.write(
                        kReorderEnabledKey, v ? '1' : '0');
                  },
                ),
              ),
              if (_reorderEnabled)
                _SettingItem(
                  emoji: '📅',
                  title: '며칠 전 알림',
                  trailing: _TimePill(
                    time: '$_reorderLeadDays일',
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
                ),
            ],
          ),
          _SectionLabel('가족'),
          _SectionGroup(
            children: [
              _SettingItem(
                emoji: '👨‍👩‍👧',
                title: '가족 관리',
                onTap: () => context.push('/family-management'),
              ),
              _SettingItem(
                emoji: '➕',
                title: '가족 추가',
                onTap: () => context.push('/onboarding/family-add'),
              ),
              _SettingItem(
                emoji: '📥',
                title: '내 데이터 내보내기',
                sub: 'JSON 파일로 백업',
                onTap: _exportData,
              ),
            ],
          ),
          _SectionLabel('정보'),
          _SectionGroup(
            children: [
              _SettingItem(
                emoji: '👋',
                title: '온보딩 다시 보기',
                sub: '앱 소개 4슬라이드',
                onTap: () => context.push('/onboarding?from=settings'),
              ),
              _SettingItem(
                emoji: '🔒',
                title: '개인정보 처리방침',
                onTap: () => context.push('/privacy-policy'),
              ),
              _SettingItem(
                emoji: '📋',
                title: '이용약관',
                onTap: () => context.push('/terms'),
              ),
              _SettingItem(
                emoji: '⚠️',
                title: '면책 조항',
                onTap: () => context.push('/disclaimer'),
              ),
              _SettingItem(
                emoji: 'ℹ️',
                title: '앱 정보',
                sub: '버전 1.0.0',
                onTap: _onAppInfoTap,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton(
              key: const Key('wipe-button'),
              onPressed: _confirmWipe,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.alertInk,
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '⚠️ 모든 데이터 삭제',
                style: AppTypography.title.copyWith(
                  fontSize: 13.5,
                  color: AppColors.alertInk,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const DisclaimerFooter(),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionGroup extends StatelessWidget {
  final List<Widget> children;
  const _SectionGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        boxShadow: AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.r16),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.divider),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String? sub;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingItem({
    required this.emoji,
    required this.title,
    this.sub,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.r8),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.title.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub!,
                    style: AppTypography.caption.copyWith(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          trailing ??
              const Icon(Icons.chevron_right, color: AppColors.faint, size: 18),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

class _TimePill extends StatelessWidget {
  final String time;
  final VoidCallback onTap;
  const _TimePill({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.r8),
        ),
        child: Text(
          time,
          style: AppTypography.title.copyWith(
            fontSize: 13,
            color: AppColors.primaryInk,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

Future<int?> _pickInt({
  required BuildContext context,
  required String title,
  required List<int> options,
  required int initial,
}) {
  return showDialog<int>(
    context: context,
    builder: (dctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.r20),
      ),
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
