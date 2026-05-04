import '../../../core/data/models/family_input.dart';

/// Family member entity used by the home/family UI layer.
/// Wraps [FamilyInput] (the recommendation-engine input) with an
/// identity (`id`) and a relationship label so the UI can group, sort
/// and personalize cards.
enum FamilyRelationship {
  self,
  spouseHusband,
  spouseWife,
  childSon,
  childDaughter,
  parentFather,
  parentMother,
  other,
}

extension FamilyRelationshipLabel on FamilyRelationship {
  String get label {
    switch (this) {
      case FamilyRelationship.self:
        return '본인';
      case FamilyRelationship.spouseHusband:
        return '남편';
      case FamilyRelationship.spouseWife:
        return '아내';
      case FamilyRelationship.childSon:
        return '아들';
      case FamilyRelationship.childDaughter:
        return '딸';
      case FamilyRelationship.parentFather:
        return '아빠';
      case FamilyRelationship.parentMother:
        return '엄마';
      case FamilyRelationship.other:
        return '가족';
    }
  }
}

class FamilyMember {
  final String id;
  final FamilyRelationship relationship;
  final FamilyInput input;

  const FamilyMember({
    required this.id,
    required this.relationship,
    required this.input,
  });

  String get name => input.name;
  int get age => input.age;
  Gender get gender => input.gender;
  AgeGroup get ageGroup => input.ageGroup;
  List<String> get currentProductIds => input.currentProductIds;
  DateTime? get lastCheckupDate => input.lastCheckup?.checkupDate;

  /// Avatar emoji based on relationship + age, per Stage 4 spec.
  String get avatarEmoji {
    switch (relationship) {
      case FamilyRelationship.self:
        return '👤';
      case FamilyRelationship.spouseHusband:
        return '👨';
      case FamilyRelationship.spouseWife:
        return '👩';
      case FamilyRelationship.childSon:
        return age < 13 ? '👦' : '🧑';
      case FamilyRelationship.childDaughter:
        return age < 13 ? '👧' : '🧑';
      case FamilyRelationship.parentFather:
        return age >= 65 ? '👴' : '👨';
      case FamilyRelationship.parentMother:
        return age >= 65 ? '👵' : '👩';
      case FamilyRelationship.other:
        return '🙂';
    }
  }

  FamilyMember copyWith({
    String? id,
    FamilyRelationship? relationship,
    FamilyInput? input,
  }) =>
      FamilyMember(
        id: id ?? this.id,
        relationship: relationship ?? this.relationship,
        input: input ?? this.input,
      );
}
