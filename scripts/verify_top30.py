"""Top-30 product label re-verification.

Each entry below was confirmed via web search/fetch (search engines + brand
sites + 약학정보원). When the label reading differs from the category-rule
default produced by `add_intake_fields.py`, the value here overrides it.

Sources are recorded inline; the report script prints them.
"""

from __future__ import annotations

import json
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TARGET = ROOT / "assets" / "data" / "products.json"

VERIFIED_DATE = "2026-05-06"

# (actual_id, requested_id, timing, dose_per_intake, intakes_per_day,
#  intake_note, data_source URL)
VERIFIED = [
    # ── Multivitamin (5) ─────────────────────────────────────────────
    ("centrum_woman", "centrum_woman",
     "anyTimeAfterMeal", 1, 1,
     "오전중 식후 1정 (만 12세 이상 여성)",
     "https://www.health.kr/searchDrug/result_drug.asp?drug_cd=A11AOOOOO0627"),
    ("centrum_man", "centrum_man",
     "anyTimeAfterMeal", 1, 1,
     "식후 30분 이내, 아침 또는 점심 권장",
     "https://centrum.pchkorea.co.kr/product/centrum-for-men"),
    ("centrum_silver_man", "centrum_silver_man",
     "anyTimeAfterMeal", 1, 1,
     "식사 직후 1정",
     "https://www.pillyze.com/products/484/%EC%8B%A4%EB%B2%84-%EB%A7%A8-50+"),
    ("imp_premium", "impactamin_premium",
     "multiple", 1, 2,
     "1일 1회 2정 또는 1일 2회 1정씩 (의약품)",
     "https://nedrug.mfds.go.kr/pbp/CCBBB01/getItemDetail?itemSeq=201102450"),
    ("gnc_megamen", "gnc_megamen",
     "anyTimeAfterMeal", 2, 1,
     "1일 1회 2정 식후 (남성용)",
     "https://prod.danawa.com/info/?pcode=3375355"),

    # ── Vitamin D (3) ────────────────────────────────────────────────
    ("dikamax_1000", "dikamax_1000",
     "anyTimeAfterMeal", 1, 1,
     "1일 1회 1정 (만 8세 이상, 의약품 - 약학정보원)",
     "https://www.health.kr/searchDrug/result_drug.asp?drug_cd=A11AOOOOO6432"),
    ("solgar_d3_1000", "solgar_d3_1000",
     "withMeal", 1, 1,
     "매일 1정을 식사와 함께",
     "https://www.greating.co.kr/market/marketDetail?itemId=147720"),
    ("solgar_d3_5000", "solgar_d3_5000",
     "withMeal", 1, 1,
     "매일 1캡슐을 가급적 식사와 함께",
     "https://www.vitatra.com/product/detail/42091"),

    # ── Vitamin C (2) ────────────────────────────────────────────────
    ("ckd_vit_c_1000", "ckd_c_1000",
     "anyTimeAfterMeal", 1, 1,
     "1일 1회 1정 식후 (공복 시 위장 자극 가능)",
     "https://prod.danawa.com/info/?pcode=4280991"),
    ("eundan_vit_c_1000", "koreaeundan_c_1000",
     "anyTimeAfterMeal", 1, 1,
     "1일 1회 1정 식후 (공복 섭취 시 설사 가능)",
     "https://www.eundan.com/bbs_detail.php?bbs_num=160&tb=board_free&menu_number=470"),

    # ── Omega3 (3) ───────────────────────────────────────────────────
    # Spec note: products labelled "1일 1회 2캡슐" are 2+1, not 1+2 split.
    ("promega_dual", "ckd_promega_dual",
     "morningAfter", 2, 1,
     "오전중 식후 2캡슐 (1일 1회)",
     "https://www.ckdhc.com/product/productView.do?prodCode=CHC0000059"),
    ("nordic_ultimate_omega", "nordic_omega3_ultimate",
     "anyTimeAfterMeal", 2, 1,
     "1일 2 소프트젤 식사와 함께",
     "https://www.nordic.com/products/ultimate-omega/"),
    ("atomy_rtg_omega3", "atomy_omega3",
     "anyTimeAfterMeal", 2, 1,
     "1일 1회 2캡슐 식후 (지용성)",
     "https://kr.atomy.com/product/004041"),

    # ── Probiotics (3) ───────────────────────────────────────────────
    ("lactofit_gold", "lactofit_gold",
     "morningEmpty", 1, 1,
     "1일 1회 1포 식전·식후 무관, 아침 공복 권장",
     "https://www.pillyze.com/products/5951/(%EB%8B%A8%EC%A2%85)-%EB%9D%BD%ED%86%A0%ED%95%8F-%EC%83%9D%EC%9C%A0%EC%82%B0%EA%B7%A0-%EA%B3%A8%EB%93%9C"),
    ("lactofit_core", "lactofit_core",
     "morningEmpty", 1, 1,
     "1일 1회 1포 아침 식전 권장",
     "https://www.pillyze.com/products/17969/%EB%9D%BD%ED%86%A0%ED%95%8F-%EC%83%9D%EC%9C%A0%EC%82%B0%EA%B7%A0-%EC%BD%94%EC%96%B4%EB%A7%A5%EC%8A%A4"),
    ("duolac_gold", "duolac_gold",
     "multiple", 1, 2,
     "1일 2포 아침/저녁 식후 (분말형)",
     "https://www.duolac.co.kr/gd/prdDtlView.do?pdtCd=NP00000815"),

    # ── Magnesium (2) ────────────────────────────────────────────────
    ("solgar_mg_citrate", "solgar_magnesium_citrate",
     "dinnerAfter", 2, 1,
     "1일 1회 2정 저녁 식후",
     "https://www.pillyze.com/products/9747/%EB%A7%88%EA%B7%B8%EB%84%A4%EC%8A%98-%EC%8B%9C%ED%8A%B8%EB%A0%88%EC%9D%B4%ED%8A%B8"),
    ("solgar_mg_b6", "solgar_magnesium_b6",
     "multiple", 1, 3,
     "1일 3회 1정 또는 1일 1회 3정, 식사 직후",
     "https://www.pillyze.com/products/9561/%EB%A7%88%EA%B7%B8%EB%84%A4%EC%8A%98-%EC%9C%84%EB%93%9C-%EB%B9%84%ED%83%80%EB%AF%BCB6-(%ED%95%B4%EC%99%B8)"),

    # ── Calcium (1) ──────────────────────────────────────────────────
    ("oscal_calcium_d", "oscal",
     "multiple", 1, 2,
     "1일 2정 식후 (분복 권장)",
     "https://prod.danawa.com/info/?pcode=6352198"),

    # ── Lutein (2) ───────────────────────────────────────────────────
    ("hurum_lutein", "hurum_lutein",
     "anyTimeAfterMeal", 1, 1,
     "1일 1캡슐 식후 (지용성)",
     "https://www.costco.co.kr/HealthSupplement/Other-Health-Supplement/Vision-Support-Supplements/Hurum-Lutein-Zeaxanthin-500mg-x-30-x-3/p/625438"),
    ("ckd_eyeclear_lutein_zea", "ckd_iclear_lutein",
     "morningAfter", 1, 1,
     "오전중 식후 1캡슐",
     "https://www.ckdhc.com/product/productView.do?category=CKD_CATE00000024&prodCode=CHC0000288"),

    # ── CoQ10 (1) ────────────────────────────────────────────────────
    ("ckd_coq10_plus_30", "ckd_coq10_plus",
     "morningAfter", 1, 1,
     "아침 식후 1캡슐 (지용성, 에너지 생성 보조)",
     "https://www.pillyze.com/columns/13"),

    # ── Milk Thistle (2) ─────────────────────────────────────────────
    ("ckd_milk_thistle", "ckd_milkthistle",
     "dinnerAfter", 1, 1,
     "1일 1회 1정 저녁 식사 직후",
     "https://www.pillyze.com/columns/11"),
    ("solgar_milk_thistle_300", "solgar_milkthistle",
     "dinnerAfter", 1, 1,
     "1일 1회 1캡슐 저녁 식후",
     "https://www.pillyze.com/products/1676/%EB%B0%80%ED%81%AC%EC%94%A8%EC%8A%AC"),

    # ── Pregnancy (1) ────────────────────────────────────────────────
    ("elevit", "elevit",
     "morningAfter", 1, 1,
     "1일 1회 1정 아침 식사와 함께 (오전 입덧 시 점심·저녁 가능)",
     "https://www.elevit.co.kr/ko/pregnancy"),

    # ── Circulation / Ginkgo (1) ─────────────────────────────────────
    ("ginexin_f_80", "ginkgo_80",
     "multiple", 1, 2,
     "1회 80mg 1일 2회 (식사 무관)",
     "https://www.health.kr/searchDrug/result_drug.asp?drug_cd=A11A1890B0008"),

    # ── Menopause (1) ────────────────────────────────────────────────
    ("estrog100", "estrog_100",
     "multiple", 1, 2,
     "1일 2정 (라벨 확인 필요 - 제조사별 상이)",
     "https://www.naturalendo.co.kr/default/product/product_1.php?tit=03&sub=01"),

    # ── Sleep (1) ────────────────────────────────────────────────────
    ("doctorlin_melavine", "dr_lin_melavine",
     "beforeSleep", 1, 1,
     "취침 30분~1시간 전 1정",
     "https://m.doctorlean.co.kr/goods/view?no=385"),

    # ── Korean herbal (1) ────────────────────────────────────────────
    ("jks_red_ginseng_extract", "jungkwanjang_red_ginseng",
     "morningEmpty", 3, 1,
     "1일 1회 3g, 아침 공복 (티스푼 사용)",
     "https://www.jungkwanjang.co.kr/products/view.do?ref_id=324&id=394"),

    # ── Immunity (1) ─────────────────────────────────────────────────
    ("atomy_hemohim", "atomy_hemohim",
     "multiple", 1, 2,
     "1일 2포 (아침 1포 + 저녁 1포) 식전·식후 무관",
     "https://kr.atomy.com/product/000011"),
]


