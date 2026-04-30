enum SymptomType { typeA, typeB }

enum SymptomUrgency { low, medium, high }

SymptomUrgency symptomUrgencyFrom(String? raw) {
  switch (raw) {
    case 'high':
      return SymptomUrgency.high;
    case 'medium':
      return SymptomUrgency.medium;
    default:
      return SymptomUrgency.low;
  }
}

class SymptomSupplementLink {
  final String supplement;
  final String relevance;
  final String safeExpression;

  const SymptomSupplementLink({
    required this.supplement,
    required this.relevance,
    required this.safeExpression,
  });

  factory SymptomSupplementLink.fromJson(Map<String, dynamic> json) =>
      SymptomSupplementLink(
        supplement: (json['supplement'] as String?) ?? '',
        relevance: (json['relevance'] as String?) ?? 'secondary',
        safeExpression: (json['safe_expression'] as String?) ?? '',
      );
}

class SymptomResult {
  final String id;
  final String symptom;
  final SymptomType type;
  final List<String> keywords;
  final List<SymptomSupplementLink> relatedSupplements;
  final List<String> lifestyleTips;
  final SymptomUrgency urgency;

  const SymptomResult({
    required this.id,
    required this.symptom,
    required this.type,
    required this.keywords,
    required this.relatedSupplements,
    required this.lifestyleTips,
    required this.urgency,
  });

  factory SymptomResult.fromJson(Map<String, dynamic> json) => SymptomResult(
        id: (json['id'] as String?) ?? '',
        symptom: (json['symptom'] as String?) ?? '',
        type: ((json['type'] as String?) ?? 'A') == 'B'
            ? SymptomType.typeB
            : SymptomType.typeA,
        keywords: ((json['keywords'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(growable: false),
        relatedSupplements: ((json['related_supplements'] as List?) ?? const [])
            .map((e) =>
                SymptomSupplementLink.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        lifestyleTips: ((json['lifestyle_tips'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(growable: false),
        urgency: symptomUrgencyFrom(json['urgency'] as String?),
      );
}
