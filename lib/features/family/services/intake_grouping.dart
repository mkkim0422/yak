import '../../../core/data/models/product_model.dart';
import '../models/family_member.dart';

/// Three buckets shown on the member detail screen. Order matters — the
/// member screen renders them top-to-bottom in this order.
enum IntakeSlot { morning, lunch, evening }

extension IntakeSlotX on IntakeSlot {
  String get emoji => switch (this) {
        IntakeSlot.morning => '🌅',
        IntakeSlot.lunch => '🌞',
        IntakeSlot.evening => '🌙',
      };

  String get label => switch (this) {
        IntakeSlot.morning => '아침',
        IntakeSlot.lunch => '점심',
        IntakeSlot.evening => '저녁',
      };
}

/// One product or manual entry rendered into a specific slot. The same
/// underlying entry may appear in multiple slots when [intakesPerDay] >= 2
/// (분복) — each [IntakeOccurrence] carries its own [dose] for that slot.
class IntakeOccurrence {
  /// Stable id of the entry — product id or manual entry id. Used by the
  /// caller to remove or open the detail page.
  final String entryId;

  /// True when [entryId] points at a curated product (250 DB);
  /// false for [ManualProductEntry].
  final bool isCurated;

  /// Display name shown on the card.
  final String name;

  /// Doses taken at this slot (e.g. 1정, 2캡슐). Always ≥ 1.
  final int dose;

  /// Unit string ("정", "캡슐", "포", ...). Empty falls back to "정"
  /// at render time.
  final String unit;

  /// Pre-meal / post-meal / 식사 중 — used to render "식후 2정" inside
  /// the card. The slot emoji/label lives in the section header; this
  /// only adds a meal-relative hint.
  final MealRelation mealRelation;

  /// Backing curated [Product] when [isCurated]. Null for manuals.
  final Product? product;

  /// Backing [ManualProductEntry] when not curated.
  final ManualProductEntry? manual;

  const IntakeOccurrence({
    required this.entryId,
    required this.isCurated,
    required this.name,
    required this.dose,
    required this.unit,
    required this.mealRelation,
    this.product,
    this.manual,
  });
}

/// Whether the dose is taken before / during / after a meal. Drives
/// the inside-card label after we strip the emoji from the schedule line.
enum MealRelation { beforeMeal, withMeal, afterMeal, beforeSleep, none }

extension MealRelationX on MealRelation {
  String get label => switch (this) {
        MealRelation.beforeMeal => '식전',
        MealRelation.withMeal => '식사 중',
        MealRelation.afterMeal => '식후',
        MealRelation.beforeSleep => '취침 전',
        MealRelation.none => '',
      };
}

class IntakeGroupedSchedule {
  final List<IntakeOccurrence> morning;
  final List<IntakeOccurrence> lunch;
  final List<IntakeOccurrence> evening;

  const IntakeGroupedSchedule({
    required this.morning,
    required this.lunch,
    required this.evening,
  });

  int get total => morning.length + lunch.length + evening.length;

  List<IntakeOccurrence> forSlot(IntakeSlot slot) => switch (slot) {
        IntakeSlot.morning => morning,
        IntakeSlot.lunch => lunch,
        IntakeSlot.evening => evening,
      };
}

/// Build a [IntakeGroupedSchedule] from a member's full intake list.
/// Call sites pass the curated products already resolved from the repo,
/// so this stays trivially testable without I/O.
IntakeGroupedSchedule buildGroupedSchedule({
  required List<Product> curatedProducts,
  required List<ManualProductEntry> manuals,
}) {
  final morning = <IntakeOccurrence>[];
  final lunch = <IntakeOccurrence>[];
  final evening = <IntakeOccurrence>[];

  for (final p in curatedProducts) {
    final unit = p.unit.isEmpty ? '정' : p.unit;
    final slots = _slotsFor(p.intakeTiming, p.intakesPerDay);
    for (final slot in slots) {
      final occ = IntakeOccurrence(
        entryId: p.id,
        isCurated: true,
        name: p.name,
        dose: p.dosePerIntake,
        unit: unit,
        mealRelation: _mealRelationFor(p.intakeTiming),
        product: p,
      );
      _bucketFor(slot, morning, lunch, evening).add(occ);
    }
  }

  for (final m in manuals) {
    final slots = _slotsFor(m.intakeTiming, m.intakesPerDay);
    for (final slot in slots) {
      final occ = IntakeOccurrence(
        entryId: m.id,
        isCurated: false,
        name: m.name,
        dose: m.dosePerIntake,
        unit: '정',
        mealRelation: _mealRelationFor(m.intakeTiming),
        manual: m,
      );
      _bucketFor(slot, morning, lunch, evening).add(occ);
    }
  }

  return IntakeGroupedSchedule(
    morning: List.unmodifiable(morning),
    lunch: List.unmodifiable(lunch),
    evening: List.unmodifiable(evening),
  );
}

/// Returns the list of slots in which a product/manual should appear,
/// based on its [IntakeTiming] and [intakesPerDay].
///
/// Single-shot products land in exactly one slot. `multiple` and any
/// timing with `intakesPerDay >= 2` is split:
///   * 2 → morning + evening
///   * 3 → morning + lunch + evening
///   * 4+ → morning + lunch + evening (best-effort; the card carries a
///     "1일 N회 (라벨 참조)" note in the schedule label).
List<IntakeSlot> _slotsFor(IntakeTiming timing, int intakesPerDay) {
  if (intakesPerDay >= 2) {
    if (intakesPerDay == 2) {
      return const [IntakeSlot.morning, IntakeSlot.evening];
    }
    return const [IntakeSlot.morning, IntakeSlot.lunch, IntakeSlot.evening];
  }
  switch (timing) {
    case IntakeTiming.morningEmpty:
    case IntakeTiming.morningAfter:
    case IntakeTiming.anyTimeAfterMeal:
    case IntakeTiming.withMeal:
      return const [IntakeSlot.morning];
    case IntakeTiming.lunchAfter:
      return const [IntakeSlot.lunch];
    case IntakeTiming.dinnerAfter:
    case IntakeTiming.beforeSleep:
      return const [IntakeSlot.evening];
    case IntakeTiming.multiple:
      // Should not reach here when intakesPerDay == 1, but be defensive.
      return const [IntakeSlot.morning];
  }
}

MealRelation _mealRelationFor(IntakeTiming timing) {
  switch (timing) {
    case IntakeTiming.morningEmpty:
      return MealRelation.beforeMeal;
    case IntakeTiming.morningAfter:
    case IntakeTiming.lunchAfter:
    case IntakeTiming.dinnerAfter:
    case IntakeTiming.anyTimeAfterMeal:
      return MealRelation.afterMeal;
    case IntakeTiming.withMeal:
      return MealRelation.withMeal;
    case IntakeTiming.beforeSleep:
      return MealRelation.beforeSleep;
    case IntakeTiming.multiple:
      return MealRelation.afterMeal;
  }
}

List<IntakeOccurrence> _bucketFor(
  IntakeSlot slot,
  List<IntakeOccurrence> morning,
  List<IntakeOccurrence> lunch,
  List<IntakeOccurrence> evening,
) =>
    switch (slot) {
      IntakeSlot.morning => morning,
      IntakeSlot.lunch => lunch,
      IntakeSlot.evening => evening,
    };
