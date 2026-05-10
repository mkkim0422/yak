import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/models/user_product_review.dart';
import '../../../core/data/user_product_review_repository.dart';

/// 큐레이션 영양제 상세 화면에서 사용자 후기 1건을 reactive하게 표시하기
/// 위한 provider. V1 정책: productId 당 후기 1개 고정. V1.x 단계 10에서
/// 누적 정책으로 전환 시 UI만 변경.
final userProductReviewRepositoryProvider =
    Provider<UserProductReviewRepository>((ref) {
  return UserProductReviewRepository();
});

/// productId 별 후기 — 저장/삭제 후 [Ref.invalidate]로 갱신.
final userProductReviewProvider =
    FutureProvider.family<UserProductReview?, String>(
  (ref, productId) async {
    final repo = ref.watch(userProductReviewRepositoryProvider);
    return repo.getFor(productId);
  },
);
