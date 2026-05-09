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

/// One product or manual entry rendered into a specific slot. V1+에서는
/// 사용자가 보통 아침에 한 번에 복용하는 행동 패턴에 맞춰, 1일 N회 분산
/// 라벨이라도 단일 슬롯에 [dailyDose]만큼 묶어 표시합니다.
class IntakeOccurrence {
  /// Stable id of the entry — product id or manual entry id. Used by the
  /// caller to remove or open the detail page.
  final String entryId;

  /// True when [entryId] points at a curated product (250 DB);
  /// false for [ManualProductEntry].
  final bool isCurated;

  /// Display name shown on the card.
  final String name;

  /// Total daily doses 묶음 (= dailyDose, 즉 dosePerIntake × intakesPerDay).
  /// 분복 라벨이라도 시간대 카드는 단일 슬롯에 합산해 표시합니다.
  final int dose;

  /// Unit string ("정", "캡슐", "포", ...). Empty falls back to "정"
  /// at render time.
  final String unit;

  /// Pre-meal / post-meal / 식사 중. 사용자 노출 라벨 뱃지(`timing.badgeText`)
  /// 가 표시 본문이며, 본 필드는 mealRelation 기반 회귀 검증용으로 유지.
  final MealRelation mealRelation;

  /// Original IntakeTiming — 카드 측에서 [IntakeTimingX.badgeText] 뱃지를
  /// 렌더할 때 사용.
  final IntakeTiming timing;

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
    required this.timing,
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
    final slot = _slotFor(p.intakeTiming);
    final occ = IntakeOccurrence(
      entryId: p.id,
      isCurated: true,
      name: p.name,
      dose: p.dailyDose,
      unit: unit,
      mealRelation: _mealRelationFor(p.intakeTiming),
      timing: p.intakeTiming,
      product: p,
    );
    _bucketFor(slot, morning, lunch, evening).add(occ);
  }

  for (final m in manuals) {
    final slot = _slotFor(m.intakeTiming);
    final occ = IntakeOccurrence(
      entryId: m.id,
      isCurated: false,
      name: m.name,
      dose: m.dailyDose,
      unit: '정',
      mealRelation: _mealRelationFor(m.intakeTiming),
      timing: m.intakeTiming,
      manual: m,
    );
    _bucketFor(slot, morning, lunch, evening).add(occ);
  }

  return IntakeGroupedSchedule(
    morning: List.unmodifiable(morning),
    lunch: List.unmodifiable(lunch),
    evening: List.unmodifiable(evening),
  );
}

/// IntakeTiming → 단일 슬롯 매핑. 사용자(30-40대 엄마)는 보통 아침에 한 번에
/// 복용하므로, 라벨에 "1일 N회 분산"이 있어도 슬롯은 단일로 묶고 dose는
/// dailyDose로 합산합니다 (intake_grouping의 buildGroupedSchedule 참조).
IntakeSlot _slotFor(IntakeTiming timing) {
  switch (timing) {
    case IntakeTiming.morningEmpty:
    case IntakeTiming.morningAfter:
    case IntakeTiming.anyTimeAfterMeal:
    case IntakeTiming.withMeal:
    case IntakeTiming.multiple:
      return IntakeSlot.morning;
    case IntakeTiming.lunchAfter:
      return IntakeSlot.lunch;
    case IntakeTiming.dinnerAfter:
    case IntakeTiming.beforeSleep:
      return IntakeSlot.evening;
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
