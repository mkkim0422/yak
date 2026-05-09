/// Category → user-facing label / general benefit / cautions copy used
/// by the product detail screen. Keep this side of the codebase
/// statically known so the screen renders identically without an
/// extra JSON lookup.
library;

class ProductCategoryMeta {
  final String label;
  final String benefit;

  /// Optional cautions list. Empty list means we render no warnings
  /// section for this category.
  final List<String> cautions;

  const ProductCategoryMeta({
    required this.label,
    required this.benefit,
    this.cautions = const [],
  });
}

const ProductCategoryMeta _kFallback = ProductCategoryMeta(
  label: '영양제',
  benefit: '제품 라벨에 표시된 효능을 확인해주세요',
);

const Map<String, ProductCategoryMeta> _kCategoryMeta = {
  'multivitamin': ProductCategoryMeta(
    label: '종합비타민',
    benefit: '여러 비타민·미네랄을 한 번에 보충해 균형 잡힌 영양 섭취를 도와요',
  ),
  'omega3': ProductCategoryMeta(
    label: '오메가-3',
    benefit: 'EPA·DHA가 들어 있어 혈중 중성지방·혈행 개선에 도움이 돼요',
    cautions: ['항응고제 복용 시 약사·의사와 상의'],
  ),
  'krill_oil': ProductCategoryMeta(
    label: '크릴오일',
    benefit: '인지질 형태의 오메가-3 + 아스타잔틴 — 흡수율과 항산화에 강점이 있어요',
    cautions: ['갑각류 알레르기 시 주의'],
  ),
  'vitamin_d': ProductCategoryMeta(
    label: '비타민D',
    benefit: '뼈 건강, 면역 기능, 칼슘 흡수에 도움을 줘요',
    cautions: ['신장질환·부갑상선 질환 시 의사와 상의'],
  ),
  'vitamin_c': ProductCategoryMeta(
    label: '비타민C',
    benefit: '항산화, 면역, 피로 회복에 도움을 주는 수용성 비타민이에요',
    cautions: ['고용량 장기 복용 시 신장결석 위험 — 1g/일 이내 권장'],
  ),
  'vitamin_b': ProductCategoryMeta(
    label: '비타민B군',
    benefit: '에너지 대사, 신경 건강, 피로 회복에 도움을 줘요',
  ),
  'biotin': ProductCategoryMeta(
    label: '비오틴',
    benefit: '모발·손톱·피부 건강에 도움을 주는 비타민B군이에요',
  ),
  'probiotic': ProductCategoryMeta(
    label: '유산균',
    benefit: '장 내 유익균 보충으로 배변·면역에 도움이 돼요',
  ),
  'probiotics': ProductCategoryMeta(
    label: '유산균',
    benefit: '장 내 유익균 보충으로 배변·면역에 도움이 돼요',
  ),
  'fiber': ProductCategoryMeta(
    label: '식이섬유',
    benefit: '배변 활동에 도움을 줘요',
    cautions: ['복용 시 충분한 물과 함께'],
  ),
  'calcium': ProductCategoryMeta(
    label: '칼슘',
    benefit: '뼈·치아 형성에 필요한 영양소예요',
    cautions: ['신장결석 병력 시 주의', '갑상선약·철분제와 2시간 간격'],
  ),
  'magnesium': ProductCategoryMeta(
    label: '마그네슘',
    benefit: '근육·신경 건강과 수면 질에 도움을 줘요',
    cautions: ['고용량 시 설사 가능 — 분복 권장'],
  ),
  'iron': ProductCategoryMeta(
    label: '철분',
    benefit: '적혈구 형성과 산소 운반에 필요한 미네랄이에요',
    cautions: ['공복 흡수 좋지만 위장 자극 시 식후 복용', '변비·구역질 가능'],
  ),
  'mineral': ProductCategoryMeta(
    label: '미네랄',
    benefit: '필수 미네랄을 보충해 신체 균형 유지에 도움을 줘요',
  ),
  'lutein': ProductCategoryMeta(
    label: '루테인',
    benefit: '눈의 황반 색소 밀도를 유지하고 눈 건강에 도움을 줘요',
  ),
  'eye': ProductCategoryMeta(
    label: '눈 건강',
    benefit: '루테인·지아잔틴·아스타잔틴 등 눈 건강 영양소를 보충해요',
  ),
  'antioxidant': ProductCategoryMeta(
    label: '항산화',
    benefit: '활성산소 중화 — 노화·피로·면역에 도움을 줘요',
  ),
  'collagen': ProductCategoryMeta(
    label: '콜라겐',
    benefit: '피부 탄력과 관절·결합조직 건강에 도움을 줘요',
  ),
  'joint': ProductCategoryMeta(
    label: '관절',
    benefit: '글루코사민·콘드로이친·MSM 등으로 관절 건강에 도움을 줘요',
  ),
  'liver': ProductCategoryMeta(
    label: '간 건강',
    benefit: '밀크씨슬·실리마린이 간세포 보호에 도움을 줘요',
  ),
  'sleep': ProductCategoryMeta(
    label: '수면',
    benefit: '멜라토닌·테아닌·GABA로 입면·숙면에 도움을 줘요',
    cautions: ['복용 후 운전 금지', '항우울제·항불안제와 상의'],
  ),
  'immune': ProductCategoryMeta(
    label: '면역',
    benefit: '비타민C·아연·프로폴리스 등으로 면역에 도움을 줘요',
  ),
  'immunity': ProductCategoryMeta(
    label: '면역',
    benefit: '비타민C·아연·프로폴리스 등으로 면역에 도움을 줘요',
  ),
  'circulation': ProductCategoryMeta(
    label: '혈행',
    benefit: '은행잎추출물·코엔자임Q10 등으로 혈액순환에 도움을 줘요',
    cautions: ['항응고제 복용 시 의사와 상의'],
  ),
  'menopause_female': ProductCategoryMeta(
    label: '갱년기 여성',
    benefit: '갱년기 여성 호르몬 변화로 인한 불편에 도움을 줘요',
  ),
  'menopause_male': ProductCategoryMeta(
    label: '갱년기 남성',
    benefit: '중년 남성 활력과 호르몬 균형에 도움을 줘요',
  ),
  'women_health': ProductCategoryMeta(
    label: '여성 건강',
    benefit: '여성에게 부족하기 쉬운 철분·엽산·칼슘 등을 보충해요',
  ),
  'men_health': ProductCategoryMeta(
    label: '남성 건강',
    benefit: '아연·셀레늄·쏘팔메토 등으로 남성 건강에 도움을 줘요',
  ),
  'pregnancy': ProductCategoryMeta(
    label: '임산부',
    benefit: '임신·수유 시 필요한 엽산·철분·DHA 등을 보충해요',
    cautions: ['반드시 산부인과 의사와 상의 후 복용'],
  ),
  'prenatal': ProductCategoryMeta(
    label: '임산부',
    benefit: '임신·수유 시 필요한 엽산·철분·DHA 등을 보충해요',
    cautions: ['반드시 산부인과 의사와 상의 후 복용'],
  ),
  'kids': ProductCategoryMeta(
    label: '어린이',
    benefit: '성장기 아이에게 필요한 비타민·미네랄을 보충해요',
  ),
  'kids_multivitamin': ProductCategoryMeta(
    label: '어린이 종합비타민',
    benefit: '성장기 아이에게 필요한 비타민·미네랄을 한 번에 보충해요',
  ),
  'kids_omega3': ProductCategoryMeta(
    label: '어린이 오메가-3',
    benefit: '뇌·눈 발달에 필요한 DHA를 보충해요',
  ),
  'kids_vitamin_d': ProductCategoryMeta(
    label: '어린이 비타민D',
    benefit: '성장기 뼈 건강과 면역에 도움을 줘요',
  ),
  'kids_korean_herbal': ProductCategoryMeta(
    label: '어린이 한방',
    benefit: '전통 한방 원리에 따라 조성된 어린이 영양 보충제예요',
    cautions: ['만성 질환·복용 약 있는 아이는 한의사와 상의'],
  ),
  'korean_herbal': ProductCategoryMeta(
    label: '한방',
    benefit: '전통 한방 원리에 따라 조성된 영양제예요',
    cautions: ['임산부 복용 전 한의사와 상의'],
  ),
  'ginseng': ProductCategoryMeta(
    label: '인삼·홍삼',
    benefit: '활력·면역·피로 회복에 도움을 줘요',
    cautions: ['고혈압·자가면역 질환자 의사와 상의'],
  ),
  'sports': ProductCategoryMeta(
    label: '스포츠',
    benefit: '운동 전·중·후 회복과 퍼포먼스에 도움을 줘요',
  ),
  'weight': ProductCategoryMeta(
    label: '체중 관리',
    benefit: '체중 관리 보조에 도움을 줄 수 있어요',
    cautions: ['균형 잡힌 식단·운동과 병행'],
  ),
  'superfood': ProductCategoryMeta(
    label: '슈퍼푸드',
    benefit: '스피루리나·클로렐라 등 영양 밀도가 높은 식품 보충제예요',
  ),
};

ProductCategoryMeta categoryMeta(String category) {
  return _kCategoryMeta[category] ?? _kFallback;
}
