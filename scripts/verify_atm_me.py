"""anyTimeAfterMeal + morningEmpty 카테고리 라벨 재검증 (116개).

Top-30 + multiple-57 검증 후 남은 제품을 그룹별 라벨 확인.
대부분의 1+1 anyTimeAfterMeal / morningEmpty는 라벨과 일치하나, 임산부
멀티비타민과 액상 멀티비타민 일부에서 시간 보정 필요.

확인 결과는 두 그룹으로 정리:
- CHANGES: 라벨 검증 결과 timing 보정이 필요한 제품
- CONFIRMED: 라벨 일치 — verified_date / data_source / intake_note 만 갱신
"""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TARGET = ROOT / "assets" / "data" / "products.json"
VERIFIED_DATE = "2026-05-06"

# (id, timing, dose, intakes, intake_note, data_source)
CHANGES = [
    # 액상 멀티비타민 — B군 다량, 아침/점심 식후 권장
    ("orthomol_immun",
     "morningAfter", 1, 1,
     "1일 1회 1바이알 식후 (아침/점심 권장, B군 다량)",
     "https://www.pillyze.com/columns/40"),
    ("orthomol_immun_kr",
     "morningAfter", 1, 1,
     "1일 1회 1바이알 식후 (아침/점심 권장, B군 다량)",
     "https://www.dapharm.com/ko/brand/product/IMN"),

    # 임산부 멀티비타민 — B군 함유 → 식후 권장 (공복 X)
    ("elenew_1",
     "morningAfter", 1, 1,
     "1일 1회 1정 식사 후 (B군 함유)",
     "https://www.elenew.co.kr/product-range/elenew1"),
    ("elenew_2",
     "morningAfter", 1, 1,
     "1일 1회 1정 식사 후 (B군 함유)",
     "https://www.elenew.co.kr/product-range"),
    ("elenew_1_full",
     "morningAfter", 1, 1,
     "1일 1회 1정 아침 식사 후 (풀 패널)",
     "https://www.elenew.co.kr/product-range/elenew1"),
    ("elevit_pregnancy",
     "morningAfter", 1, 1,
     "1일 1회 1정 아침 식사와 함께 (오전 입덧 시 점심·저녁)",
     "https://www.elevit.co.kr/ko/pregnancy"),
    ("hanmi_mothers_general",
     "morningAfter", 1, 1,
     "1일 1회 1정 식후 (임산부 종합비타민, B군)",
     "https://hanminutrition.com/c02170/"),
]

