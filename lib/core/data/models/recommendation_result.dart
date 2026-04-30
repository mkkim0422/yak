enum RecommendationCategory {
  mustTake,
  highlyRecommended,
  considerIf,
  alreadyTaking,
}

class RecommendedSupplement {
  final String name;
  final RecommendationCategory category;
  final int priority;
  final String reason;
  final String? personalizedReason;

  const RecommendedSupplement({
    required this.name,
    required this.category,
    required this.priority,
    required this.reason,
    this.personalizedReason,
  });

  RecommendedSupplement copyWith({
    RecommendationCategory? category,
    int? priority,
    String? reason,
    String? personalizedReason,
  }) =>
      RecommendedSupplement(
        name: name,
        category: category ?? this.category,
        priority: priority ?? this.priority,
        reason: reason ?? this.reason,
        personalizedReason: personalizedReason ?? this.personalizedReason,
      );
}

class RecommendationResult {
  final List<RecommendedSupplement> mustTake;
  final List<RecommendedSupplement> highlyRecommended;
  final List<RecommendedSupplement> considerIf;
  final List<RecommendedSupplement> alreadyTaking;
  final String regionNote;

  const RecommendationResult({
    required this.mustTake,
    required this.highlyRecommended,
    required this.considerIf,
    required this.alreadyTaking,
    required this.regionNote,
  });

  static const RecommendationResult empty = RecommendationResult(
    mustTake: [],
    highlyRecommended: [],
    considerIf: [],
    alreadyTaking: [],
    regionNote: '',
  );

  List<RecommendedSupplement> get all => [
        ...mustTake,
        ...highlyRecommended,
        ...considerIf,
      ];
}
