enum ConflictKind {
  supplementSupplement,
  supplementDrug,
  overdose,
}

enum ConflictSeverity { info, caution, warning }

ConflictSeverity conflictSeverityFrom(String? raw) {
  switch (raw) {
    case 'warning':
      return ConflictSeverity.warning;
    case 'caution':
      return ConflictSeverity.caution;
    default:
      return ConflictSeverity.info;
  }
}

class ConflictWarning {
  final ConflictKind kind;
  final ConflictSeverity severity;
  final String title;
  final String description;
  final String? solution;

  const ConflictWarning({
    required this.kind,
    required this.severity,
    required this.title,
    required this.description,
    this.solution,
  });
}
