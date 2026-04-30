import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env_config.dart';

/// Strips PII from a profile before any data leaves the device.
class ClaudePayloadSanitizer {
  ClaudePayloadSanitizer._();

  static const Set<String> _piiKeys = {
    'name',
    'fullName',
    'firstName',
    'lastName',
    'phone',
    'mobile',
    'email',
    'address',
    'birthDate',
    'rrn',
    'ssn',
  };

  /// Returns a sanitized copy of [profile] safe for outbound API calls.
  /// - Removes any keys in the PII denylist.
  /// - Converts age (int) into an age band string like "30s".
  static Map<String, dynamic> sanitize(Map<String, dynamic> profile) {
    final result = <String, dynamic>{};
    profile.forEach((key, value) {
      if (_piiKeys.contains(key)) return;
      if (key == 'age' && value is int) {
        result['ageBand'] = _ageBand(value);
        return;
      }
      result[key] = value;
    });
    return result;
  }

  static String _ageBand(int age) {
    if (age < 2) return 'newborn';
    if (age < 7) return 'toddler';
    if (age < 13) return 'child';
    if (age < 20) return 'teen';
    final decade = (age ~/ 10) * 10;
    if (decade >= 70) return '70s+';
    return '${decade}s';
  }
}

/// Thin client around the Anthropic Messages API.
/// In Stage 1 the API key is empty, so all calls return null and callers
/// fall back to canned content.
class ClaudeApi {
  ClaudeApi({http.Client? client}) : _client = client ?? http.Client();

  static const String _endpoint = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-sonnet-4-6';
  static const Duration _timeout = Duration(seconds: 8);

  final http.Client _client;

  bool get isConfigured => EnvConfig.hasClaudeKey;

  /// Returns a single warm Korean comment for the home screen, or null on
  /// failure. Callers should fall back to a local message.
  Future<String?> getAiComment(Map<String, dynamic> profile) async {
    if (!isConfigured) return null;
    final sanitized = ClaudePayloadSanitizer.sanitize(profile);
    final prompt =
        '아래 가족 구성원 프로필을 보고, 영양제 챙김에 대한 따뜻한 한 줄 코멘트를 한국어 존댓말로 작성해주세요. '
        '의료 조언은 피하고, 1문장 25자 이내, 이모지는 1개까지만 사용해주세요.\n'
        '프로필: ${jsonEncode(sanitized)}';
    return _request(prompt);
  }

  /// Returns a Korean fallback explanation for a symptom search, or null.
  Future<String?> getSymptomFallback(String query) async {
    if (!isConfigured) return null;
    final prompt =
        '"$query" 증상에 일반적으로 도움이 될 수 있는 영양 성분을 2-3가지 한국어로 안내해주세요. '
        '진단·처방은 피하고, 마지막에 의사 상담 권유를 한 줄 포함해주세요.';
    return _request(prompt);
  }

  Future<String?> _request(String prompt) async {
    try {
      final response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': EnvConfig.claudeApiKey,
              'anthropic-version': '2023-06-01',
            },
            body: jsonEncode({
              'model': _model,
              'max_tokens': 256,
              'messages': [
                {
                  'role': 'user',
                  'content': prompt,
                },
              ],
            }),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) return null;
      final json = jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
      final content = json['content'];
      if (content is List && content.isNotEmpty) {
        final first = content.first as Map<String, dynamic>;
        final text = first['text'];
        if (text is String && text.isNotEmpty) return text.trim();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void dispose() => _client.close();
}

/// 식약처 (MFDS) public API placeholder.
/// Real endpoint integration is added in Phase 2 once the key is provisioned.
class MfdsApi {
  MfdsApi._();

  static bool get isConfigured => EnvConfig.hasMfdsKey;

  /// Returns null until the API key is available.
  static Future<Map<String, dynamic>?> lookupProduct(String _) async => null;
}
