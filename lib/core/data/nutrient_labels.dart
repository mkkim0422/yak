/// Centralised nutrient-key → Korean label mapping.
///
/// Keys come from `products.json` ingredient maps (e.g. `vitamin_d_iu`,
/// `omega3_total_mg`). Multiple keys (different units, synonyms) collapse
/// to a single user-facing label so the UI never shows raw enum text.
library;

const Map<String, String> _kBaseLabels = {
  // ── Vitamins ────────────────────────────────────────────────
  'vitamin_a': '비타민A',
  'vitamin_b1': '비타민B1',
  'vitamin_b2': '비타민B2',
  'vitamin_b3': '나이아신',
  'niacin': '나이아신',
  'vitamin_b5': '판토텐산',
  'pantothenic_acid': '판토텐산',
  'vitamin_b6': '비타민B6',
  'vitamin_b7': '비오틴',
  'biotin': '비오틴',
  'vitamin_b9': '엽산',
  'folate': '엽산',
  'folic_acid': '엽산',
  'vitamin_b12': '비타민B12',
  'vitamin_c': '비타민C',
  'vitamin_d': '비타민D',
  'vitamin_d3': '비타민D',
  'vitamin_e': '비타민E',
  'vitamin_k': '비타민K',
  'vitamin_k1': '비타민K',
  'vitamin_k2': '비타민K',
  'choline': '콜린',

  // ── Minerals ────────────────────────────────────────────────
  'calcium': '칼슘',
  'iron': '철분',
  'magnesium': '마그네슘',
  'zinc': '아연',
  'selenium': '셀레늄',
  'iodine': '요오드',
  'copper': '구리',
  'manganese': '망간',
  'chromium': '크롬',
  'molybdenum': '몰리브덴',
  'potassium': '칼륨',
  'phosphorus': '인',

  // ── Omega-3 / fatty acids ───────────────────────────────────
  'omega3_total': '오메가3',
  'omega3': '오메가3',
  'omega3_epa': 'EPA',
  'epa': 'EPA',
  'omega3_dha': 'DHA',
  'dha': 'DHA',
  'ala': 'ALA',

  // ── Antioxidants / functional ingredients ───────────────────
  'coenzyme_q10': '코엔자임Q10',
  'coq10': '코엔자임Q10',
  'lutein': '루테인',
  'zeaxanthin': '지아잔틴',
  'astaxanthin': '아스타잔틴',
  'resveratrol': '레스베라트롤',
  'curcumin': '커큐민',
  'milk_thistle': '밀크씨슬',
  'silymarin': '밀크씨슬',
  'lycopene': '라이코펜',

  // ── Probiotics / digestive ──────────────────────────────────
  'probiotics': '유산균',
  'fiber': '식이섬유',

  // ── Joint / connective tissue ───────────────────────────────
  'glucosamine': '글루코사민',
  'chondroitin': '콘드로이친',
  'msm': 'MSM',
  'collagen': '콜라겐',

  // ── Herbal ──────────────────────────────────────────────────
  'red_ginseng': '홍삼',
  'ginseng': '인삼',
  'ginkgo_biloba': '은행잎추출물',
  'ginkgo': '은행잎추출물',
  'saw_palmetto': '쏘팔메토',
  'ashwagandha': '아쉬와간다',
  'boswellia': '보스웰리아',
  'cranberry': '크랜베리',
  'propolis': '프로폴리스',

  // ── Amino acids / sport ─────────────────────────────────────
  'taurine': '타우린',
  'arginine': '아르기닌',
  'l_arginine': 'L-아르기닌',
  'theanine': '테아닌',
  'l_theanine': 'L-테아닌',
  'glutamine': '글루타민',
  'l_glutamine': 'L-글루타민',
  'creatine': '크레아틴',
  'protein': '단백질',
  'whey_protein': '유청 단백질',
  'bcaa': 'BCAA',
  'eaa': 'EAA',
  'aakg': 'AAKG',
  'beta_alanine': '베타알라닌',
  'citrulline': '시트룰린',
  'l_carnitine': '카르니틴',
  'carnitine': '카르니틴',

  // ── Sleep / stimulant ───────────────────────────────────────
  'melatonin': '멜라토닌',
  'caffeine': '카페인',
  'gaba': 'GABA',

  // ── Misc ────────────────────────────────────────────────────
  'spirulina': '스피루리나',
  'chlorella': '클로렐라',
  'krill_oil': '크릴오일',
  'mct_oil': 'MCT오일',
  'inositol': '이노시톨',
  'nac': 'NAC',
  '_5htp': '5-HTP',
  'htp_5': '5-HTP',
  'cla': 'CLA',
  'gla': '감마리놀렌산',
  'hca': 'HCA (가르시니아)',

  // ── Carotenoids / antioxidants (250 DB ingredient grep 보강) ─
  'beta_carotene': '베타카로틴',
  'alpha_lipoic_acid': '알파리포산',
  'anthocyanoside': '안토시아노사이드',
  'flavonoids': '플라보노이드',
  'flavonol_glycosides': '플라보놀 배당체',
  'chlorophyll': '엽록소',

  // ── Branched-chain amino acids + others ────────────────────
  'leucine': '류신',
  'isoleucine': '이소류신',
  'valine': '발린',
  'l_citrulline': 'L-시트룰린',

  // ── Probiotic CFU 변형 ────────────────────────────────────
  'guaranteed_cfu_billion': '보장균수',
  'label_cfu_billion': '표시균수',

  // ── Herbal extracts (한국 시장 흔한 라벨 표기) ────────────────
  'ginkgo_extract': '은행잎 추출물',
  'ginsenoside': '진세노사이드',
  'ginsenoside_mg_per': '진세노사이드 (g당)',
  'ginsenoside_rg1_rb1_rg3': '진세노사이드 Rg1+Rb1+Rg3',
  'evening_primrose_oil': '달맞이꽃 종자유',
  'maca_extract': '마카 추출물',
  'cranberry_extract': '크랜베리 추출물',
  'saw_palmetto_extract': '쏘팔메토 추출물',
  'saw_palmetto_lauric_acid': '쏘팔메토 라우르산',
  'boswellia_extract': '보스웰리아 추출물',
  'hovenia_extract': '헛개나무 추출물',
  'estrog100': '에스트로지100',

  // ── Other ─────────────────────────────────────────────────
  'collagen_peptide': '콜라겐 펩타이드',
  'phospholipid': '인지질',
  'octacosanol': '옥타코사놀',
  'piperine': '피페린',
  'heme_iron': '헴철',
  'dietary_fiber': '식이섬유',
};

