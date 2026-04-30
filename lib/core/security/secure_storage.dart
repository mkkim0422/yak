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
}
