import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alyak/core/data/product_repository.dart';
import 'package:alyak/features/family/models/family_member.dart';
import 'package:alyak/features/family/providers/family_provider.dart';
import 'package:alyak/features/home/providers/member_analysis_provider.dart';

FamilyMember _member(String id, {String name = 'A'}) {
  final now = DateTime(2026, 1, 1);
  return FamilyMember(
    id: id,
    name: name,
    relationship: Relationship.self,
    birthYear: 1990,
    sex: Sex.female,
    createdAt: now,
    updatedAt: now,
  );
}

ProviderContainer _container(List<FamilyMember> seed) {
  final container = ProviderContainer(
    overrides: [
      productRepositoryProvider.overrideWithValue(ProductRepository()),
      familyMembersProvider.overrideWith((ref) {
        final notifier = FamilyMembersNotifier(
          InMemoryFamilyStorage(),
          onMemberRemoved: noopMemberRemoved,
        );
        notifier.debugReplace(seed);
        return notifier;
      }),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('memberNutrientAnalysisProvider caching', () {
    test('repeated reads without state change return same instance', () {
      final c = _container([_member('m1')]);
      final first = c.read(memberNutrientAnalysisProvider('m1'));
      final second = c.read(memberNutrientAnalysisProvider('m1'));
      expect(identical(first, second), isTrue,
          reason: 'Riverpod should cache the analysis until deps change.');
    });

    test('mutating member B does not invalidate member A analysis', () {
      final c = _container([_member('mA'), _member('mB')]);
      final aBefore = c.read(memberNutrientAnalysisProvider('mA'));

      // Mutate B (different id).
      final bNew = c
          .read(familyControllerProvider)
          .getMember('mB')!
          .copyWith(name: 'B-renamed');
      c.read(familyControllerProvider).updateMember(bNew);

      final aAfter = c.read(memberNutrientAnalysisProvider('mA'));
      expect(identical(aBefore, aAfter), isTrue,
          reason:
              'select() should narrow the dep so only B re-runs analysis.');
    });

    test('mutating member A invalidates A analysis', () {
      final c = _container([_member('mA')]);
      final aBefore = c.read(memberNutrientAnalysisProvider('mA'));
      final aNew = c
          .read(familyControllerProvider)
          .getMember('mA')!
          .copyWith(name: 'A-renamed');
      c.read(familyControllerProvider).updateMember(aNew);
      final aAfter = c.read(memberNutrientAnalysisProvider('mA'));
      expect(identical(aBefore, aAfter), isFalse);
    });
  });
}
