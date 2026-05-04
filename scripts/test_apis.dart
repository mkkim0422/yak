// Standalone API verification script.
//
// Reads keys from C:\alyak\.env (KEY=VALUE per line). It NEVER prints
// the keys themselves — only mask-safe summaries. Run with:
//
//   dart run scripts/test_apis.dart
//
// Designed to use only the Dart SDK (no pubspec dependency) so it can
// run before any flutter pub get.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _envPath = '.env';

/// Mask a key so we never accidentally leak it.
String _mask(String raw) {
  if (raw.length <= 6) return '***';
  return '${raw.substring(0, 4)}***${raw.substring(raw.length - 2)}';
}

Map<String, String> _loadEnv() {
  final file = File(_envPath);
  if (!file.existsSync()) {
    stderr.writeln('FATAL: .env not found at $_envPath');
    exit(1);
  }
  final out = <String, String>{};
  for (final line in file.readAsLinesSync()) {
    final t = line.trim();
    if (t.isEmpty || t.startsWith('#')) continue;
    final eq = t.indexOf('=');
    if (eq < 0) continue;
    out[t.substring(0, eq).trim()] = t.substring(eq + 1).trim();
  }
  return out;
}

class ApiResult {
  final int? status;
  final int durationMs;
  final dynamic body; // parsed if json, else String preview
  final String? error;
  ApiResult({
    this.status,
    required this.durationMs,
    this.body,
    this.error,
  });
}

Future<ApiResult> _httpJson(
  Uri uri, {
  Map<String, String> headers = const {},
}) async {
  final stopwatch = Stopwatch()..start();
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 15);
  try {
    final req = await client.getUrl(uri);
    headers.forEach(req.headers.set);
    req.headers.set('Accept', 'application/json');
    req.headers.set('User-Agent', 'alyak-api-tester/1.0');
    final res = await req.close().timeout(const Duration(seconds: 30));
    final raw = await res.transform(utf8.decoder).join();
    stopwatch.stop();
    dynamic parsed;
    try {
      parsed = jsonDecode(raw);
    } catch (_) {
      parsed = raw.length > 800 ? '${raw.substring(0, 800)}...' : raw;
    }
    return ApiResult(
      status: res.statusCode,
      durationMs: stopwatch.elapsedMilliseconds,
      body: parsed,
    );
  } catch (e) {
    stopwatch.stop();
    return ApiResult(
      durationMs: stopwatch.elapsedMilliseconds,
      error: e.toString(),
    );
  } finally {
    client.close(force: true);
  }
}

void _section(String title) {
  stdout.writeln('\n${'═' * 60}');
  stdout.writeln(title);
  stdout.writeln('═' * 60);
}

void _sub(String title) {
  stdout.writeln('\n──── $title ────');
}

// -------------------------------------------------------------------
// 1) data.go.kr 건강기능식품정보 (HtfsInfoService03 / getHtfsItem01)
// -------------------------------------------------------------------
Future<List<Map<String, dynamic>>> _testMfdsDataGo(String key) async {
  _section('1) MFDS data.go.kr — 건강기능식품정보');
  stdout.writeln('Endpoint: HtfsInfoService03/getHtfsItem01');
  stdout.writeln('Key: ${_mask(key)}');

  final queries = ['센트룸', '락토핏', '오메가3', '비타민D'];
  final results = <Map<String, dynamic>>[];

  // NOTE: spec said PRDLST_NM but the field returned by the API is
  // PRDUCT — try PRDUCT as the filter param. Both are sent so whichever
  // the server accepts will work.
  for (final q in queries) {
    _sub('검색어: $q');
    final uri = Uri.parse(
      'http://apis.data.go.kr/1471000/HtfsInfoService03/getHtfsItem01'
      '?serviceKey=${Uri.encodeComponent(key)}'
      '&pageNo=1&numOfRows=5&type=json'
      '&PRDUCT=${Uri.encodeComponent(q)}'
      '&PRDLST_NM=${Uri.encodeComponent(q)}',
    );
    final r = await _httpJson(uri);
    final entry = <String, dynamic>{
      'query': q,
      'status': r.status,
      'duration_ms': r.durationMs,
    };
    if (r.error != null) {
      stdout.writeln('  ❌ error: ${r.error}');
      entry['error'] = r.error;
      results.add(entry);
      continue;
    }
    stdout.writeln('  HTTP ${r.status}  ${r.durationMs}ms');

    final body = r.body;
    int? count;
    Map<String, dynamic>? firstItem;
    String? msg;
    if (body is Map) {
      // data.go.kr returns:
      //   {body: {items: [{item: {...}}, {item: {...}}], totalCount, ...}, header: {...}}
      final hdr = body['header'];
      if (hdr is Map) msg = '${hdr['resultCode']} ${hdr['resultMsg']}';

      Map? inner = (body['body'] is Map) ? body['body'] as Map : null;
      // Older shape: {response: {header, body}}
      if (inner == null && body['response'] is Map) {
        final response = body['response'] as Map;
        if (response['header'] is Map) {
          msg = '${(response['header'] as Map)['resultCode']} '
              '${(response['header'] as Map)['resultMsg']}';
        }
        if (response['body'] is Map) inner = response['body'] as Map;
      }
      if (inner != null) {
        count = (inner['totalCount'] as num?)?.toInt();
        final rawItems = inner['items'];
        if (rawItems is List && rawItems.isNotEmpty) {
          var first = rawItems.first;
          // Drill into nested {item: {...}} if present.
          if (first is Map && first.length == 1 && first['item'] is Map) {
            first = first['item'];
          }
          if (first is Map) {
            firstItem = first.cast<String, dynamic>();
          }
        } else if (rawItems is Map && rawItems['item'] != null) {
          final raw = rawItems['item'];
          if (raw is List && raw.isNotEmpty) {
            firstItem = (raw.first as Map).cast<String, dynamic>();
          } else if (raw is Map) {
            firstItem = raw.cast<String, dynamic>();
          }
        }
      }
    }
    stdout.writeln('  resultMsg: ${msg ?? '(none)'}');
    stdout.writeln('  totalCount: $count');
    if (firstItem != null) {
      stdout.writeln('  fields (${firstItem.length}):');
      for (final k in firstItem.keys.toList()..sort()) {
        final v = firstItem[k];
        final preview = v == null
            ? '(null)'
            : v.toString().length > 60
                ? '${v.toString().substring(0, 60)}…'
                : v.toString();
        stdout.writeln('    · $k = $preview');
      }
    } else {
      stdout.writeln('  (no items in response)');
    }
    entry['count'] = count;
    entry['first_item_fields'] = firstItem?.keys.toList();
    entry['first_item_sample'] = firstItem;
    results.add(entry);
  }
  return results;
}

