import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:alyak/features/family/models/family_member.dart';
import 'package:alyak/features/family/providers/family_provider.dart';

FamilyMember _member(String id, {String name = 'A'}) {
  final now = DateTime(2026, 5, 4, 10, 30);
  return FamilyMember(
    id: id,
    name: name,
    relationship: Relationship.self,
    birthYear: DateTime.now().year - 35,
    sex: Sex.female,
    heightCm: 165,
    weightKg: 55,
    smokingStatus: SmokingStatus.former,
    drinkingFrequency: DrinkingFrequency.weekly,
    dietQuality: DietQuality.average,
    sleepHours: SleepHours.fiveToSeven,
    stressLevel: StressLevel.high,
    allergies: const ['우유', '갑각류'],
    medications: const ['혈압약'],
    isPregnant: false,
    isBreastfeeding: false,
    currentProductIds: const ['prd_001', 'prd_002'],
    manualProducts: [
      ManualProductEntry(
        id: 'manual_1',
        name: '직접 입력 제품',
        brand: '브랜드A',
        category: '비타민D',
        dailyDose: 1,
        packageSize: 60,
        priceKrw: 12000,
        ingredients: const {'vitamin_d_iu': 1000},
        startedAt: DateTime(2026, 1, 1),
      ),
    ],
    activeSymptomIds: const ['fatigue'],
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('FamilyMember JSON roundtrip', () {
    test('all fields survive encode/decode', () {
      final original = _member('m1', name: '테스트');
      final encoded = jsonEncode(original.toJson());
      final decoded = FamilyMember.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      expect(decoded.id, 'm1');
      expect(decoded.name, '테스트');
      expect(decoded.relationship, Relationship.self);
      expect(decoded.sex, Sex.female);
      expect(decoded.smokingStatus, SmokingStatus.former);
      expect(decoded.drinkingFrequency, DrinkingFrequency.weekly);
      expect(decoded.allergies, ['우유', '갑각류']);
      expect(decoded.medications, ['혈압약']);
      expect(decoded.currentProductIds, ['prd_001', 'prd_002']);
      expect(decoded.manualProducts.length, 1);
      expect(decoded.manualProducts.first.id, 'manual_1');
      expect(decoded.manualProducts.first.ingredients['vitamin_d_iu'], 1000);
      expect(decoded.activeSymptomIds, ['fatigue']);
    });

    test('Migration: legacy "age" field maps to birthYear', () {
      final legacy = {
        'id': 'm_legacy',
        'name': '구버전',
        'relationship': 'self',
        'age': 30,
        'sex': 'female',
        'created_at': DateTime(2024, 1, 1).toIso8601String(),
        'updated_at': DateTime(2024, 1, 1).toIso8601String(),
      };
      final decoded = FamilyMember.fromJson(legacy);
      expect(decoded.birthYear, DateTime.now().year - 30);
      expect(decoded.age, 30);
    });

    test('profile_image_path round-trips when set', () {
      final original = _member('m1').copyWith(
        profileImagePath: '/data/profiles/m1_123.jpg',
      );
      final encoded = jsonEncode(original.toJson());
      final decoded = FamilyMember.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      expect(decoded.profileImagePath, '/data/profiles/m1_123.jpg');
    });

    test('legacy payload without profile_image_path → null', () {
      final original = _member('m1');
      final json = original.toJson()..remove('profile_image_path');
      final decoded =
          FamilyMember.fromJson(jsonDecode(jsonEncode(json)) as Map<String, dynamic>);
      expect(decoded.profileImagePath, isNull);
    });

    test('copyWith with explicit null clears the photo path', () {
      final withPhoto = _member('m1').copyWith(
        profileImagePath: '/data/profiles/m1_42.jpg',
      );
      expect(withPhoto.profileImagePath, isNotNull);
      final cleared = withPhoto.copyWith(profileImagePath: null);
      expect(cleared.profileImagePath, isNull);
    });

    test('copyWith without profileImagePath param preserves it', () {
      final withPhoto = _member('m1').copyWith(
        profileImagePath: '/data/profiles/m1_42.jpg',
      );
      final unchanged = withPhoto.copyWith(name: 'renamed');
      expect(unchanged.profileImagePath, '/data/profiles/m1_42.jpg');
      expect(unchanged.name, 'renamed');
    });
  });

  group('FamilyMembersNotifier persistence', () {
    test('addMember writes to storage and indexes the id', () async {
      final storage = InMemoryFamilyStorage();
      final notifier = FamilyMembersNotifier(
        storage,
        onMemberRemoved: noopMemberRemoved,
      );
      await notifier.ready;

      await notifier.addMember(_member('m1'));
      expect(notifier.state.length, 1);

      final indexJson = await storage.read(kFamilyMembersListKey);
      expect(jsonDecode(indexJson!), ['m1']);

      final memberJson = await storage.read('${kFamilyMemberPrefix}m1');
      expect(memberJson, isNotNull);
      expect(jsonDecode(memberJson!)['name'], 'A');
    });

    test('reload from storage restores previous members', () async {
      final storage = InMemoryFamilyStorage();
      final n1 = FamilyMembersNotifier(
        storage,
        onMemberRemoved: noopMemberRemoved,
      );
      await n1.ready;
      await n1.addMember(_member('m1', name: 'first'));
      await n1.addMember(_member('m2', name: 'second'));

      // Simulate app restart with the same backing store.
      final n2 = FamilyMembersNotifier(
        storage,
        onMemberRemoved: noopMemberRemoved,
      );
      await n2.ready;
      expect(n2.state.length, 2);
      expect(n2.state.map((m) => m.name), ['first', 'second']);
    });

    test('updateMember overwrites the stored payload', () async {
      final storage = InMemoryFamilyStorage();
      final notifier = FamilyMembersNotifier(
        storage,
        onMemberRemoved: noopMemberRemoved,
      );
      await notifier.ready;
      await notifier.addMember(_member('m1', name: 'before'));
      final original = notifier.state.first;
      await notifier.updateMember(original.copyWith(name: 'after'));
      expect(notifier.state.first.name, 'after');

      final stored = await storage.read('${kFamilyMemberPrefix}m1');
      expect(jsonDecode(stored!)['name'], 'after');
    });

    test('removeMember triggers notification cancel callback', () async {
      final storage = InMemoryFamilyStorage();
      final cancelled = <String>[];
      final notifier = FamilyMembersNotifier(
        storage,
        onMemberRemoved: (id) async => cancelled.add(id),
      );
      await notifier.ready;
      await notifier.addMember(_member('m1'));
      await notifier.removeMember('m1');
      expect(notifier.state, isEmpty);
      expect(cancelled, ['m1']);
      expect(await storage.read('${kFamilyMemberPrefix}m1'), isNull);
    });

    test('corrupted index → starts fresh without crashing', () async {
      final storage = InMemoryFamilyStorage({
        kFamilyMembersListKey: 'this is not json',
      });
      final notifier = FamilyMembersNotifier(
        storage,
        onMemberRemoved: noopMemberRemoved,
      );
      await notifier.ready;
      expect(notifier.state, isEmpty);
    });
  });
}
