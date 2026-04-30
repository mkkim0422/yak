import 'package:intl/intl.dart';

import '../../../core/api/claude_api.dart';
import '../../../core/security/secure_storage.dart';

/// Returns one warm Korean comment per family member per day.
/// Tries the Claude API when configured, otherwise returns a stable
/// fallback chosen by hashing (memberId, date).
class AiCommentService {
  AiCommentService({ClaudeApi? api}) : _api = api ?? ClaudeApi();

  static const String _cachePrefix = 'ai_comment';

  static const List<String> fallbackMessages = [
    '물 한 컵과 함께 영양제, 잊지 마세요 💧',
    '오늘도 가족 건강 챙기시느라 수고 많으세요 💚',
    '꾸준함이 가장 큰 보약이에요 🌱',
    '작은 습관이 큰 변화를 만들어요 ✨',
    '가족의 미소를 위한 한 알 💊',
    '오늘 컨디션 어떠세요? 😊',
    '건강한 하루 되세요 🌞',
    '영양제 한 알에 마음을 담아 보세요 🌷',
    '꾸준한 챙김이 큰 사랑이에요 💝',
    '오늘도 가족을 위한 하루 시작해요 🌅',
  ];

  final ClaudeApi _api;

  String fallbackFor({required String memberId, DateTime? date}) {
    final d = date ?? DateTime.now();
    final key = '$memberId-${d.year}-${d.month}-${d.day}';
    final index = key.hashCode.abs() % fallbackMessages.length;
    return fallbackMessages[index];
  }

  Future<String> getDailyComment({
    required String memberId,
    required Map<String, dynamic> profile,
    DateTime? date,
  }) async {
    final d = date ?? DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(d);
    final cacheKey = '$_cachePrefix.$memberId.$dateKey';

    final cached = await SecureStorage.read(cacheKey);
    if (cached != null && cached.isNotEmpty) return cached;

    final remote = await _api.getAiComment(profile);
    final message = (remote != null && remote.isNotEmpty)
        ? remote
        : fallbackFor(memberId: memberId, date: d);

    await SecureStorage.write(cacheKey, message);
    return message;
  }
}
