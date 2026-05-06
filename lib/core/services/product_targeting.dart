import '../data/models/product_model.dart';
import '../../features/family/models/family_member.dart';

/// Demographic groupings that the recommender can match products against.
/// The product DB has no `target_groups` field — we infer membership from
/// the Korean name + category, so the same logic works for the curated 250
/// without a data migration.
enum TargetGroup {
  kids,
  adultMale,
  adultFemale,
  seniorMale,
  seniorFemale,
  pregnant,
  menopauseFemale,
  menopauseMale,
}

/// Heuristic Korean keyword → target-group inference. Only fires when the
/// product itself self-identifies via name/category — generic products
/// (e.g. plain "비타민D 1000IU") return an empty set so they remain
/// recommendable to everyone.
Set<TargetGroup> inferProductTargets(Product p) {
  final out = <TargetGroup>{};
  final name = p.name.toLowerCase();
  final cat = p.category;

  // ── Kids ────────────────────────────────────────────────────────
  if (cat.startsWith('kids') ||
      name.contains('키즈') ||
      name.contains('어린이') ||
      name.contains('유아') ||
      name.contains('아이') ||
      name.contains('주니어')) {
    out.add(TargetGroup.kids);
  }

  // ── Pregnancy / prenatal ───────────────────────────────────────
  if (cat == 'prenatal' ||
      cat == 'pregnancy' ||
      name.contains('임산부') ||
      name.contains('산모') ||
      name.contains('엘레비트') ||
      name.contains('prenatal')) {
    out.add(TargetGroup.pregnant);
  }

  // ── Female / menopause female ──────────────────────────────────
  final isFemale = name.contains('우먼') ||
      name.contains('woman') ||
      name.contains("women's") ||
      name.contains('women') ||
      name.contains('여성') ||
      cat == 'women_health';
  final isMale = name.contains('맨') ||
      name.contains("men's") ||
      name.contains(' men ') ||
      name.endsWith(' men') ||
      name.contains('남성') ||
      cat == 'men_health';
  final isSenior = name.contains('실버') ||
      name.contains('시니어') ||
      name.contains('senior') ||
      name.contains('50+') ||
      name.contains('silver');

  if (cat == 'menopause_female') {
    out.add(TargetGroup.menopauseFemale);
  }
  if (cat == 'menopause_male') {
    out.add(TargetGroup.menopauseMale);
  }
  if (isFemale) {
    out.add(isSenior ? TargetGroup.seniorFemale : TargetGroup.adultFemale);
  }
  if (isMale) {
    out.add(isSenior ? TargetGroup.seniorMale : TargetGroup.adultMale);
  }
  if (isSenior && !isFemale && !isMale) {
    // Generic senior — match either sex's senior persona.
    out
      ..add(TargetGroup.seniorFemale)
      ..add(TargetGroup.seniorMale);
  }

  return out;
}

/// The persona's "wanted" target groups, in priority order. Higher = better
/// match. Used by the recommender to score candidate products.
List<TargetGroup> personaTargets(FamilyMember m) {
  // Pregnancy trumps everything.
  if (m.isPregnant) {
    return [TargetGroup.pregnant, TargetGroup.adultFemale];
  }

  final age = m.age;
  if (age < 13) {
    return [TargetGroup.kids];
  }
  if (m.sex == Sex.female) {
    if (age >= 65) return [TargetGroup.seniorFemale, TargetGroup.adultFemale];
    if (age >= 50) {
      return [
        TargetGroup.menopauseFemale,
        TargetGroup.adultFemale,
        TargetGroup.seniorFemale,
      ];
    }
    return [TargetGroup.adultFemale];
  } else {
    if (age >= 65) return [TargetGroup.seniorMale, TargetGroup.adultMale];
    if (age >= 50) {
      return [
        TargetGroup.menopauseMale,
        TargetGroup.adultMale,
        TargetGroup.seniorMale,
      ];
    }
    return [TargetGroup.adultMale];
  }
}

/// Persona ↔ product targeting score.
///
/// * +50 when the product self-identifies as the persona's primary group
/// * +20 for a secondary persona match (e.g. senior female → adult female)
/// * +10 when the product is generic (no target groups inferred)
/// * −100 hard exclusion when the product targets the *opposite* persona
///   (e.g. "센트룸 맨" never recommended to a female persona)
int targetMatchScore({
  required Product product,
  required FamilyMember member,
}) {
  final productTargets = inferProductTargets(product);
  if (productTargets.isEmpty) return 10; // Generic — universally recommendable

  final wanted = personaTargets(member);
  if (wanted.isEmpty) return 10;

  for (var i = 0; i < wanted.length; i++) {
    if (productTargets.contains(wanted[i])) {
      return i == 0 ? 50 : 20;
    }
  }

  // Hard exclusion — wrong-sex / wrong-age targeted products.
  final exclusions = _exclusionGroups(member);
  if (productTargets.any(exclusions.contains)) return -100;
  return 0;
}

Set<TargetGroup> _exclusionGroups(FamilyMember m) {
  final out = <TargetGroup>{};
  if (m.isPregnant) {
    // Pregnancy excludes male-targeted and senior-male.
    out
      ..add(TargetGroup.adultMale)
      ..add(TargetGroup.seniorMale)
      ..add(TargetGroup.menopauseMale);
    return out;
  }
  if (m.age < 13) {
    out
      ..add(TargetGroup.adultMale)
      ..add(TargetGroup.adultFemale)
      ..add(TargetGroup.seniorMale)
      ..add(TargetGroup.seniorFemale)
      ..add(TargetGroup.menopauseMale)
      ..add(TargetGroup.menopauseFemale)
      ..add(TargetGroup.pregnant);
    return out;
  }
  if (m.sex == Sex.female) {
    out
      ..add(TargetGroup.adultMale)
      ..add(TargetGroup.seniorMale)
      ..add(TargetGroup.menopauseMale);
    if (m.age < 50) out.add(TargetGroup.menopauseFemale);
  } else {
    out
      ..add(TargetGroup.adultFemale)
      ..add(TargetGroup.seniorFemale)
      ..add(TargetGroup.menopauseFemale)
      ..add(TargetGroup.pregnant);
    if (m.age < 50) out.add(TargetGroup.menopauseMale);
  }
  // Adults should not get kids' products even if generic-looking.
  if (m.age >= 19) out.add(TargetGroup.kids);
  return out;
}
