// Locks the lastCheckupDate + checkupNote round-trip through FamilyMember
// JSON, and the step-17 (checkup) gating in the family-add chat.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:alyak/features/family/models/family_member.dart';
import 'package:alyak/features/onboarding/screens/family_add_screen.dart';

void main() {
  group('FamilyMember checkup round-trip', () {
    test('lastCheckupDate + checkupNote survive JSON serialize/deserialize',
        () {
      final m = FamilyMember(
        id: 'm1',
        name: '홍길동',
        relationship: Relationship.self,
        birthYear: 1990,
        sex: Sex.male,
        lastCheckupDate: DateTime(2025, 5, 1),
        checkupNote: '콜레스테롤 200, 정상',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );
      final restored = FamilyMember.fromJson(
        jsonDecode(jsonEncode(m.toJson())) as Map<String, dynamic>,
      );
      expect(restored.lastCheckupDate, DateTime(2025, 5, 1));
      expect(restored.checkupNote, '콜레스테롤 200, 정상');
    });

    test('legacy payloads (no checkup fields) deserialize cleanly', () {
      final raw = {
        'id': 'm2',
        'name': '레거시',
        'relationship': 'self',
        'birth_year': 1985,
        'sex': 'male',
        'created_at': '2020-01-01T00:00:00.000',
        'updated_at': '2020-01-01T00:00:00.000',
      };
      final m = FamilyMember.fromJson(raw);
      expect(m.lastCheckupDate, isNull);
      expect(m.checkupNote, isNull);
    });

    test('copyWith updates checkup fields', () {
      final m = FamilyMember(
        id: 'm1',
        name: '홍길동',
        relationship: Relationship.self,
        birthYear: 1990,
        sex: Sex.male,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );
      final updated = m.copyWith(
        lastCheckupDate: DateTime(2026, 3, 15),
        checkupNote: '메모',
      );
      expect(updated.lastCheckupDate, DateTime(2026, 3, 15));
      expect(updated.checkupNote, '메모');
    });
  });

  group('family-add step 17 (checkup) gating', () {
    bool show(int age) => debugShouldShowStep(
          step: 17,
          relationship: Relationship.self,
          sex: Sex.male,
          age: age,
        );

    test('19세 이하 → skipped', () {
      expect(show(0), isFalse);
      expect(show(15), isFalse);
      expect(show(19), isFalse);
    });

    test('20세+ → asked', () {
      expect(show(20), isTrue);
      expect(show(35), isTrue);
      expect(show(80), isTrue);
    });

    test('step 18 (complete) is always shown', () {
      expect(
        debugShouldShowStep(
          step: 18,
          relationship: Relationship.self,
          sex: Sex.male,
          age: 1,
        ),
        isTrue,
      );
    });
  });
}
