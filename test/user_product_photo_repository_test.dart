// 단계 7 — UserProductPhotoRepository 회귀 가드.
// SecureStorage / path_provider 호출은 storage 인터페이스와 임시 디렉토리
// 주입으로 격리. file I/O 자체는 dart:io 임시 디렉토리에서 그대로 검증.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:alyak/core/data/models/user_product_keys.dart';
import 'package:alyak/core/data/user_product_photo_repository.dart';

class _FakeStorage implements UserProductPhotoStorage {
  final Map<String, String> _meta = {};
  String? _index;

  @override
  Future<String?> readMeta(String productId) async =>
      _meta[UserProductKeys.photosFor(productId)];

  @override
  Future<void> writeMeta(String productId, String json) async {
    _meta[UserProductKeys.photosFor(productId)] = json;
  }

  @override
  Future<void> deleteMeta(String productId) async {
    _meta.remove(UserProductKeys.photosFor(productId));
  }

  @override
  Future<List<String>> readIndex() async {
    final raw = _index;
    if (raw == null || raw.isEmpty) return const [];
    try {
      final parsed = jsonDecode(raw);
      if (parsed is! List) return const [];
      return parsed.whereType<String>().toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<void> writeIndex(List<String> productIds) async {
    _index = jsonEncode(productIds);
  }

  @override
  Future<void> deleteIndex() async {
    _index = null;
  }

  // 깨진 JSON / 평문 입력 폴백 회귀를 검증하기 위한 직접 주입.
  void seedMetaRaw(String productId, String raw) {
    _meta[UserProductKeys.photosFor(productId)] = raw;
  }

  void seedIndexRaw(String raw) {
    _index = raw;
  }
}

void main() {
  late Directory tmp;
  late _FakeStorage storage;
  late UserProductPhotoRepository repo;
  late File srcFile;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('upp_test_');
    storage = _FakeStorage();
    repo = UserProductPhotoRepository(
      storage: storage,
      appDocsDir: () async => tmp,
    );
    // image_picker 의 XFile 은 임의 경로/바이트로 생성 가능.
    srcFile = File('${tmp.path}${Platform.pathSeparator}_src.jpg');
    await srcFile.writeAsBytes(List<int>.filled(8, 0));
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('add', () {
    test('파일 복사 + 메타 누적 + 인덱스 등록', () async {
      final photo = await repo.add(
        productId: 'centrum_man',
        src: XFile(srcFile.path),
      );

      expect(photo.productId, 'centrum_man');
      expect(photo.id.startsWith('upp_'), isTrue);
      expect(File(photo.photoPath).existsSync(), isTrue,
          reason: '복사된 파일이 디스크에 존재해야 함');
      expect(photo.photoPath, contains('products'),
          reason: '<appDocs>/products/ 하위에 저장되어야 함');

      final list = await repo.listFor('centrum_man');
      expect(list.length, 1);
      expect(list.first.id, photo.id);

      final index = await repo.indexedProductIds();
      expect(index, ['centrum_man']);
    });

    test('동일 productId 중복 추가 — 누적되며 인덱스는 1회만', () async {
      await repo.add(
          productId: 'centrum_man', src: XFile(srcFile.path));
      // 다른 마이크로초가 보장되도록 한 틱 양보.
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await repo.add(
          productId: 'centrum_man', src: XFile(srcFile.path));

      final list = await repo.listFor('centrum_man');
      expect(list.length, 2);
      expect(list[0].registeredAt.isBefore(list[1].registeredAt), isTrue,
          reason: '오름차순 정렬');

      final index = await repo.indexedProductIds();
      expect(index, ['centrum_man'],
          reason: '같은 productId는 인덱스에 한 번만 기록');
    });

    test('서로 다른 productId 격리', () async {
      await repo.add(
          productId: 'centrum_man', src: XFile(srcFile.path));
      await repo.add(
          productId: 'centrum_woman', src: XFile(srcFile.path));

      expect((await repo.listFor('centrum_man')).length, 1);
      expect((await repo.listFor('centrum_woman')).length, 1);

      final index = await repo.indexedProductIds();
      expect(index.toSet(), {'centrum_man', 'centrum_woman'});
    });
  });

  group('remove', () {
    test('일부 삭제 — 메타는 갱신, 인덱스는 유지', () async {
      final p1 = await repo.add(
          productId: 'centrum_man', src: XFile(srcFile.path));
      await Future<void>.delayed(const Duration(milliseconds: 2));
      final p2 = await repo.add(
          productId: 'centrum_man', src: XFile(srcFile.path));

      await repo.remove(productId: 'centrum_man', photoId: p1.id);

      expect(File(p1.photoPath).existsSync(), isFalse,
          reason: '삭제된 사진의 디스크 파일도 함께 제거');
      expect(File(p2.photoPath).existsSync(), isTrue);

      final list = await repo.listFor('centrum_man');
      expect(list.map((p) => p.id), [p2.id]);

      final index = await repo.indexedProductIds();
      expect(index, ['centrum_man'],
          reason: '잔여 사진이 있으면 인덱스 유지');
    });

    test('마지막 사진 삭제 — 메타·인덱스 모두 비움', () async {
      final p = await repo.add(
          productId: 'centrum_man', src: XFile(srcFile.path));
      await repo.remove(productId: 'centrum_man', photoId: p.id);

      expect(await repo.listFor('centrum_man'), isEmpty);
      expect(await repo.indexedProductIds(), isEmpty);
    });

    test('존재하지 않는 photoId — no-op', () async {
      final p = await repo.add(
          productId: 'centrum_man', src: XFile(srcFile.path));
      await repo.remove(
          productId: 'centrum_man', photoId: 'upp_does_not_exist');

      expect((await repo.listFor('centrum_man')).map((x) => x.id), [p.id]);
      expect(File(p.photoPath).existsSync(), isTrue);
    });
  });

  group('legacy / corruption tolerance', () {
    test('깨진 JSON 메타 → 빈 리스트로 폴백', () async {
      storage.seedMetaRaw('centrum_man', 'not-valid-json');
      final list = await repo.listFor('centrum_man');
      expect(list, isEmpty);
    });

    test('깨진 JSON 인덱스 → 빈 리스트로 폴백', () async {
      storage.seedIndexRaw('"plain string not array"');
      final ids = await repo.indexedProductIds();
      expect(ids, isEmpty);
    });

    test('share_consent 누락 legacy entry → false 폴백 (모델 회귀 가드)',
        () async {
      // V1 출시 시점에 저장된 메타에 share_consent 키가 없었더라도
      // 차후 add/remove 흐름이 깨지지 않아야 함.
      final legacyJson = jsonEncode([
        {
          'id': 'upp_legacy',
          'product_id': 'centrum_man',
          'photo_path': '/legacy/path.jpg',
          'registered_at': '2026-05-01T10:00:00.000',
        }
      ]);
      storage.seedMetaRaw('centrum_man', legacyJson);

      final list = await repo.listFor('centrum_man');
      expect(list.length, 1);
      expect(list.first.shareConsent, false);
      expect(list.first.id, 'upp_legacy');
    });
  });

  test('UserProductKeys 형태 — V1.x Supabase 마이그레이션 키 락', () {
    expect(UserProductKeys.photosFor('centrum_man'),
        'cloud.user_product_photos.centrum_man');
    expect(UserProductKeys.photosIndex,
        'cloud.user_product_photos.index');
  });
}
