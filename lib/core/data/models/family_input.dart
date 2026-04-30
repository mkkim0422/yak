import 'health_checkup_model.dart';
import 'product_model.dart';
import '../product_repository.dart';

enum Gender { male, female }

enum AgeGroup { newborn, toddler, child, teen, adult, elderly }

AgeGroup ageGroupFromAge(int age) {
  if (age <= 1) return AgeGroup.newborn;
  if (age <= 6) return AgeGroup.toddler;
  if (age <= 12) return AgeGroup.child;
  if (age <= 18) return AgeGroup.teen;
  if (age <= 59) return AgeGroup.adult;
  return AgeGroup.elderly;
}

extension AgeGroupLabel on AgeGroup {
  String get label {
    switch (this) {
      case AgeGroup.newborn:
        return '영유아';
      case AgeGroup.toddler:
        return '유아';
      case AgeGroup.child:
        return '어린이';
      case AgeGroup.teen:
        return '청소년';
      case AgeGroup.adult:
        return '성인';
      case AgeGroup.elderly:
        return '시니어';
    }
  }
}

enum SmokingAmount { light, moderate, heavy, veryHeavy }

enum DrinkingType { soju, beer, wine, liquor, mixed }

enum DrinkingFrequency { monthly, weekly, frequent }

enum Diet { korean, western, vegetarian, vegan, mixed }

enum ExerciseLevel { none, light, moderate, intense }

enum SleepLevel { poor, fair, good, excellent }

enum StressLevel { low, moderate, high, severe }

enum FeedingType { breast, formula, solid, mixed }

enum StoolFrequency { daily, twoOrThreeTimes, weekly, less }

enum StoolForm { hard, normal, soft, watery }

class FamilyInput {
  final String name;
  final int age;
  final Gender gender;
  final AgeGroup ageGroup;

  final bool? smoker;
  final SmokingAmount? smokingAmount;
  final bool? drinker;
  final DrinkingType? drinkingType;
  final DrinkingFrequency? drinkingFrequency;
  final Diet? diet;
  final ExerciseLevel? exerciseLevel;
  final SleepLevel? sleepLevel;
  final StressLevel? stressLevel;

  final bool? hasAllergies;
  final List<String>? allergies;
  final FeedingType? feedingType;
  final bool? pickyEating;
  final double? heightCm;
  final double? weightKg;
  final DateTime? heightWeightUpdated;
  final StoolFrequency? stoolFrequency;
  final StoolForm? stoolForm;
  final bool? eatsVegetables;
  final bool? eatsFish;

  final bool? digestiveIssues;
  final bool? takingMedications;

  final List<String> currentSupplements;
  final List<String> currentProductIds;
  final List<String> symptomIds;
  final HealthCheckup? lastCheckup;

  const FamilyInput({
    required this.name,
    required this.age,
    required this.gender,
    required this.ageGroup,
    this.smoker,
    this.smokingAmount,
    this.drinker,
    this.drinkingType,
    this.drinkingFrequency,
    this.diet,
    this.exerciseLevel,
    this.sleepLevel,
    this.stressLevel,
    this.hasAllergies,
    this.allergies,
    this.feedingType,
    this.pickyEating,
    this.heightCm,
    this.weightKg,
    this.heightWeightUpdated,
    this.stoolFrequency,
    this.stoolForm,
    this.eatsVegetables,
    this.eatsFish,
    this.digestiveIssues,
    this.takingMedications,
    this.currentSupplements = const [],
    this.currentProductIds = const [],
    this.symptomIds = const [],
    this.lastCheckup,
  });

  /// Returns total daily nutrient intake from all currently-taken products.
  /// Each product's ingredients are multiplied by the product's daily_dose.
  Map<String, double> getCurrentNutrientIntake(ProductRepository repo) {
    final result = <String, double>{};
    for (final id in currentProductIds) {
      final Product? product = repo.getById(id);
      if (product == null) continue;
      product.ingredients.forEach((nutrient, amount) {
        result.update(
          nutrient,
          (existing) => existing + amount * product.dailyDose,
          ifAbsent: () => amount * product.dailyDose,
        );
      });
    }
    return result;
  }

  bool get isHeavyDrinker =>
      drinker == true &&
      (drinkingFrequency == DrinkingFrequency.frequent ||
          drinkingFrequency == DrinkingFrequency.weekly);

  bool get isHighStress =>
      stressLevel == StressLevel.high || stressLevel == StressLevel.severe;

  bool get isVegetarian =>
      diet == Diet.vegetarian || diet == Diet.vegan;
}