def main() -> int:
    data = json.loads(TARGET.read_text(encoding="utf-8"))
    products_by_id = {p["id"]: p for p in data["products"]}

    diffs = []
    not_found = []
    for entry in VERIFIED:
        pid, req_id, timing, dose, intakes, note, source = entry
        p = products_by_id.get(pid)
        if p is None:
            not_found.append((req_id, pid))
            continue

        before = (p.get("intake_timing"), p.get("dose_per_intake"),
                  p.get("intakes_per_day"))
        after = (timing, dose, intakes)

        # Verify daily_dose invariant
        if dose * intakes != p["daily_dose"]:
            print(f"WARN {pid}: dose×intakes ({dose}×{intakes}={dose*intakes}) "
                  f"!= daily_dose ({p['daily_dose']}) — leaving daily_dose alone")

        p["intake_timing"] = timing
        p["dose_per_intake"] = dose
        p["intakes_per_day"] = intakes
        p["intake_note"] = note
        p["data_source"] = source
        p["verified_date"] = VERIFIED_DATE

        diffs.append((pid, req_id, before, after))

    # Bump version
    data["version"] = "2026.05.06-v6-top30-verified"

    TARGET.write_text(
        json.dumps(data, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    # Stats / report
    changed = []
    same = []
    for pid, req_id, before, after in diffs:
        if before == after:
            same.append((pid, req_id))
        else:
            changed.append((pid, req_id, before, after))

    print(f"=== Top-30 verification report ===")
    print(f"verified : {len(diffs)} / 30")
    print(f"matched  : {len(same)}")
    print(f"changed  : {len(changed)}")
    if not_found:
        print(f"not_found: {len(not_found)} (skipped)")
        for req, pid in not_found:
            print(f"  - {req:30s} -> {pid} (no row in DB)")
    print()
    print("=== Changed rows ===")
    print(f"{'id':30s} {'before':35s} -> {'after':35s}")
    for pid, req_id, before, after in changed:
        bs = f"{before[0]:18s} {before[1]}+{before[2]}"
        as_ = f"{after[0]:18s} {after[1]}+{after[2]}"
        print(f"{pid:30s} {bs:35s} -> {as_:35s}  ({req_id})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
