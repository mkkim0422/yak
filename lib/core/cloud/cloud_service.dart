import 'package:flutter_riverpod/flutter_riverpod.dart';

/// V1.x 단계 11에서 Supabase 통합 시 활성화될 클라우드 인터페이스의
/// **자리만** 잡는 추상. V1 출시 빌드는 [NoopCloudService] 단일 구현 — 실제
/// 네트워크 호출 없음. 처리방침 v1.3에 명시된 대로 V1엔 외부 전송 X.
///
/// 단계 11에서 추가될 메서드 후보(현 시점엔 의도적으로 비워둠 — 인터페이스
/// 표면이 단계 11 스키마 결정 전에 굳지 않도록):
///   * uploadUserPhoto(productId, photoPath, shareConsent)
///   * uploadUserReview(productId, review, shareConsent)
///   * pushManualEntryHash(hash) — 익명 카운터 +1
///   * pullCommunityCounters() — 단계 13 검토 큐용
abstract class CloudService {
  /// V1 의미: 항상 false. 단계 11에서 사용자 동의·로그인 상태 따라 true.
  bool get isAvailable;
}

/// V1 기본 구현 — 모든 호출이 no-op. 단계 11에서 SupabaseCloudService를
/// 추가하고 [cloudServiceProvider]를 override.
class NoopCloudService implements CloudService {
  const NoopCloudService();

  @override
  bool get isAvailable => false;
}

/// V1엔 NoopCloudService 고정. 단계 11에서 ProviderScope override로 실
/// 구현 주입 예정.
final cloudServiceProvider = Provider<CloudService>((ref) {
  return const NoopCloudService();
});
