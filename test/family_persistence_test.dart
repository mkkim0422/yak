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
    age: 35,
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
    lastCheckup: HealthCheckup(
      checkupDate: DateTime(2025, 11, 12),
      ldl: 110,
      fastingGlucose: 95,
      vitaminD: 22.5,
      systolicBp: 120,
      diastolicBp: 78,
    ),
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
      expect(decoded.lastCheckup?.ldl, 110);
      expect(decoded.lastCheckup?.systolicBp, 120);
      expect(decoded.activeSymptomIds, ['fatigue']);
    });

    test('HealthCheckup roundtrip preserves importedFromHealthApp', () {
      final original = HealthCheckup(
        checkupDate: DateTime(2025, 8, 1),
        importedFromHealthApp: true,
      );
      final decoded = HealthCheckup.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );
      expect(decoded.importedFromHealthApp, true);
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