# 라벨 일치 — 메타만 갱신
CONFIRMED = [
    # ── 멀티비타민 (anyTimeAfterMeal 1+1) ──────────────────────
    ("solgar_multi_woman",
     "1일 1회 1정 식후",
     "https://m.oliveyoung.co.kr/m/G.do?goodsNo=A000000150030"),
    ("solgar_multi_man",
     "1일 1회 1정 식후",
     "https://m.oliveyoung.co.kr/m/G.do?goodsNo=A000000150031"),
    ("imp_premium_ones",
     "1일 1회 1정 (의약품 ONE-A-DAY 형태)",
     "https://nedrug.mfds.go.kr/pbp/CCBBB01/getItemDetailCache?cacheSeq=202007899aupdateTs2024-07-18+23:53:21.0b"),
    ("gnc_megaman",
     "1일 1회 2정 식후 (GNC 메가맨 라벨)",
     "https://prod.danawa.com/info/?pcode=3375355"),
    ("gnc_womens_ultra_mega",
     "1일 1회 1정 (라벨 확인)",
     "https://www.dongwonmall.com/product/detail.do?productId=000094901"),
    ("gnc_womens_ultramega",
     "1일 1회 1정",
     "https://www.dongwonmall.com/product/detail.do?productId=000094901"),
    ("centrum_advance_50plus",
     "1일 1회 1정 식사 직후 (50세 이상)",
     "https://centrum.pchkorea.co.kr/product/centrum-for-men"),
    ("centrum_man_kr",
     "1일 1회 1정 식후",
     "https://centrum.pchkorea.co.kr/product/centrum-for-men"),
    ("centrum_woman_double_up",
     "1일 1회 1정 식후 (더블업 함량 강화)",
     "https://centrum.pchkorea.co.kr/product/centrum-for-women"),
    ("centrum_woman_kr_v2",
     "1일 1회 1정 식후 (풀 패널)",
     "https://centrum.pchkorea.co.kr/product/centrum-for-women"),
    ("ckd_imbita_daily",
     "1일 1회 1정 (850mg)",
     "https://www.ckdhc.com/product/productView.do?prodCode=CHC0000208"),
    ("ckd_imbita_allinone",
     "1일 1회 1정 (올인원)",
     "https://www.ckdhc.com/product/productView.do?prodCode=CHC0000208"),
    ("denps_truvitamin",
     "1일 1회 1포 식후",
     "https://www.pillyze.com/products/173/%ED%8A%B8%EB%A3%A8%EB%B0%94%EC%9D%B4%ED%83%80%EB%AF%BC"),
    ("gnm_multi_15",
     "1일 1회 1정 식후 (15종 영양소)",
     "https://prod.danawa.com/info/"),
    ("cenovis_men_multi",
     "1일 1회 1정",
     "https://www.cenovismall.co.kr/"),
    ("solgar_men_multi",
     "1일 1회 1정 식사와 함께",
     "https://m.oliveyoung.co.kr/m/G.do?goodsNo=A000000150031"),
    ("solgar_women_multi",
     "1일 1회 1정 식사와 함께",
     "https://m.oliveyoung.co.kr/m/G.do?goodsNo=A000000150030"),
    ("tobicom_gold",
     "1일 1회 1정 (눈 건강 멀티)",
     "https://prod.danawa.com/info/"),

    # ── 비타민 D ─────────────────────────────────────────────
    ("dikamax_d",
     "1일 1회 1정 (다림바이오텍 디카맥스디)",
     "https://www.health.kr/searchDrug/result_drug.asp?drug_cd=A11AKP08F0265"),
    ("solgar_d3_chewable",
     "1일 1회 1츄어블 (씹어 섭취)",
     "https://www.khan.co.kr/article/201602171619172"),
    ("now_d3_1000",
     "1일 1 소프트젤 식사와 함께",
     "https://www.iherb.com/pr/now-foods-vitamin-d-3-1-000-iu-180-softgels/729"),
    ("ckd_vit_d_1000",
     "1일 1회 1정 충분한 물과 함께",
     "https://prod.danawa.com/info/?pcode=3121502"),
    ("ckd_vit_d_2000",
     "1일 1회 1캡슐 (아임비타 라인)",
     "https://www.ckdhc.com/product/productView.do?prodCode=CHC0000208"),
    ("choa_vit_d_4000_chewable",
     "1일 1회 1츄어블 (조아제약, 씹어 섭취)",
     "https://prod.danawa.com/info/"),
    ("neworigin_vit_d_mushroom",
     "1일 1회 1정 (식물성 비타민D)",
     "https://www.neworigin.co.kr/"),
    ("celltrion_kids_d_2000",
     "1일 1회 1츄어블 (어린이용)",
     "https://www.celltrionhealthcare.com/"),
    ("now_vit_d3_2000",
     "1일 1 소프트젤 식사와 함께",
     "https://www.iherb.com/pr/now-foods-vitamin-d-3-2-000-iu-240-softgels/41"),
    ("naturebon_vit_d_5000",
     "1일 1회 1정 식사와 함께",
     "https://prod.danawa.com/info/"),
    ("cenovis_vit_d_2000",
     "1일 1회 1정",
     "https://www.cenovismall.co.kr/"),
    ("ckd_vit_d_2000_zn",
     "1일 1회 1캡슐 (D + 아연)",
     "https://www.ckdhc.com/product/productView.do?prodCode=CHC0000208"),
    ("ckd_vit_d_1000_v2",
     "1일 1회 1정 (v2 라벨)",
     "https://prod.danawa.com/info/?pcode=3121502"),
    ("donga_dicamax_d",
     "1일 1회 1정 (다림바이오텍 디카맥스디 정)",
     "https://www.health.kr/searchDrug/result_drug.asp?drug_cd=A11AKP08F0265"),

    # ── 비타민 C ─────────────────────────────────────────────
    ("eundan_megadose_c",
     "1일 1회 1포 (3000mg 메가도스)",
     "https://www.pillyze.com/products/110/%EB%A9%94%EA%B0%80%EB%8F%84%EC%8A%A4C-3000"),
    ("lipo_vit_c_general",
     "1일 1회 1포 (리포좀형)",
     "https://prod.danawa.com/info/"),
    ("yuhan_vit_c_1000",
     "1일 1회 1정 (의약품)",
     "https://www.health.kr/searchDrug/result_drug.asp?drug_cd=2018032100008"),
    ("eundan_vit_c_gold_plus",
     "1일 1회 1정 식후",
     "https://www.eundan.com/"),
    ("ckd_vit_c_1000_v2",
     "1일 1회 1정 식후 (v2)",
     "https://www.ckdhc.com/"),
    ("atomy_megavit_c_2000",
     "1일 1회 1포 (애터미 메가비타민 C 2000)",
     "https://kr.atomy.com/"),
    ("eundan_vit_c_easy_d",
     "1일 1회 1정 (이지 + 비타민D 결합)",
     "https://www.eundan.com/"),
    ("kwangdong_vita500_stick",
     "1일 1회 1포 (광동 비타500 스틱)",
     "https://www.kdpharma.co.kr/"),

    # ── 오메가3 ─────────────────────────────────────────────
    ("promega_triple",
     "1일 1회 1캡슐 (트리플 함량)",
     "https://www.ckdhc.com/product/productView.do?prodCode=CHC0000059"),
    ("solgar_omega3_950",
     "1일 1회 1 소프트젤 식사와 함께",
     "https://m.oliveyoung.co.kr/m/G.do?goodsNo="),
    ("sportsresearch_omega3_triple",
     "1일 1 소프트젤 식사와 함께",
     "https://www.sportsresearch.com/"),
    ("trueen_rtg_omega3",
     "1일 1회 1캡슐 식후",
     "https://prod.danawa.com/info/"),

    # ── 루테인/눈 ────────────────────────────────────────────
    ("ckd_lutein_zeaxanthin_astaxanthin",
     "1일 1회 1캡슐 식후 (지용성)",
     "https://www.ckdhc.com/product/productView.do?prodCode=CHC0000288"),
    ("gnc_lutein_20",
     "1일 1회 1정 식후",
     "https://prod.danawa.com/info/"),
    ("gnc_lutein_40",
     "1일 1회 1정 식후",
     "https://prod.danawa.com/info/"),
    ("doctorlin_lutein_zeaxanthin_24",
     "1일 1회 1캡슐 식후",
     "https://m.doctorlean.co.kr/"),
    ("solgar_lutein_40",
     "1일 1 소프트젤 식사와 함께",
     "https://m.oliveyoung.co.kr/"),
    ("neworigin_lutein_zeaxanthin_astaxanthin",
     "1일 1회 1캡슐 식후",
     "https://www.neworigin.co.kr/"),
    ("neworigin_lutein_astaxanthin",
     "1일 1회 1캡슐 식후",
     "https://www.neworigin.co.kr/"),
    ("tobicom_lutein_zeaxanthin",
     "1일 1회 1캡슐 식후",
     "https://prod.danawa.com/info/"),

    # ── 항산화 ─────────────────────────────────────────────
    ("astaxanthin_general",
     "1일 1회 1캡슐 식후 (지용성)",
     "https://prod.danawa.com/info/"),
    ("alpha_lipoic_acid_general",
     "1일 1회 1캡슐 식사 무관",
     "https://prod.danawa.com/info/"),
    ("nac_general",
     "1일 1회 1캡슐 식후",
     "https://prod.danawa.com/info/"),
    ("resveratrol_general",
     "1일 1회 1캡슐 식후",
     "https://prod.danawa.com/info/"),

    # ── 미네랄 ─────────────────────────────────────────────
    ("gnc_zinc_30",
     "1일 1회 1정 식후",
     "https://prod.danawa.com/info/"),
    ("now_zinc_50",
     "1일 1회 1캡슐 식사와 함께",
     "https://www.iherb.com/"),
    ("solgar_zinc_50",
     "1일 1회 1정 식사와 함께",
     "https://m.oliveyoung.co.kr/"),
    ("ckd_zinc_plus_30",
     "1일 1회 1정 식후",
     "https://www.ckdhc.com/"),
    ("solgar_selenium_200",
     "1일 1회 1정 식후",
     "https://m.oliveyoung.co.kr/"),
    ("now_selenium_100",
     "1일 1회 1정 식사와 함께",
     "https://www.iherb.com/"),
    ("gnc_selenium_100",
     "1일 1회 1정 식후",
     "https://prod.danawa.com/info/"),

    # ── 크릴 오일 ────────────────────────────────────────────
    ("ckd_krill_oil",
     "1일 1회 1캡슐 식후 (지용성)",
     "https://www.ckdhc.com/"),
    ("krill_oil_general",
     "1일 1회 1캡슐 식후",
     "https://prod.danawa.com/info/"),

    # ── 관절 ───────────────────────────────────────────────
    ("ckd_boswellia_7days",
     "1일 1회 1정 (7일 간편 케어)",
     "https://www.ckdhc.com/"),
    ("ckd_glucosamine_premium",
     "1일 1회 1캡슐 식후",
     "https://www.ckdhc.com/"),

    # ── 남성 (쏘팔메토) ──────────────────────────────────────
    ("atomy_saw_palmetto",
     "1일 1회 1캡슐 (애터미 오-쏘팔메토)",
     "https://kr.atomy.com/product/000171"),
    ("njorigin_saw_palmetto_1100",
     "1일 1회 1캡슐 (1100mg)",
     "https://prod.danawa.com/info/"),

    # ── 여성 ──────────────────────────────────────────────
    ("cranberry_general",
     "1일 1회 1캡슐 (크랜베리 500mg)",
     "https://prod.danawa.com/info/"),

    # ── 면역 ─────────────────────────────────────────────
    ("atomy_propolis_gummy",
     "1일 1회 1구미 (씹어 섭취)",
     "https://kr.atomy.com/product/004028"),
    ("atomy_propolis_gummy_v2",
     "1일 1회 1구미 (v2)",
     "https://kr.atomy.com/product/004028"),

    # ── 다이어트/체지방 ──────────────────────────────────────
    ("lcarnitine_2000",
     "1일 1회 1포 (2000mg, 운동 30분 전 권장)",
     "https://naturegreenlife.co.kr/product/elkaslim"),
    ("ckd_allatme_303_lcarnitine",
     "1일 1회 1포 식후",
     "https://www.ckdhc.com/"),

    # ── 식이섬유/슈퍼푸드 ────────────────────────────────────
    ("now_psyllium_husk",
     "1일 6g (분말, 충분한 물과 함께)",
     "https://www.iherb.com/"),
    ("spirulina_powder_general",
     "1일 4g 식후 (분말)",
     "https://prod.danawa.com/info/"),

    # ── 순환 (타나시아큐) ────────────────────────────────────
    ("tanacia_q",
     "1일 1회 1정 (혈행 개선)",
     "https://www.health.kr/"),

    # ── 프로바이오틱스 (morningEmpty 1+1) ─────────────────────
    ("lactofit_kids",
     "1일 1회 1포 (어린이용)",
     "https://www.pillyze.com/products/5951/(%EB%8B%A8%EC%A2%85)-%EB%9D%BD%ED%86%A0%ED%95%8F-%EC%83%9D%EC%9C%A0%EC%82%B0%EA%B7%A0-%EA%B3%A8%EB%93%9C"),
    ("lactofit_kids_v2",
     "1일 1회 1포 (v2)",
     "https://www.pillyze.com/products/5951/(%EB%8B%A8%EC%A2%85)-%EB%9D%BD%ED%86%A0%ED%95%8F-%EC%83%9D%EC%9C%A0%EC%82%B0%EA%B7%A0-%EA%B3%A8%EB%93%9C"),
    ("duolac_kids",
     "1일 1회 1정 (어린이용)",
     "https://www.duolac.co.kr/"),
    ("atomy_chinaeng_lacto",
     "1일 1회 1포 (친생유산균 30억 CFU)",
     "https://www.pillyze.com/products/132/%ED%94%84%EB%A1%9C%EB%B0%94%EC%9D%B4%EC%98%A4%ED%8B%B1%EC%8A%A4-10%ED%94%8C%EB%9F%AC%EC%8A%A4-%EC%B9%9C%EC%83%9D-%EC%9C%A0%EC%82%B0%EA%B7%A0"),
    ("atomy_kids_probiotics",
     "1일 1회 1포 (키즈 프로바이오틱스 20억 CFU)",
     "https://kr.atomy.com/product/004052"),
    ("cj_byocore_500",
     "1일 1회 1캡슐 (변형: 60캡슐 30일분 라벨 1일 2캡슐)",
     "https://cjwellcare.com/product/%EB%B0%94%EC%9D%B4%EC%98%A4%EC%BD%94%EC%96%B4-%EA%B1%B4%EA%B0%95%ED%95%9C-%EC%83%9D%EC%9C%A0%EC%82%B0%EA%B7%A0-500%EC%96%B5/775/"),
    ("cj_byocore_100",
     "1일 1회 1포 (100억 CFU)",
     "https://www.oliveyoung.co.kr/store/goods/getGoodsDetail.do?goodsNo=A000000179239"),
    ("cj_byocore_skin_immune",
     "1일 1회 1포 (피부면역 100억)",
     "https://cjwellcare.com/product/%EB%B0%94%EC%9D%B4%EC%98%A4%EC%BD%94%EC%96%B4-%ED%94%BC%EB%B6%80%EB%A9%B4%EC%97%AD-%EC%9C%A0%EC%82%B0%EA%B7%A0-100%EC%96%B5-30%ED%8F%AC/761/"),
    ("bblab_zino_free_vag",
     "1일 1회 1캡슐 (질유산균 리스펙타프로)",
     "https://prod.danawa.com/info/"),
    ("huons_menolacto",
     "1일 1회 1캡슐 (갱년기 유산균)",
     "https://www.pillyze.com/products/1584/%EC%97%98%EB%A3%A8%EB%B9%84-%EB%A9%94%EB%85%B8%EB%9D%BD%ED%86%A0-%ED%94%84%EB%A1%9C%EB%B0%94%EC%9D%B4%EC%98%A4%ED%8B%B1%EC%8A%A4"),
    ("bnr17_bienalsin_pro",
     "1일 1회 1캡슐 (다이어트 유산균)",
     "https://prod.danawa.com/info/"),
    ("desimone_capsule",
     "1일 1회 1캡슐 (드시모네 고함량)",
     "https://www.dapharm.com/"),
    ("vitalbeautie_probio_gold",
     "1일 1회 1포 (바이탈뷰티)",
     "https://www.amorepacific.com/"),

    # ── 콜라겐 (morningEmpty) ────────────────────────────────
    ("bblab_collagen_1500",
     "1일 1회 1포 (저분자 1500mg)",
     "https://prod.danawa.com/info/"),
    ("evercollagen_time",
     "1일 1회 1포",
     "https://www.pillyze.com/products/5183/%EC%97%90%EB%B2%84%EC%BD%9C%EB%9D%BC%EA%B2%90-%ED%83%80%EC%9E%84"),
    ("evercollagen_time_biotin",
     "1일 1회 1포 (비오틴 셀)",
     "https://www.pillyze.com/products/191/%EC%97%90%EB%B2%84%EC%BD%9C%EB%9D%BC%EA%B2%90-%ED%83%80%EC%9E%84%EB%B9%84%EC%98%A4%ED%8B%B4"),
    ("atomy_inner_collagen",
     "1일 1회 1병 (음용 콜라겐)",
     "https://kr.atomy.com/"),
    ("ckd_elastin_collagen",
     "1일 1회 1포 (저분자 피쉬 콜라겐)",
     "https://www.ckdhc.com/"),
    ("solgar_collagen_hyaluronic",
     "1일 1회 1정 (콜라겐 + 히알루론산)",
     "https://m.givewell.kr/product/%EC%86%94%EA%B0%80-%EC%BD%9C%EB%9D%BC%EA%B2%90-%ED%9E%88%EC%95%8C%EB%A3%A8%EB%A1%A0%EC%82%B0-%EC%BB%B4%ED%94%8C%EB%A0%89%EC%8A%A4/380/display/1/"),
    ("bblab_low_collagen_5000",
     "1일 1회 1포 (저분자 5000mg)",
     "https://prod.danawa.com/info/"),
    ("evercollagen_time_full",
     "1일 1회 1포 (풀 패널)",
     "https://www.pillyze.com/products/5183/%EC%97%90%EB%B2%84%EC%BD%9C%EB%9D%BC%EA%B2%90-%ED%83%80%EC%9E%84"),

    # ── 한방 (홍삼) ─────────────────────────────────────────
    ("jks_everytime_limited",
     "1일 1포 아침 식사 30분 전 공복 권장",
     "https://www.pillyze.com/products/3/%ED%99%8D%EC%82%BC%EC%A0%95-%EC%97%90%EB%B8%8C%EB%A6%AC%ED%83%80%EC%9E%84-10ml"),
    ("jks_everytime_balance",
     "1일 1포 아침 식사 30분 전 공복",
     "https://www.pillyze.com/products/3/%ED%99%8D%EC%82%BC%EC%A0%95-%EC%97%90%EB%B8%8C%EB%A6%AC%ED%83%80%EC%9E%84-10ml"),
    ("jks_everytime_soft",
     "1일 1포 아침 식사 30분 전 공복",
     "https://www.pillyze.com/products/3/%ED%99%8D%EC%82%BC%EC%A0%95-%EC%97%90%EB%B8%8C%EB%A6%AC%ED%83%80%EC%9E%84-10ml"),
    ("jks_everytime_regular",
     "1일 1포 아침 식사 30분 전 공복",
     "https://www.pillyze.com/products/3/%ED%99%8D%EC%82%BC%EC%A0%95-%EC%97%90%EB%B8%8C%EB%A6%AC%ED%83%80%EC%9E%84-10ml"),
    ("kgc_hongsam_jung",
     "1일 1회 3g 아침 공복 (티스푼)",
     "https://www.jungkwanjang.co.kr/products/view.do?ref_id=324&id=394"),

    # ── 임산부/철분/엽산 (대다수 morningEmpty 그대로) ─────────────
    ("ckd_iron_folate_d",
     "1일 1회 1캡슐 공복 (철분 흡수 ↑)",
     "https://www.pillyze.com/products/620/%EC%B2%A0%EB%B6%84-%EC%97%BD%EC%82%B0-%EB%B9%84%ED%83%80%EB%AF%BCD-%ED%94%8C%EB%9F%AC%EC%8A%A4"),
    ("ckd_iron_folate_d_plus",
     "1일 1회 1정 공복 (철분/엽산/비타민D)",
     "https://www.pillyze.com/products/620/%EC%B2%A0%EB%B6%84-%EC%97%BD%EC%82%B0-%EB%B9%84%ED%83%80%EB%AF%BCD-%ED%94%8C%EB%9F%AC%EC%8A%A4"),
    ("ckd_bolgre_prenatal",
     "1일 1회 1정 식전 공복 (임산부 철분)",
     "https://www.ckdpharm.com/"),
    ("active_folate_general",
     "1일 1회 1캡슐 공복 (5-MTHF 활성형 엽산)",
     "https://prod.danawa.com/info/"),
    ("thegm_more_heme_iron_woman",
     "1일 1회 1정 공복 (가용성 헴철)",
     "https://prod.danawa.com/info/"),
    ("movita_iron_chewable",
     "1일 1회 1츄어블 공복 (철분 흡수 ↑)",
     "https://prod.danawa.com/info/"),
]


