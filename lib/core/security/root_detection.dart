import 'dart:io';

/// Lightweight rooted/jailbroken device detection. Warning-only — does not
/// block app usage. Avoid relying on this for any security-critical decision.
class RootDetection {
  RootDetection._();

  static const List<String> _androidSuPaths = [
    '/system/bin/su',
    '/system/xbin/su',
    '/sbin/su',
    '/system/app/Superuser.apk',
    '/system/etc/init.d/99SuperSUDaemon',
    '/system/xbin/daemonsu',
  ];

  static const List<String> _iosJailbreakPaths = [
    '/Applications/Cydia.app',
    '/Library/MobileSubstrate/MobileSubstrate.dylib',
    '/bin/bash',
    '/usr/sbin/sshd',
    '/etc/apt',
    '/private/var/lib/apt/',
  ];

  static Future<bool> isCompromised() async {
    try {
      if (Platform.isAndroid) {
        for (final p in _androidSuPaths) {
          if (await File(p).exists()) return true;
        }
      } else if (Platform.isIOS) {
        for (final p in _iosJailbreakPaths) {
          if (await File(p).exists()) return true;
        }
      }
    } catch (_) {
      return false;
    }
    return false;
  }
}
