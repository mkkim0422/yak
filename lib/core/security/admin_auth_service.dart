import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'secure_storage.dart';

/// Admin 모드 인증.
///
/// 비밀번호 해시는 빌드 시 `--dart-define=ADMIN_PASSWORD_HASH=<sha256>`로
/// 주입. 환경변수가 없는 빌드(`defaultValue: ''`)는 Admin 비활성 — 코드/APK
/// 유출 시 해시조차 노출되지 않도록 빌드 산출물 자체에 안 들어감.
///
/// 잠금: 5회 연속 실패 → 1분간 입력 거부. 카운터/만료시각은 SecureStorage
/// 에 영속(앱 재시작·우회 시도에도 유지). 성공 시 둘 다 클리어.
class AdminAuthService {
  AdminAuthService({
    AdminAuthStorage? storage,
    DateTime Function()? clock,
  })  : _storage = storage ?? const _SecureStorageBackend(),
        _clock = clock ?? DateTime.now;

  final AdminAuthStorage _storage;
  final DateTime Function() _clock;

  /// 빌드 시 주입된 SHA-256 해시 — 비어있으면 Admin 비활성.
  static const String _kAdminPasswordHash = String.fromEnvironment(
    'ADMIN_PASSWORD_HASH',
    defaultValue: '',
  );

  /// 잠금 발동 임계치 (연속 실패 횟수).
  static const int kMaxAttempts = 5;

  /// 잠금 지속 시간.
  static const Duration kLockDuration = Duration(minutes: 1);

  /// 빌드에 비밀번호 해시가 주입되어 있는지. false면 진입 시 토스트 후
  /// 차단(Settings 7번 탭에서 곧장 분기).
  bool get isEnabled => _kAdminPasswordHash.isNotEmpty;

  /// 현재 잠금 만료까지 남은 시간 — null 또는 만료 이후면 잠금 없음.
  Future<Duration?> remainingLockout() async {
    final ms = await _storage.readLockedUntilMs();
    if (ms == null) return null;
    final until = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = _clock();
    if (until.isBefore(now) || until.isAtSameMomentAs(now)) {
      // 만료 — 정리해서 다음 호출이 깨끗한 상태로 시작.
      await _storage.deleteLockedUntil();
      return null;
    }
    return until.difference(now);
  }

  /// 비밀번호 검증.
  ///   * [VerifyResult.disabled] — 빌드에 해시 미주입.
  ///   * [VerifyResult.locked] — 잠금 진행 중 (또는 5회째 실패로 새로 잠금).
  ///   * [VerifyResult.success] — 일치. 카운터/잠금 클리어.
  ///   * [VerifyResult.failed] — 불일치. 카운터 +1.
  Future<VerifyResult> verify(String input) async {
    if (!isEnabled) return VerifyResult.disabled;

    if (await remainingLockout() != null) {
      return VerifyResult.locked;
    }

    final hash = hashPassword(input);
    if (hash == _kAdminPasswordHash) {
      await _storage.deleteFailCount();
      await _storage.deleteLockedUntil();
      return VerifyResult.success;
    }

    final next = (await _storage.readFailCount()) + 1;
    if (next >= kMaxAttempts) {
      final until = _clock().add(kLockDuration);
      await _storage.writeLockedUntilMs(until.millisecondsSinceEpoch);
      await _storage.deleteFailCount();
      return VerifyResult.locked;
    }
    await _storage.writeFailCount(next);
    return VerifyResult.failed;
  }

  /// 잠금/카운터 강제 해제. 운영용 — UI에서 호출하지 않음.
  Future<void> clearLockState() async {
    await _storage.deleteFailCount();
    await _storage.deleteLockedUntil();
  }

  /// 입력 문자열의 SHA-256 hex digest. 빌드 시 주입할 해시도 본 함수의
  /// 출력 형식(소문자 hex)을 따라야 함.
  static String hashPassword(String input) =>
      sha256.convert(utf8.encode(input)).toString();
}

enum VerifyResult { success, failed, locked, disabled }

/// 잠금 카운터/만료 영속화 인터페이스. V1엔 [_SecureStorageBackend] 단일
/// 구현, 테스트에선 fake 주입.
abstract class AdminAuthStorage {
  Future<int> readFailCount();
  Future<void> writeFailCount(int count);
  Future<void> deleteFailCount();
  Future<int?> readLockedUntilMs();
  Future<void> writeLockedUntilMs(int ms);
  Future<void> deleteLockedUntil();
}

class _SecureStorageBackend implements AdminAuthStorage {
  const _SecureStorageBackend();

  @override
  Future<int> readFailCount() async {
    final raw = await SecureStorage.read(SecureKeys.adminFailCount);
    return int.tryParse(raw ?? '') ?? 0;
  }

  @override
  Future<void> writeFailCount(int count) =>
      SecureStorage.write(SecureKeys.adminFailCount, count.toString());

  @override
  Future<void> deleteFailCount() =>
      SecureStorage.delete(SecureKeys.adminFailCount);

  @override
  Future<int?> readLockedUntilMs() async {
    final raw = await SecureStorage.read(SecureKeys.adminLockedUntil);
    if (raw == null || raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  @override
  Future<void> writeLockedUntilMs(int ms) =>
      SecureStorage.write(SecureKeys.adminLockedUntil, ms.toString());

  @override
  Future<void> deleteLockedUntil() =>
      SecureStorage.delete(SecureKeys.adminLockedUntil);
}
