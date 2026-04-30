import 'secure_storage.dart';

/// Tracks last active timestamp and triggers auto-logout after 30 days.
class SessionGuard {
  static const String _lastActiveKey = 'alyak.session.lastActive';
  static const Duration _maxIdle = Duration(days: 30);

  Future<void> touch() async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch.toString();
    await SecureStorage.write(_lastActiveKey, now);
  }

  Future<bool> isExpired() async {
    final raw = await SecureStorage.read(_lastActiveKey);
    if (raw == null) return false;
    final ts = int.tryParse(raw);
    if (ts == null) return true;
    final last = DateTime.fromMillisecondsSinceEpoch(ts, isUtc: true);
    final elapsed = DateTime.now().toUtc().difference(last);
    return elapsed > _maxIdle;
  }

  Future<void> clear() async {
    await SecureStorage.delete(_lastActiveKey);
  }
}
