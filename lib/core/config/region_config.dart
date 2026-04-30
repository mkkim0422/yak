/// Region-specific adjustments for supplement recommendations.
class RegionConfig {
  RegionConfig._();

  static const String region = 'KR';

  static RegionAdjustment current() => regionAdjustments[region] ?? defaultAdj;

  static const RegionAdjustment defaultAdj = RegionAdjustment(
    region: 'default',
    vitaminDPriority: NutrientPriority.medium,
    omega3Priority: NutrientPriority.medium,
    ironCaution: false,
    notes: '',
  );

  static const Map<String, RegionAdjustment> regionAdjustments = {
    'KR': RegionAdjustment(
      region: 'KR',
      vitaminDPriority: NutrientPriority.high,
      omega3Priority: NutrientPriority.medium,
      ironCaution: false,
      notes: '한국 식단은 나트륨이 많고 비타민D 결핍률이 높아요',
    ),
    'JP': RegionAdjustment(
      region: 'JP',
      vitaminDPriority: NutrientPriority.medium,
      omega3Priority: NutrientPriority.low,
      ironCaution: false,
      notes: '생선 섭취가 많아 오메가3 결핍은 적은 편이에요',
    ),
    'US': RegionAdjustment(
      region: 'US',
      vitaminDPriority: NutrientPriority.medium,
      omega3Priority: NutrientPriority.high,
      ironCaution: false,
      notes: '강화식품으로 비타민D 보충이 비교적 잘 되어요',
    ),
    'SEA': RegionAdjustment(
      region: 'SEA',
      vitaminDPriority: NutrientPriority.low,
      omega3Priority: NutrientPriority.medium,
      ironCaution: true,
      notes: '햇빛이 충분해 비타민D는 덜 필요하지만 철분 결핍이 흔해요',
    ),
    'default': defaultAdj,
  };
}

class RegionAdjustment {
  final String region;
  final NutrientPriority vitaminDPriority;
  final NutrientPriority omega3Priority;
  final bool ironCaution;
  final String notes;

  const RegionAdjustment({
    required this.region,
    required this.vitaminDPriority,
    required this.omega3Priority,
    required this.ironCaution,
    required this.notes,
  });
}

enum NutrientPriority { low, medium, high }
