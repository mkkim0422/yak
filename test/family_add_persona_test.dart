// Persona-driven branching of the family-add chat after the KDRIs 2025
// alignment cleanup:
//
//   * sex (step 4) skipped when relationship implies a sex
//   * pregnancy/lactation (step 7) only for female 20–50
//   * blood type (step 8) NEW — asked for everyone, optional
//   * smoking / drinking (steps 9, 10) — DROPPED (no KDRIs RDA)
//   * diet (step 11) only for 4+, simplified to 균형/부족
//   * sleep / stress (steps 12, 13) — DROPPED (no KDRIs RDA)
//   * medications (step 15) only for 1+
//   * checkup (step 17) only for 20+

import 'package:flutter_test/flutter_test.dart';

import 'package:alyak/features/family/models/family_member.dart';
import 'package:alyak/features/onboarding/screens/family_add_screen.dart';

bool _show(
  int step, {
  Relationship rel = Relationship.self,
  Sex sex = Sex.male,
  int age = 30,
}) =>
    debugShouldShowStep(step: step, relationship: rel, sex: sex, age: age);

void main() {
  group('relationship implies sex', () {
    test('explicit-sex relations resolve', () {
      expect(debugImpliedSex(Relationship.husband), Sex.male);
      expect(debugImpliedSex(Relationship.father), Sex.male);
      expect(debugImpliedSex(Relationship.son), Sex.male);
      expect(debugImpliedSex(Relationship.wife), Sex.female);
      expect(debugImpliedSex(Relationship.mother), Sex.female);
      expect(debugImpliedSex(Relationship.daughter), Sex.female);
    });

    test('self / other return null (we ask)', () {
      expect(debugImpliedSex(Relationship.self), isNull);
      expect(debugImpliedSex(Relationship.other), isNull);
    });
  });

  group('step 4 (sex)', () {
    test('skipped when the relationship implies sex', () {
      expect(_show(4, rel: Relationship.husband), isFalse);
      expect(_show(4, rel: Relationship.son), isFalse);
      expect(_show(4, rel: Relationship.daughter), isFalse);
    });

    test('asked for self / other', () {
      expect(_show(4, rel: Relationship.self), isTrue);
      expect(_show(4, rel: Relationship.other), isTrue);
    });
  });

  group('step 7 (pregnancy / lactation, combined)', () {
    test('female 20–50 → asked', () {
      expect(_show(7, rel: Relationship.wife, sex: Sex.female, age: 20),
          isTrue);
      expect(_show(7, rel: Relationship.wife, sex: Sex.female, age: 35),
          isTrue);
      expect(_show(7, rel: Relationship.wife, sex: Sex.female, age: 50),
          isTrue);
    });

    test('female under 20 / over 50 → skipped', () {
      expect(_show(7, rel: Relationship.daughter, sex: Sex.female, age: 19),
          isFalse);
      expect(_show(7, rel: Relationship.daughter, sex: Sex.female, age: 15),
          isFalse);
      expect(_show(7, rel: Relationship.mother, sex: Sex.female, age: 60),
          isFalse);
    });

    test('male of any age → skipped', () {
      expect(_show(7, rel: Relationship.husband, sex: Sex.male, age: 35),
          isFalse);
      expect(_show(7, rel: Relationship.son, sex: Sex.male, age: 10),
          isFalse);
    });
  });

  group('step 8 (blood type) — NEW, asked for all ages', () {
    test('shown for everyone — newborn through elderly', () {
      for (final age in [0, 1, 10, 35, 60, 80]) {
        expect(
          _show(8, rel: Relationship.son, sex: Sex.male, age: age),
          isTrue,
          reason: 'age $age',
        );
      }
    });
  });

  group('steps 9, 10, 12, 13 — DROPPED in KDRIs alignment', () {
    test('smoking (9) never shown', () {
      for (final age in [10, 19, 35, 60]) {
        expect(_show(9, rel: Relationship.son, sex: Sex.male, age: age),
            isFalse,
            reason: 'smoking age $age');
      }
    });

    test('drinking (10) never shown', () {
      for (final age in [10, 19, 35, 60]) {
        expect(_show(10, rel: Relationship.son, sex: Sex.male, age: age),
            isFalse,
            reason: 'drinking age $age');
      }
    });

    test('sleep (12) never shown', () {
      for (final age in [4, 19, 35, 60]) {
        expect(_show(12, rel: Relationship.son, sex: Sex.male, age: age),
            isFalse,
            reason: 'sleep age $age');
      }
    });

    test('stress (13) never shown', () {
      for (final age in [13, 19, 35, 60]) {
        expect(_show(13, rel: Relationship.son, sex: Sex.male, age: age),
            isFalse,
            reason: 'stress age $age');
      }
    });
  });

  group('step 11 (diet) — simplified, 4+', () {
    test('1-year-old → skipped', () {
      expect(_show(11, rel: Relationship.son, sex: Sex.male, age: 1),
          isFalse);
    });

    test('4-year-old → asked', () {
      expect(_show(11, rel: Relationship.son, sex: Sex.male, age: 4),
          isTrue);
    });

    test('adult / elderly → asked', () {
      expect(_show(11, rel: Relationship.wife, sex: Sex.female, age: 35),
          isTrue);
      expect(_show(11, rel: Relationship.mother, sex: Sex.female, age: 70),
          isTrue);
    });
  });

  group('step 5 (medical disclaimer) — only for under 4', () {
    test('shown for 0-3', () {
      expect(_show(5, rel: Relationship.son, sex: Sex.male, age: 0),
          isTrue);
      expect(_show(5, rel: Relationship.son, sex: Sex.male, age: 3),
          isTrue);
    });

    test('hidden for 4+', () {
      expect(_show(5, rel: Relationship.son, sex: Sex.male, age: 4),
          isFalse);
    });
  });

  group('step 15 (medications) — 1+', () {
    test('newborn → skipped', () {
      expect(_show(15, rel: Relationship.son, sex: Sex.male, age: 0),
          isFalse);
    });

    test('1-year-old → asked', () {
      expect(_show(15, rel: Relationship.son, sex: Sex.male, age: 1),
          isTrue);
    });
  });

  // ── Persona scenarios — end-to-end "what does this person see?" ──
  group('persona scenarios — KDRIs 2025 cleaned up', () {
    int countSteps({
      required Relationship rel,
      required Sex sex,
      required int age,
    }) {
      var n = 0;
      for (var s = 1; s <= 18; s++) {
        if (debugShouldShowStep(
            step: s, relationship: rel, sex: sex, age: age)) {
          n++;
        }
      }
      return n;
    }

    test('newborn (1세 son) → 9 steps', () {
      // Steps shown: 1 rel, 2 name, 3 birth, 5 disclaimer, 6 height,
      // 8 blood, 14 allergies, 15 meds, 16 products, 18 complete = 10
      // Not shown: 4 (implied), 7 (male), 9 / 10 / 12 / 13 (dropped),
      // 11 (under 4), 17 (under 20).
      expect(_show(11, rel: Relationship.son, sex: Sex.male, age: 1),
          isFalse);
      expect(_show(17, rel: Relationship.son, sex: Sex.male, age: 1),
          isFalse);
      expect(countSteps(rel: Relationship.son, sex: Sex.male, age: 1), 10);
    });

    test('teen (15세 daughter) → 11 steps', () {
      // Steps shown: 1, 2, 3, 6, 8, 11, 14, 15, 16, 18 — and now 4? No —
      // daughter implies female. = 10 steps shown.
      // 5 disclaimer skipped (over 4), 7 preg skipped (under 20),
      // 9/10/12/13 dropped, 17 checkup skipped (under 20).
      expect(_show(7, rel: Relationship.daughter, sex: Sex.female, age: 15),
          isFalse);
      expect(_show(9, rel: Relationship.daughter, sex: Sex.female, age: 15),
          isFalse);
      expect(
        countSteps(rel: Relationship.daughter, sex: Sex.female, age: 15),
        10,
      );
    });

    test('wife 35 (full adult panel) → 11 steps', () {
      // Steps shown: 1, 2, 3, 6, 7 (preg), 8 (blood), 11 (diet),
      // 14, 15, 16, 17 (checkup), 18. 4 implied. = 12.
      expect(_show(7, rel: Relationship.wife, sex: Sex.female, age: 35),
          isTrue);
      expect(
        countSteps(rel: Relationship.wife, sex: Sex.female, age: 35),
        12,
      );
    });

    test('mother 60 (no pregnancy) → 10 steps', () {
      // Steps shown: 1, 2, 3, 6, 8, 11, 14, 15, 16, 17, 18. 4 implied,
      // 7 skipped (>50), 9-13 dropped. = 11.
      expect(_show(7, rel: Relationship.mother, sex: Sex.female, age: 60),
          isFalse);
      expect(_show(9, rel: Relationship.mother, sex: Sex.female, age: 60),
          isFalse);
      expect(
        countSteps(rel: Relationship.mother, sex: Sex.female, age: 60),
        11,
      );
    });

    test('self (35세, female) — sex asked too → 12 steps', () {
      // Steps: 1, 2, 3, 4 (sex asked, self), 6, 7, 8, 11, 14, 15, 16, 17,
      // 18 = 13.
      expect(_show(4, rel: Relationship.self, sex: Sex.female, age: 35),
          isTrue);
      expect(
        countSteps(rel: Relationship.self, sex: Sex.female, age: 35),
        13,
      );
    });

    test('70세 grandparent → 10 steps', () {
      // 1, 2, 3, 6, 8, 11, 14, 15, 16, 17, 18. 4 implied (mother).
      // 7 skipped (>50), 9-13 dropped. = 11.
      expect(
        countSteps(rel: Relationship.mother, sex: Sex.female, age: 70),
        11,
      );
    });
  });
}
