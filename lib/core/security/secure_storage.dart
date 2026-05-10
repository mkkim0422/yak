import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper around flutter_secure_storage with platform-specific options.
class SecureStorage {
  SecureStorage._();

  static const _options = AndroidOptions(
    encryptedSharedPreferences: true,
    resetOnError: false,
  );

  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  static const FlutterSecureStorage _instance = FlutterSecureStorage(
    aOptions: _options,
    iOptions: _iosOptions,
  );

  static FlutterSecureStorage get instance => _instance;

  static Future<void> write(String key, String value) =>
      _instance.write(key: key, value: value);

  static Future<String?> read(String key) => _instance.read(key: key);

  static Future<void> delete(String key) => _instance.delete(key: key);

  static Future<bool> contains(String key) =>
      _instance.containsKey(key: key);

  static Future<void> deleteAll() => _instance.deleteAll();

  /// 100% wipe used on logout / 30-day session expiry.
  static Future<void> wipe() => _instance.deleteAll();
}

/// Centralized secure-storage key namespace.
class SecureKeys {
  SecureKeys._();

  static const String privacyConsent = 'alyak.privacyConsent';
  static const String onboardingComplete = 'alyak.onboardingComplete';
  static const String familyDraftsIndex = 'alyak.familyDrafts.index';
  static const String familyOrder = 'alyak.familyOrder';

  static const String notificationSettings = 'alyak.notification.settings';

  static const String streakCount = 'alyak.streak.count';
  static const String streakLastDate = 'alyak.streak.lastDate';
  static const String streakBest = 'alyak.streak.best';

  static const String reorderDate = 'alyak.reorder.date';
  static const String sessionLastActive = 'alyak.session.lastActive';

  /// Admin 모드 인증 잠금 카운터/만료. 비밀번호 해시 자체는 빌드 시
  /// `--dart-define=ADMIN_PASSWORD_HASH=...`로 주입되어 SecureStorage엔
  /// 저장하지 않음 — APK 유출 시 해시가 디바이스 저장소에서 발견되지
  /// 않도록. 본 두 키는 잠금 상태 영속용.
  static const String adminFailCount = 'alyak.admin.fail_count';
  static const String adminLockedUntil = 'alyak.admin.locked_until';

  static String familyDraft(String memberId) => 'alyak.family.draft.$memberId';
  static String checkin(String memberId, String yyyymmdd) =>
      'alyak.checkin.$memberId.$yyyymmdd';
  static String aiComment(String memberId, String yyyymmdd) =>
      'ai_comment.$memberId.$yyyymmdd';
}
