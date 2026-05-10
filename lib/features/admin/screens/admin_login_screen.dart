import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/admin_auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';

/// Admin 비밀번호 입력 화면. 인증 성공 시 [onAuthenticated] 콜백을 통해
/// 호출자(Settings의 7번 탭 진입 또는 라우트 컨테이너)가 다음 화면으로 전환.
///
/// 비밀번호는 빌드 환경변수에 SHA-256 해시로 박혀 있으며 본 화면은 입력값을
/// 해시해 비교만 함. 5회 연속 실패 시 1분 잠금.
class AdminLoginScreen extends ConsumerStatefulWidget {
  final VoidCallback onAuthenticated;
  const AdminLoginScreen({super.key, required this.onAuthenticated});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _ctrl = TextEditingController();
  final _service = AdminAuthService();
  String? _error;
  Duration? _lockRemaining;
  Timer? _tickTimer;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refreshLockState();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _refreshLockState() async {
    final remaining = await _service.remainingLockout();
    if (!mounted) return;
    setState(() => _lockRemaining = remaining);
    if (remaining != null) {
      _tickTimer?.cancel();
      _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
        final r = await _service.remainingLockout();
        if (!mounted) return;
        setState(() => _lockRemaining = r);
        if (r == null) _tickTimer?.cancel();
      });
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await _service.verify(_ctrl.text);
    if (!mounted) return;
    switch (result) {
      case VerifyResult.success:
        _ctrl.clear();
        widget.onAuthenticated();
      case VerifyResult.failed:
        setState(() {
          _error = '비밀번호가 맞지 않아요';
          _busy = false;
        });
      case VerifyResult.locked:
        await _refreshLockState();
        if (!mounted) return;
        setState(() {
          _error = '5회 실패해 1분간 입력이 잠겼어요';
          _busy = false;
        });
      case VerifyResult.disabled:
        setState(() {
          _error = '관리자 모드가 비활성화되어 있어요';
          _busy = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = _lockRemaining != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('관리자'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '🔒 관리자 비밀번호',
                style: AppTypography.heading2.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                '운영자 전용 화면입니다. 비밀번호를 입력해 주세요.',
                style: AppTypography.body2.copyWith(
                  fontSize: 13,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _ctrl,
                obscureText: true,
                enabled: !locked && !_busy,
                autofocus: true,
                inputFormatters: [LengthLimitingTextInputFormatter(64)],
                onSubmitted: (_) => locked ? null : _submit(),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: '비밀번호',
                  errorText: _error,
                ),
              ),
              if (locked) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warnBg,
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                  child: Text(
                    '🔒 잠금 중 — ${_lockRemaining!.inSeconds}초 후 다시 시도하세요',
                    style: AppTypography.body2.copyWith(
                      fontSize: 13,
                      color: AppColors.warnInk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: locked || _busy ? null : _submit,
                child: const Text('입장'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
