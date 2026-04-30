import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env_config.dart';
import '../security/secure_storage.dart';

/// One health functional food entry returned from the MFDS API.
class MfdsProduct {
  final String reportNumber;
  final String productName;
  final String company;
  final String mainFunction;
  final String dailyIntake;
  final String intakeMethod;
  final String? ingredients;
  final String? warnings;
  final DateTime? expirationDate;

  const MfdsProduct({
    required this.reportNumber,
    required this.productName,
    required this.company,
    required this.mainFunction,
    required this.dailyIntake,
    required this.intakeMethod,
    this.ingredients,
    this.warnings,
    this.expirationDate,
  });

  factory MfdsProduct.fromJson(Map<String, dynamic> json) {
    String pick(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return '';
    }

    String? pickOpt(List<String> keys) {
      final v = pick(keys);
      return v.isEmpty ? null : v;
    }

    return MfdsProduct(
      reportNumber: pick(['STTEMNT_NO', 'reportNumber']),
      productName: pick(['PRDLST_NM', 'PRODUCT_NM', 'productName']),
      company: pick(['BSSH_NM', 'company']),
      mainFunction: pick(['PRIMARY_FNCLTY', 'PRDLST_REPORT_FNCLTY', 'mainFunction']),
      dailyIntake: pick(['IFTKN_ATNT_MATR_CN', 'DAY_INTK', 'dailyIntake']),
      intakeMethod: pick(['INTAKE_HINT1', 'IFTKN_HINT', 'intakeMethod']),
      ingredients: pickOpt(['RAWMTRL_NM', 'ingredients']),
      warnings: pickOpt(['CSTDY_METHOD', 'warnings']),
      expirationDate: _parseDate(json['POG_DAYCNT'] ?? json['expirationDate']),
    );
  }

  Map<String, dynamic> toJson() => {
        'reportNumber': reportNumber,
        'productName': productName,
        'company': company,
        'mainFunction': mainFunction,
        'dailyIntake': dailyIntake,
        'intakeMethod': intakeMethod,
        if (ingredients != null) 'ingredients': ingredients,
        if (warnings != null) 'warnings': warnings,
        if (expirationDate != null)
          'expirationDate': expirationDate!.toIso8601String(),
      };

  static DateTime? _parseDate(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}

/// Client for the Korean MFDS public API
/// (Health Functional Food info — HtfsInfoService03).
///
/// Network calls fail soft: missing API key, transport errors, or non-200
/// responses all return empty results so the UI never crashes.
class MfdsApi {
  MfdsApi({http.Client? client}) : _client = client ?? http.Client();

  static const String _baseUrl =
      'http://apis.data.go.kr/1471000/HtfsInfoService03';
  static const Duration _timeout = Duration(seconds: 8);
  static const Duration _cacheTtl = Duration(hours: 24);
  static const String _cachePrefix = 'mfds.cache';

  final http.Client _client;

  bool get isConfigured => EnvConfig.hasMfdsKey;

  Future<List<MfdsProduct>> searchByName(
    String productName, {
    int page = 1,
    int pageSize = 20,
  }) async {
    if (!isConfigured) return const [];
    return _searchList(
      cacheKey: 'name.$productName.$page.$pageSize',
      params: {
        'prdlst_nm': productName,
        'pageNo': '$page',
        'numOfRows': '$pageSize',
      },
    );
  }

  Future<MfdsProduct?> getDetailByReportNumber(String reportNumber) async {
    if (!isConfigured) return null;
    final list = await _searchList(
      cacheKey: 'report.$reportNumber',
      params: {'sttemnt_no': reportNumber, 'pageNo': '1', 'numOfRows': '1'},
    );
    return list.isEmpty ? null : list.first;
  }

  Future<List<MfdsProduct>> searchByIngredient(
    String ingredient, {
    int page = 1,
    int pageSize = 20,
  }) async {
    if (!isConfigured) return const [];
    return _searchList(
      cacheKey: 'ingredient.$ingredient.$page.$pageSize',
      params: {
        'rawmtrl_nm': ingredient,
        'pageNo': '$page',
        'numOfRows': '$pageSize',
      },
    );
  }

  Future<List<MfdsProduct>> _searchList({
    required String cacheKey,
    required Map<String, String> params,
  }) async {
    final cached = await _readCache(cacheKey);
    if (cached != null) return cached;

    final uri = Uri.parse('$_baseUrl/getHtfsItem01').replace(
      queryParameters: {
        'serviceKey': EnvConfig.mfdsApiKey,
        'type': 'json',
        ...params,
      },
    );

    try {
      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return const [];
      final body = utf8.decode(response.bodyBytes);
      final items = _extractItems(jsonDecode(body));
      final result = items
          .map((e) => MfdsProduct.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
      await _writeCache(cacheKey, result);
      return result;
    } catch (_) {
      return const [];
    }
  }

  /// Walks the typical MFDS response envelope down to the list of items.
  List<dynamic> _extractItems(Object? decoded) {
    if (decoded is! Map<String, dynamic>) return const [];
    final root = decoded['response'] ?? decoded['Response'] ?? decoded;
    if (root is! Map<String, dynamic>) return const [];
    final body = root['body'] ?? root['Body'];
    if (body is! Map<String, dynamic>) return const [];
    final items = body['items'] ?? body['item'];
    if (items is List) return items;
    if (items is Map<String, dynamic>) {
      final inner = items['item'];
      if (inner is List) return inner;
      if (inner is Map<String, dynamic>) return [inner];
    }
    return const [];
  }

  Future<List<MfdsProduct>?> _readCache(String key) async {
    final raw = await SecureStorage.read('$_cachePrefix.$key');
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final ts = DateTime.tryParse(json['ts'] as String? ?? '');
      if (ts == null || DateTime.now().difference(ts) > _cacheTtl) return null;
      final list = (json['data'] as List?) ?? const [];
      return list
          .map((e) => MfdsProduct.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String key, List<MfdsProduct> data) async {
    final payload = jsonEncode({
      'ts': DateTime.now().toIso8601String(),
      'data': data.map((e) => e.toJson()).toList(),
    });
    await SecureStorage.write('$_cachePrefix.$key', payload);
  }

  void dispose() => _client.close();
}
