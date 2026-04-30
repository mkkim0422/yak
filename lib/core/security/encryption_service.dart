import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';

import 'secure_storage.dart';

/// AES-256-GCM encryption with a per-device key stored in Keychain/Keystore.
/// On first launch, generates a random 256-bit key.
class EncryptionService {
  static const String _deviceKeyName = 'alyak.deviceKey.v1';

  Encrypter? _encrypter;
  Key? _key;

  Future<void> init() async {
    final existing = await SecureStorage.read(_deviceKeyName);
    if (existing == null) {
      final keyBytes = _randomBytes(32);
      _key = Key(keyBytes);
      await SecureStorage.write(_deviceKeyName, base64Encode(keyBytes));
    } else {
      _key = Key(Uint8List.fromList(base64Decode(existing)));
    }
    _encrypter = Encrypter(AES(_key!, mode: AESMode.gcm));
  }

  Uint8List _randomBytes(int length) {
    final rnd = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => rnd.nextInt(256)),
    );
  }

  /// Encrypts plaintext, returning a base64 string of `iv || ciphertext`.
  String encryptString(String plaintext) {
    _ensureInited();
    final iv = IV(_randomBytes(12));
    final encrypted = _encrypter!.encrypt(plaintext, iv: iv);
    final combined = Uint8List.fromList(iv.bytes + encrypted.bytes);
    return base64Encode(combined);
  }

  /// Decrypts a base64 string previously created by [encryptString].
  String decryptString(String encoded) {
    _ensureInited();
    final raw = base64Decode(encoded);
    final iv = IV(Uint8List.fromList(raw.sublist(0, 12)));
    final cipher = Encrypted(Uint8List.fromList(raw.sublist(12)));
    return _encrypter!.decrypt(cipher, iv: iv);
  }

  String encryptJson(Map<String, dynamic> json) =>
      encryptString(jsonEncode(json));

  Map<String, dynamic> decryptJson(String encoded) {
    final decoded = jsonDecode(decryptString(encoded));
    return decoded as Map<String, dynamic>;
  }

  Future<void> rotateKey() async {
    final keyBytes = _randomBytes(32);
    _key = Key(keyBytes);
    await SecureStorage.write(_deviceKeyName, base64Encode(keyBytes));
    _encrypter = Encrypter(AES(_key!, mode: AESMode.gcm));
  }

  void _ensureInited() {
    if (_encrypter == null) {
      throw StateError('EncryptionService.init() was not called');
    }
  }
}
