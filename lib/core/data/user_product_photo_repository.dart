import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../security/secure_storage.dart';
import 'models/user_product_keys.dart';
import 'models/user_product_photo.dart';

/// 큐레이션 [Product] (250 DB 항목)에 사용자가 부착한 자기 사진을 관리.
/// V1엔 로컬 파일 저장 (`<appDocs>/products/`) + SecureStorage JSON 메타.
/// V1.x 단계 10에서 Supabase로 마이그레이션될 때, 본 repository의 키
/// 스키마([UserProductKeys])가 그대로 클라우드 컬럼 키로 매핑됨.
class UserProductPhotoRepository {
  UserProductPhotoRepository({
    ImagePicker? picker,
    UserProductPhotoStorage? storage,
    Future<Directory> Function()? appDocsDir,
  })  : _picker = picker ?? ImagePicker(),
        _storage = storage ?? const _SecureStorageBackend(),
        _appDocsDir = appDocsDir ?? getApplicationDocumentsDirectory;

  final ImagePicker _picker;
  final UserProductPhotoStorage _storage;
  final Future<Directory> Function() _appDocsDir;

  /// productId 사진 목록을 등록 시각 오름차순으로 반환.
  Future<List<UserProductPhoto>> listFor(String productId) async {
    final raw = await _storage.readMeta(productId);
    final items = UserProductPhoto.decodeList(raw).toList();
    items.sort((a, b) => a.registeredAt.compareTo(b.registeredAt));
    return items;
  }

  /// 사진을 보유한 productId 인덱스 (V1.x 단계 10 마이그레이션 / 향후
  /// "내가 등록한 모든 사진" 화면에서 사용 예정).
  Future<List<String>> indexedProductIds() => _storage.readIndex();

  Future<XFile?> pickFromCamera() => _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

  Future<XFile?> pickFromGallery() => _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

  /// 사진 파일을 `<appDocs>/products/{productId}_{ts}.jpg`로 복사하고
  /// 메타를 SecureStorage에 누적. 동일 productId의 사진이 리스트에 추가됨.
  Future<UserProductPhoto> add({
    required String productId,
    required XFile src,
  }) async {
    final ts = DateTime.now();
    final dir = await _productsDir();
    final fileName = '${productId}_${ts.millisecondsSinceEpoch}.jpg';
    final dest = '${dir.path}${Platform.pathSeparator}$fileName';
    await File(src.path).copy(dest);

    final photo = UserProductPhoto(
      id: 'upp_${ts.microsecondsSinceEpoch}',
      productId: productId,
      photoPath: dest,
      registeredAt: ts,
    );

    final existing = await listFor(productId);
    final updated = <UserProductPhoto>[...existing, photo];
    await _storage.writeMeta(
      productId,
      UserProductPhoto.encodeList(updated),
    );
    await _addToIndex(productId);
    return photo;
  }

  /// 사진 한 장 삭제 — 디스크 파일 + SecureStorage 메타 둘 다. 마지막 한
  /// 장이면 인덱스에서도 productId 제거.
  Future<void> remove({
    required String productId,
    required String photoId,
  }) async {
    final existing = await listFor(productId);
    final remaining =
        existing.where((p) => p.id != photoId).toList(growable: false);
    if (remaining.length == existing.length) return; // not found
    final removed = existing.firstWhere((p) => p.id == photoId);
    await _deleteFileIfExists(removed.photoPath);
    if (remaining.isEmpty) {
      await _storage.deleteMeta(productId);
      await _removeFromIndex(productId);
    } else {
      await _storage.writeMeta(
        productId,
        UserProductPhoto.encodeList(remaining),
      );
    }
  }

  Future<void> _addToIndex(String productId) async {
    final ids = await _storage.readIndex();
    if (ids.contains(productId)) return;
    await _storage.writeIndex([...ids, productId]);
  }

  Future<void> _removeFromIndex(String productId) async {
    final ids = await _storage.readIndex();
    if (!ids.contains(productId)) return;
    final next = ids.where((id) => id != productId).toList(growable: false);
    if (next.isEmpty) {
      await _storage.deleteIndex();
    } else {
      await _storage.writeIndex(next);
    }
  }

  Future<Directory> _productsDir() async {
    final appDir = await _appDocsDir();
    final dir = Directory('${appDir.path}${Platform.pathSeparator}products');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _deleteFileIfExists(String path) async {
    if (path.isEmpty) return;
    final f = File(path);
    if (await f.exists()) {
      try {
        await f.delete();
      } catch (_) {
        // best-effort — 권한/디스크 풀은 사용자에게 노출하지 않음.
      }
    }
  }
}

/// SecureStorage / 클라우드 백엔드를 추상화하기 위한 인터페이스.
/// V1엔 [_SecureStorageBackend] 단일 구현, V1.x에서 Supabase 백엔드 추가.
abstract class UserProductPhotoStorage {
  Future<String?> readMeta(String productId);
  Future<void> writeMeta(String productId, String json);
  Future<void> deleteMeta(String productId);
  Future<List<String>> readIndex();
  Future<void> writeIndex(List<String> productIds);
  Future<void> deleteIndex();
}

class _SecureStorageBackend implements UserProductPhotoStorage {
  const _SecureStorageBackend();

  @override
  Future<String?> readMeta(String productId) =>
      SecureStorage.read(UserProductKeys.photosFor(productId));

  @override
  Future<void> writeMeta(String productId, String json) =>
      SecureStorage.write(UserProductKeys.photosFor(productId), json);

  @override
  Future<void> deleteMeta(String productId) =>
      SecureStorage.delete(UserProductKeys.photosFor(productId));

  @override
  Future<List<String>> readIndex() async {
    final raw = await SecureStorage.read(UserProductKeys.photosIndex);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final parsed = jsonDecode(raw);
      if (parsed is! List) return const [];
      return parsed.whereType<String>().toList(growable: false);
    } on FormatException {
      // 깨진 JSON / 평문 입력 — 안전하게 빈 리스트로 폴백.
      return const [];
    }
  }

  @override
  Future<void> writeIndex(List<String> productIds) =>
      SecureStorage.write(UserProductKeys.photosIndex, jsonEncode(productIds));

  @override
  Future<void> deleteIndex() =>
      SecureStorage.delete(UserProductKeys.photosIndex);
}
