// Locks the persona-driven branching of the family-add chat:
//   * sex (step 4) is skipped when the relationship implies a sex
//   * pregnancy/lactation (step 7) only for female 20–50
//   * step 8 is a permanent no-op (collapsed into 7)
//   * smoking/drinking (9, 10) only for 19+
//   * diet/sleep (11, 12) only for 4+
//   * stress (13) only for 13+
//   * medications (15) only for 1+

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

  test('step 8 is a permanent no-op (collapsed into 7)', () {
    for (final age in [10, 25, 35, 60]) {
      expect(
        _show(8, rel: Relationship.wife, sex: Sex.female, age: age),
        isFalse,
        reason: 'age $age',
      );
    }
  });

  group('step 9, 10 (smoking, drinking) — 19+', () {
    test('15-year-old → skipped', () {
      expect(_show(9, rel: Relationship.son, sex: Sex.male, age: 15),
          isFalse);
      expect(_show(10, rel: Relationship.son, sex: Sex.male, age: 15),
          isFalse);
    });

    test('19-year-old → asked', () {
      expect(_show(9, rel: Relationship.son, sex: Sex.male, age: 19),
          isTrue);
      expect(_show(10, rel: Relationship.son, sex: Sex.male, age: 19),
          isTrue);
    });
  });

  group('step 11, 12 (diet, sleep) — 4+', () {
    test('1-year-old → skipped', () {
      expect(_show(11, rel: Relationship.son, sex: Sex.male, age: 1),
          isFalse);
      expect(_show(12, rel: Relationship.son, sex: Sex.male, age: 1),
          isFalse);
    });

    test('4-year-old → asked', () {
      expect(_show(11, rel: Relationship.son, sex: Sex.male, age: 4),
          isTrue);
      expect(_show(12, rel: Relationship.son, sex: Sex.male, age: 4),
          isTrue);
    });
  });

  group('step 13 (stress) — 13+', () {
    test('child → skipped', () {
      expect(_show(13, rel: Relationship.son, sex: Sex.male, age: 8),
          isFalse);
    });

    test('teen → asked', () {
      expect(_show(13, rel: Relationship.son, sex: Sex.male, age: 13),
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
  group('persona scenarios', () {
    int countSteps({
      required Relationship rel,
      required Sex sex,
      required int age,
    }) {
      var n = 0;
      for (var s = 1; s <= 17; s++) {
        if (debugShouldShowStep(
            step: s, relationship: rel, sex: sex, age: age)) {
          n++;
        }
      }
      return n;
    }

    test('newborn (1세 son): no diet/sleep/stress, no smoking/drinking', () {
      // Steps shown: 1 rel, 2 name, 3 birth, 5 disclaimer, 6 height, 14 allergies,
      // 15 meds, 16 products, 17 complete = 9
      // Not shown: 4 (implied), 7 (male), 8 (no-op), 9-13 (under-age)
      expect(_show(4, rel: Relationship.son, sex: Sex.male, age: 1), isFalse);
      expect(_show(5, rel: Relationship.son, sex: Sex.male, age: 1), isTrue);
      expect(_show(11, rel: Relationship.son, sex: Sex.male, age: 1),
          isFalse);
      expect(_show(15, rel: Relationship.son, sex: Sex.male, age: 1), isTrue);
      expect(countSteps(rel: Relationship.son, sex: Sex.male, age: 1), 9);
    });

    test('teen (15세 daughter): no preg, no smoking/drinking, no stress', () {
      expect(_show(4, rel: Relationship.daughter, sex: Sex.female, age: 15),
          isFalse);
      expect(_show(7, rel: Relationship.daughter, sex: Sex.female, age: 15),
          isFalse);
      expect(_show(9, rel: Relationship.daughter, sex: Sex.female, age: 15),
          isFalse);
      expect(_show(13, rel: Relationship.daughter, sex: Sex.female, age: 15),
          isTrue);
    });

    test('wife 35: full adult panel', () {
      expect(_show(4, rel: Relationship.wife, sex: Sex.female, age: 35),
          isFalse); // skipped, implied
      expect(_show(7, rel: Relationship.wife, sex: Sex.female, age: 35),
          isTrue);
      expect(_show(9, rel: Relationship.wife, sex: Sex.female, age: 35),
          isTrue);
      expect(_show(13, rel: Relationship.wife, sex: Sex.female, age: 35),
          isTrue);
    });

    test('mother 60: no pregnancy', () {
      expect(_show(7, rel: Relationship.mother, sex: Sex.female, age: 60),
          isFalse);
      expect(_show(9, rel: Relationship.mother, sex: Sex.female, age: 60),
          isTrue);
    });

    test('self (35세, female): asks sex + everything else', () {
      expect(_show(4, rel: Relationship.self, sex: Sex.female, age: 35),
          isTrue); // not implied
      expect(_show(7, rel: Relationship.self, sex: Sex.female, age: 35),
          isTrue);
    });
  });
}
