import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Saves and removes per-member profile photos under
/// `<appDocs>/profiles/<memberId>_<ts>.jpg`. Stateless — paths returned
/// here are persisted on the [FamilyMember] itself.
class ProfilePhotoService {
  ProfilePhotoService({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<XFile?> pickFromCamera({
    double maxDim = 500,
    int quality = 80,
  }) =>
      _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxDim,
        maxHeight: maxDim,
        imageQuality: quality,
      );

  Future<XFile?> pickFromGallery({
    double maxDim = 500,
    int quality = 80,
  }) =>
      _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxDim,
        maxHeight: maxDim,
        imageQuality: quality,
      );

  /// Copies [src] into app-internal storage and returns the absolute path.
  Future<String> saveForMember({
    required String memberId,
    required XFile src,
  }) async {
    final dir = await _profilesDir();
    final fileName =
        '${memberId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final dest = '${dir.path}/$fileName';
    await File(src.path).copy(dest);
    return dest;
  }

  /// 직접 입력 영양제 약통 사진 — `<appDocs>/manual_products/<id>_<ts>.jpg`.
  /// 라벨 가독성을 위해 호출자는 800px / quality 85 정도로 캡처하길 권장.
  Future<String> saveForManualProduct({
    required String idHint,
    required XFile src,
  }) async {
    final dir = await _manualProductsDir();
    final fileName =
        '${idHint}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final dest = '${dir.path}/$fileName';
    await File(src.path).copy(dest);
    return dest;
  }

  /// Best-effort delete. Silently ignores a missing file so callers can
  /// chain it after replace/reset without try/catch noise. Also evicts
  /// the path from Flutter's image cache so a future load with the same
  /// path (rare but possible) is forced to re-decode rather than serve
  /// the now-deleted file's stale bytes.
  Future<void> deleteIfExists(String? path) async {
    if (path == null || path.isEmpty) return;
    final f = File(path);
    PaintingBinding.instance.imageCache.evict(FileImage(f));
    if (await f.exists()) {
      try {
        await f.delete();
      } catch (_) {
        // Disk full / permission — not worth surfacing for a thumbnail.
      }
    }
  }

  Future<Directory> _profilesDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/profiles');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _manualProductsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/manual_products');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
