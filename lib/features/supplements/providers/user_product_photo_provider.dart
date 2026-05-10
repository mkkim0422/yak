import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/models/user_product_photo.dart';
import '../../../core/data/user_product_photo_repository.dart';

/// 큐레이션 영양제 상세 화면에서 사용자 자기 사진 목록을 reactive하게
/// 표시하기 위한 provider. V1엔 SecureStorage 단일 백엔드, V1.x 단계 10에서
/// Supabase로 마이그레이션될 때 repository만 교체.
final userProductPhotoRepositoryProvider =
    Provider<UserProductPhotoRepository>((ref) {
  return UserProductPhotoRepository();
});

/// productId 별 사용자 사진 목록 — 등록/삭제 후 [Ref.invalidate]로 갱신.
final userProductPhotosProvider =
    FutureProvider.family<List<UserProductPhoto>, String>(
  (ref, productId) async {
    final repo = ref.watch(userProductPhotoRepositoryProvider);
    return repo.listFor(productId);
  },
);