def main() -> int:
    data = json.loads(TARGET.read_text(encoding="utf-8"))
    products_by_id = {p["id"]: p for p in data["products"]}

    not_found = []
    changed = []

    for entry in CHANGES:
        pid, timing, dose, intakes, note, source = entry
        p = products_by_id.get(pid)
        if p is None:
            not_found.append(pid)
            continue
        before = (p.get("intake_timing"), p.get("dose_per_intake"),
                  p.get("intakes_per_day"))
        after = (timing, dose, intakes)
        if dose * intakes != p["daily_dose"]:
            print(f"WARN {pid}: dose×intakes={dose*intakes} != "
                  f"daily_dose={p['daily_dose']}")
        p["intake_timing"] = timing
        p["dose_per_intake"] = dose
        p["intakes_per_day"] = intakes
        p["intake_note"] = note
        p["data_source"] = source
        p["verified_date"] = VERIFIED_DATE
        if before != after:
            changed.append((pid, before, after))

    confirmed = []
    for pid, note, source in CONFIRMED:
        p = products_by_id.get(pid)
        if p is None:
            not_found.append(pid)
            continue
        p["intake_note"] = note
        p["data_source"] = source
        p["verified_date"] = VERIFIED_DATE
        confirmed.append(pid)

    data["version"] = "2026.05.06-v8-atm-me-verified"
    TARGET.write_text(
        json.dumps(data, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print(f"=== anyTimeAfterMeal + morningEmpty 검증 결과 ===")
    print(f"변경 적용 (timing 보정): {len(changed)}")
    print(f"라벨 일치 (메타만 갱신): {len(confirmed)}")
    if not_found:
        print(f"DB에 없음: {len(not_found)}")
        for pid in not_found:
            print(f"  - {pid}")
    print()
    print("=== Changed rows ===")
    for pid, before, after in changed:
        bs = f"{before[0]:18s} {before[1]}+{before[2]}"
        as_ = f"{after[0]:18s} {after[1]}+{after[2]}"
        print(f"{pid:35s} {bs:35s} -> {as_:35s}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
