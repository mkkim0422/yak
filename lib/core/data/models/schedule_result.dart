enum ScheduleSlot { morning, lunch, evening, beforeSleep }

extension ScheduleSlotLabel on ScheduleSlot {
  String get label {
    switch (this) {
      case ScheduleSlot.morning:
        return '아침';
      case ScheduleSlot.lunch:
        return '점심';
      case ScheduleSlot.evening:
        return '저녁';
      case ScheduleSlot.beforeSleep:
        return '취침 전';
    }
  }
}

class ScheduleConflict {
  final String a;
  final String b;
  final String reason;
  final int separateMinutes;

  const ScheduleConflict({
    required this.a,
    required this.b,
    required this.reason,
    required this.separateMinutes,
  });
}

class ScheduleSynergy {
  final String a;
  final String b;
  final String benefit;

  const ScheduleSynergy({
    required this.a,
    required this.b,
    required this.benefit,
  });
}

class ScheduleResult {
  final Map<ScheduleSlot, List<String>> bySlot;
  final List<ScheduleConflict> conflicts;
  final List<ScheduleSynergy> synergies;

  const ScheduleResult({
    required this.bySlot,
    required this.conflicts,
    required this.synergies,
  });

  static const ScheduleResult empty = ScheduleResult(
    bySlot: {
      ScheduleSlot.morning: [],
      ScheduleSlot.lunch: [],
      ScheduleSlot.evening: [],
      ScheduleSlot.beforeSleep: [],
    },
    conflicts: [],
    synergies: [],
  );

  List<String> forSlot(ScheduleSlot slot) =>
      bySlot[slot] ?? const <String>[];
}
