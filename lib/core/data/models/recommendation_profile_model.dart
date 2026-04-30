// Models for age/gender/special-condition based supplement recommendation
// profiles loaded from `assets/data/age_group_recommendations.json`.

class MustTakeItem {
  final String name;
  final int priority;
  final String reason;

  const MustTakeItem({
    required this.name,
    required this.priority,
    required this.reason,
  });

  factory MustTakeItem.fromJson(Map<String, dynamic> json) => MustTakeItem(
        name: (json['name'] as String?) ?? '',
        priority: (json['priority'] as num?)?.toInt() ?? 9,
        reason: (json['reason'] as String?) ?? '',
      );
}

class RecommendedItem {
  final String name;
  final String reason;

  const RecommendedItem({required this.name, required this.reason});

  factory RecommendedItem.fromJson(Map<String, dynamic> json) =>
      RecommendedItem(
        name: (json['name'] as String?) ?? '',
        reason: (json['reason'] as String?) ?? '',
      );
}

class ConditionalItem {
  final String name;
  final String condition;

  const ConditionalItem({required this.name, required this.condition});

  factory ConditionalItem.fromJson(Map<String, dynamic> json) =>
      ConditionalItem(
        name: (json['name'] as String?) ?? '',
        condition: (json['condition'] as String?) ?? '',
      );
}

class RecommendationProfile {
  final String id;
  final String ageGroup;
  final String gender;
  final String? specialCondition;
  final List<MustTakeItem> mustTake;
  final List<RecommendedItem> highlyRecommended;
  final List<ConditionalItem> considerIf;
  final List<String> avoid;
  final Map<String, String> regionNotes;

  const RecommendationProfile({
    required this.id,
    required this.ageGroup,
    required this.gender,
    this.specialCondition,
    required this.mustTake,
    required this.highlyRecommended,
    required this.considerIf,
    required this.avoid,
    required this.regionNotes,
  });

  factory RecommendationProfile.fromJson(Map<String, dynamic> json) {
    final region = (json['region_notes'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    return RecommendationProfile(
      id: (json['id'] as String?) ?? '',
      ageGroup: (json['age_group'] as String?) ?? '',
      gender: (json['gender'] as String?) ?? 'unisex',
      specialCondition: json['special_condition'] as String?,
      mustTake: ((json['must_take'] as List?) ?? const [])
          .map((e) => MustTakeItem.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      highlyRecommended: ((json['highly_recommended'] as List?) ?? const [])
          .map((e) => RecommendedItem.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      considerIf: ((json['consider_if'] as List?) ?? const [])
          .map((e) => ConditionalItem.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      avoid: ((json['avoid'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      regionNotes: region.map((key, value) => MapEntry(key, value.toString())),
    );
  }
}
