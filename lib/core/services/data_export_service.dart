import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../features/family/models/family_member.dart';

/// "내 데이터 내보내기" 기능. 사용자가 본 앱에 입력한 모든 가족 멤버 정보를
/// JSON으로 추출해 기기 내 파일로 저장합니다. V1.0은 외부 서버를 사용하지
/// 않으므로 본 export가 백업·이전의 유일한 경로입니다.
///
/// 출력 구조:
/// ```json
/// {
///   "schema": 1,
///   "exportedAt": "2026-05-07T12:34:56.000Z",
///   "appVersion": "1.0.0",
///   "members": [ ... FamilyMember.toJson() ... ],
///   "notes": "본 파일은 기기 내에서 생성됐으며 서버로 전송되지 않습니다."
/// }
/// ```
class DataExportService {
  DataExportService._();

  /// Schema version — Firebase / 클라우드 백업 도입 시 마이그레이션
  /// 키로 사용. 본 값은 [FamilyMember.toJson] 구조와 함께 올라갑니다.
  static const int schemaVersion = 1;
  static const String appVersion = '1.0.0';

  /// JSON 문자열 생성. 외부 저장 / 클립보드 복사 / 파일 쓰기 등 호출자
  /// 측에서 처리할 수 있도록 분리되어 있습니다.
  static String buildJson(List<FamilyMember> members) {
    final out = <String, dynamic>{
      'schema': schemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'appVersion': appVersion,
      'memberCount': members.length,
      'members': members.map((m) => m.toJson()).toList(),
      'notes': '본 파일은 기기 내에서 생성됐으며 서버로 전송되지 않습니다. '
          '복원/이전 시 다른 기기의 본 앱에서 import 기능을 사용하세요.',
    };
    return const JsonEncoder.withIndent('  ').convert(out);
  }

  /// 앱 외부 저장소 (사용자가 파일 매니저로 접근 가능)에 파일을 씁니다.
  /// Android만 지원 — iOS는 향후 share_plus 추가 시 구현.
  ///
  /// 반환값: 파일 경로. 호출자는 SnackBar 등으로 사용자에게 안내합니다.
  static Future<String> writeToExternalStorage(
    List<FamilyMember> members,
  ) async {
    final json = buildJson(members);
    Directory? dir;
    try {
      // Android 외부 저장소 (앱 종료 후에도 파일 남음).
      dir = await getExternalStorageDirectory();
    } catch (_) {
      dir = null;
    }
    // iOS 또는 외부 저장소 접근 실패 시 앱 내부 documents로 폴백.
    dir ??= await getApplicationDocumentsDirectory();

    final ts = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('.', '')
        .replaceAll('-', '')
        .substring(0, 13); // YYYYMMDDTHHMMSS 형식
    final file = File('${dir.path}/alyak_backup_$ts.json');
    await file.writeAsString(json);
    return file.path;
  }
}