// -------------------------------------------------------------------
// 2) foodsafetykorea.go.kr 영양DB (I0760)
// -------------------------------------------------------------------
Future<Map<String, dynamic>> _testFoodsafety(String key) async {
  _section('2) MFDS foodsafetykorea — 건강기능식품 영양DB I0760');
  stdout.writeln('Key: ${_mask(key)}');

  Future<Map<String, dynamic>> call(String suffix) async {
    final uri = Uri.parse(
      'http://openapi.foodsafetykorea.go.kr/api/$key/I0760/json/1/5$suffix',
    );
    final r = await _httpJson(uri);
    final out = <String, dynamic>{
      'status': r.status,
      'duration_ms': r.durationMs,
    };
    if (r.error != null) {
      stdout.writeln('  ❌ error: ${r.error}');
      out['error'] = r.error;
      return out;
    }
    stdout.writeln('  HTTP ${r.status}  ${r.durationMs}ms');
    final body = r.body;
    if (body is Map) {
      final wrapper = body['I0760'];
      if (wrapper is Map) {
        final result = wrapper['RESULT'];
        if (result is Map) {
          stdout.writeln(
              '  RESULT: ${result['CODE']} ${result['MSG']}');
        }
        final total = wrapper['total_count'];
        stdout.writeln('  total_count: $total');
        final rows = wrapper['row'];
        if (rows is List && rows.isNotEmpty) {
          final first = (rows.first as Map).cast<String, dynamic>();
          stdout.writeln('  fields (${first.length}):');
          for (final k in first.keys.toList()..sort()) {
            final v = first[k];
            final preview = v.toString().length > 60
                ? '${v.toString().substring(0, 60)}…'
                : v.toString();
            stdout.writeln('    · $k = $preview');
          }
          out['fields'] = first.keys.toList();
          out['first_row'] = first;
        } else {
          stdout.writeln('  (no row data)');
        }
        out['total'] = total;
      } else {
        stdout.writeln('  unexpected shape: ${body.keys}');
      }
    } else {
      stdout.writeln('  unexpected body type: ${body.runtimeType}');
    }
    return out;
  }

  _sub('기본 호출');
  final base = await call('');

  _sub('필터: HELT_ITM_GRP_NM=비타민');
  final filtered = await call('/HELT_ITM_GRP_NM=${Uri.encodeComponent('비타민')}');

  return {'base': base, 'filtered': filtered};
}