/// Strip a trailing `_iu`, `_mg`, `_mcg`, `_g`, `_billion_cfu` suffix and
/// whatever the unit string was. Returns `(base, displayUnit)`.
const _kKnownUnits = <String>[
  'billion_cfu',
  'mcg',
  'mg',
  'iu',
  'g',
];

(String base, String unit) splitNutrientKey(String key) {
  final lc = key.toLowerCase();
  for (final u in _kKnownUnits) {
    if (lc.endsWith('_$u')) {
      return (
        lc.substring(0, lc.length - u.length - 1),
        _displayUnit(u),
      );
    }
  }
  return (lc, '');
}

String _displayUnit(String raw) {
  switch (raw) {
    case 'iu':
      return 'IU';
    case 'billion_cfu':
      return '억CFU';
    default:
      return raw;
  }
}

/// Returns the Korean label for a raw nutrient key. If we don't know the
/// key, returns the base (with underscores → spaces, title-cased).
String nutrientLabel(String key) {
  final (base, _) = splitNutrientKey(key);
  final mapped = _kBaseLabels[base];
  if (mapped != null) return mapped;
  return _humanize(base);
}

/// Returns the formatted `LABEL AMOUNT+UNIT` line for an ingredient row
/// (used by product cards, recommendation screens, etc.).
String formatIngredientLine(String key, double amount) {
  final (base, unit) = splitNutrientKey(key);
  final label = _kBaseLabels[base] ?? _humanize(base);
  final amountStr = _formatAmount(amount);
  if (unit.isEmpty) return '$label $amountStr';
  return '$label $amountStr$unit';
}

String _formatAmount(double amount) {
  if (amount >= 100 || amount == amount.roundToDouble()) {
    return amount.toStringAsFixed(0);
  }
  if (amount >= 10) return amount.toStringAsFixed(1);
  return amount.toStringAsFixed(2);
}

String _humanize(String base) {
  return base
      .split('_')
      .where((p) => p.isNotEmpty)
      .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
      .join(' ');
}