// -------------------------------------------------------------------
// 3) Naver Search API — shop.json
// -------------------------------------------------------------------
Future<List<Map<String, dynamic>>> _testNaver(
    String clientId, String clientSecret) async {
  _section('3) Naver 쇼핑 검색');
  stdout.writeln('ClientId: ${_mask(clientId)}  Secret: ${_mask(clientSecret)}');

  final queries = ['센트룸 우먼', '락토핏 골드', '종근당 프로메가', '솔가 비타민D'];
  final results = <Map<String, dynamic>>[];

  for (final q in queries) {
    _sub('검색어: $q');
    final uri = Uri.parse(
      'https://openapi.naver.com/v1/search/shop.json'
      '?query=${Uri.encodeComponent(q)}&display=5&sort=sim',
    );
    final r = await _httpJson(uri, headers: {
      'X-Naver-Client-Id': clientId,
      'X-Naver-Client-Secret': clientSecret,
    });
    final entry = <String, dynamic>{
      'query': q,
      'status': r.status,
      'duration_ms': r.durationMs,
    };
    if (r.error != null) {
      stdout.writeln('  ❌ error: ${r.error}');
      entry['error'] = r.error;
      results.add(entry);
      continue;
    }
    stdout.writeln('  HTTP ${r.status}  ${r.durationMs}ms');
    final body = r.body;
    if (body is Map) {
      stdout.writeln('  total: ${body['total']}  display: ${body['display']}');
      final items = body['items'];
      if (items is List && items.isNotEmpty) {
        entry['count'] = items.length;
        for (var i = 0; i < items.length; i++) {
          final it = (items[i] as Map).cast<String, dynamic>();
          stdout.writeln('  [#${i + 1}]');
          for (final k in const [
            'title',
            'image',
            'lprice',
            'hprice',
            'mallName',
            'maker',
            'brand',
            'productType',
          ]) {
            final v = it[k];
            final s = v?.toString() ?? '(null)';
            final preview =
                s.length > 80 ? '${s.substring(0, 80)}…' : s;
            stdout.writeln('    · $k = $preview');
          }
        }
        entry['first_item_keys'] = (items.first as Map).keys.toList();
        entry['first_image'] = (items.first as Map)['image'];
      } else {
        stdout.writeln('  (no items)');
        if (body['errorCode'] != null || body['errorMessage'] != null) {
          stdout.writeln(
              '  errorCode: ${body['errorCode']}  errorMessage: ${body['errorMessage']}');
          entry['errorCode'] = body['errorCode'];
          entry['errorMessage'] = body['errorMessage'];
        }
      }
    } else {
      final preview = body.toString();
      stdout.writeln('  unexpected body: '
          '${preview.length > 200 ? preview.substring(0, 200) + '...' : preview}');
    }
    results.add(entry);
  }
  return results;
}

// -------------------------------------------------------------------
// Image HEAD probe — verify the first Naver image URL is fetchable.
// -------------------------------------------------------------------
Future<int?> _headStatus(String url) async {
  try {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);
    final req = await client.headUrl(Uri.parse(url));
    final res = await req.close().timeout(const Duration(seconds: 12));
    client.close();
    return res.statusCode;
  } catch (_) {
    return null;
  }
}

Future<void> main() async {
  final env = _loadEnv();
  final required = const [
    'MFDS_DATAGO_KEY',
    'MFDS_FOODSAFETY_KEY',
    'NAVER_CLIENT_ID',
    'NAVER_CLIENT_SECRET',
  ];
  for (final k in required) {
    final v = env[k];
    if (v == null || v.isEmpty) {
      stderr.writeln('FATAL: missing env $k');
      exit(2);
    }
  }
  stdout.writeln('Loaded ${required.length} keys (all masked).');

  final mfds1 = await _testMfdsDataGo(env['MFDS_DATAGO_KEY']!);
  final mfds2 = await _testFoodsafety(env['MFDS_FOODSAFETY_KEY']!);
  final naver = await _testNaver(
    env['NAVER_CLIENT_ID']!,
    env['NAVER_CLIENT_SECRET']!,
  );

  // Final image-probe for Naver first hit.
  String? imgUrl;
  for (final n in naver) {
    if (n['first_image'] is String) {
      imgUrl = n['first_image'] as String;
      break;
    }
  }
  if (imgUrl != null) {
    _section('Naver 이미지 URL 작동 확인');
    final code = await _headStatus(imgUrl);
    stdout.writeln('  HEAD ${code ?? 'unreachable'}');
  }

  // Compact summary.
  _section('요약');
  void summary(String name, List<Map<String, dynamic>> r) {
    final ok = r.where((e) => e['status'] == 200 && e['error'] == null).length;
    final avg = r.isEmpty
        ? 0
        : (r.map((e) => e['duration_ms'] as int).reduce((a, b) => a + b) /
                r.length)
            .round();
    stdout.writeln('  $name: $ok/${r.length} 성공, 평균 ${avg}ms');
  }

  summary('식약처 정보 (data.go.kr)', mfds1);
  // foodsafety has 2 calls
  final ff = [mfds2['base'], mfds2['filtered']]
      .map((e) => (e as Map).cast<String, dynamic>())
      .toList();
  summary('식약처 영양DB (foodsafety)', ff);
  summary('네이버 쇼핑', naver);
}
