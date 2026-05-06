"""multiple-timing 재검증 (1+N 분복 vs N+1 통합).

`add_intake_fields.py`가 daily_dose>=2 제품을 자동으로 1+N 분복으로 처리한 결과
실제 라벨이 "1일 1회 N정" (= N+1 통합) 인 제품 다수 발견.
이 스크립트는 라벨/약학정보원 web 검증으로 확인된 차이만 반영한다.

Top-30 검증에서 이미 처리된 제품은 건드리지 않는다.
"""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TARGET = ROOT / "assets" / "data" / "products.json"
VERIFIED_DATE = "2026-05-06"

# (id, timing, dose_per_intake, intakes_per_day, intake_note, data_source)
# Only entries that *changed* compared to the v5 자동 룰 결과는 여기에 둔다.
# 변경 없음(라벨 일치) 제품은 verified_date / data_source / note 갱신만 적용
# (별도 리스트에서 관리).
CHANGES = [
    # ── omega3: "1일 1회 2캡슐" 패턴 (분복 → 통합) ───────────────────
    ("nordic_omega3_basic",
     "anyTimeAfterMeal", 2, 1,
     "1일 2 소프트젤 식사와 함께",
     "https://www.pillyze.com/products/3575/%EC%98%A4%EB%A9%94%EA%B0%803"),
    ("promega_dual_plus",
     "morningAfter", 2, 1,
     "1일 1회 2캡슐 오전 식후",
     "https://www.pillyze.com/products/24278/%ED%98%88%ED%96%89%EA%B1%B4%EA%B0%95-%ED%94%84%EB%A1%9C%EB%A9%94%EA%B0%80-%EC%95%8C%ED%8B%B0%EC%A7%80-%EC%98%A4%EB%A9%94%EA%B0%803-%EB%93%80%EC%96%BC-%ED%94%8C%EB%9F%AC%EC%8A%A4"),
    ("ckd_belderwell_omega3",
     "anyTimeAfterMeal", 2, 1,
     "1일 1회 2캡슐 식후 (벨더웰 라인 표준 라벨)",
     "https://www.ckdhc.com/product/productView.do?prodCode=CHC0000059"),
    ("ckd_promega_triple",
     "anyTimeAfterMeal", 2, 1,
     "1일 1회 2캡슐 식후 (프로메가 라인 표준 라벨)",
     "https://www.ckdhc.com/product/productView.do?prodCode=CHC0000059"),
    ("nordic_kids_dha_capsule",
     "withMeal", 2, 1,
     "1일 2 소프트젤 식사와 함께 (만 5세 이상)",
     "https://www.nordic.com/products/childrens-dha/"),
    ("nordic_omega_2x_mini",
     "anyTimeAfterMeal", 2, 1,
     "1일 2 미니 소프트젤 식사와 함께",
     "https://www.ople.com/m/shop/item.php?it_id=1201761903"),

    # ── 멀티비타민: "1일 1회 N정" 통합 패턴 ────────────────────────
    ("now_adam",
     "withMeal", 2, 1,
     "매일 식사 중 2 소프트젤",
     "https://food119.co.kr/40/?idx=769"),
    ("now_eve",
     "withMeal", 3, 1,
     "매일 식사와 함께 3 소프트젤",
     "https://food119.co.kr/40/?idx=770"),
    ("atomy_proactamin",
     "anyTimeAfterMeal", 2, 1,
     "1일 1회 2캡슐 충분한 물과 함께",
     "https://kr.atomy.com/product/004078"),

    # ── 칼슘/마그네슘: "1일 1회 N정" 통합 패턴 ─────────────────────
    ("solgar_ca_mg_zn",
     "withMeal", 3, 1,
     "1일 1회 3정 식사와 함께 (분복 가능)",
     "https://www.pillyze.com/products/9512/%EC%B9%BC%EC%8A%98-%EB%A7%88%EA%B7%B8%EB%84%A4%EC%8A%98-%ED%94%8C%EB%9F%AC%EC%8A%A4-%EC%A7%95%ED%81%AC"),
    ("ckd_ca_mg_d_zn",
     "dinnerAfter", 2, 1,
     "1일 1회 2정 (저녁 식후 권장)",
     "https://www.pillyze.com/products/236/%EC%B9%BC%EC%8A%98-%EC%95%A4-%EB%A7%88%EA%B7%B8%EB%84%A4%EC%8A%98-%EB%B9%84%ED%83%80%EB%AF%BCD-%EC%95%84%EC%97%B0"),
    ("ckd_ca_mg_d_zn_v2",
     "dinnerAfter", 2, 1,
     "1일 1회 2정 (저녁 식후 권장) - 1000mg 라벨",
     "https://www.pillyze.com/products/236/%EC%B9%BC%EC%8A%98-%EC%95%A4-%EB%A7%88%EA%B7%B8%EB%84%A4%EC%8A%98-%EB%B9%84%ED%83%80%EB%AF%BCD-%EC%95%84%EC%97%B0"),
    ("ckd_camgd_zn_v2",
     "dinnerAfter", 2, 1,
     "1일 1회 2정 (저녁 식후 권장)",
     "https://www.pillyze.com/products/236/%EC%B9%BC%EC%8A%98-%EC%95%A4-%EB%A7%88%EA%B7%B8%EB%84%A4%EC%8A%98-%EB%B9%84%ED%83%80%EB%AF%BCD-%EC%95%84%EC%97%B0"),
    ("ckd_mg_plus",
     "beforeSleep", 2, 1,
     "1일 1회 2정 (1100mg 라벨, 취침 전 권장)",
     "https://prod.danawa.com/info/?pcode=18751613"),

    # ── 콜라겐 ────────────────────────────────────────────────
    ("evercollagen_in_up_plus",
     "morningEmpty", 2, 1,
     "1일 1회 2정 (콜라겐 흡수 위해 공복 권장)",
     "https://www.pillyze.com/products/5354/%EC%97%90%EB%B2%84%EC%BD%9C%EB%9D%BC%EA%B2%90-%EC%9D%B8%EC%95%A4%EC%97%85-%ED%94%8C%EB%9F%AC%EC%8A%A4"),

    # ── 관절 (보스웰리아) ─────────────────────────────────────────
    ("frombio_joint_boswellia",
     "anyTimeAfterMeal", 2, 1,
     "1일 1회 2정 (1000mg 보스웰리아)",
     "https://www.pillyze.com/products/106/%EA%B4%80%EC%A0%88%EC%97%B0%EA%B3%A8%EC%97%94-%EB%B3%B4%EC%8A%A4%EC%9B%B0%EB%A6%AC%EC%95%84"),
    ("frombio_boswellia",
     "anyTimeAfterMeal", 2, 1,
     "1일 1회 2정 (1000mg 보스웰리아)",
     "https://www.pillyze.com/products/106/%EA%B4%80%EC%A0%88%EC%97%B0%EA%B3%A8%EC%97%94-%EB%B3%B4%EC%8A%A4%EC%9B%B0%EB%A6%AC%EC%95%84"),

    # ── 홍삼 ─────────────────────────────────────────────────
    ("pilly_red_ginseng_octacosanol",
     "morningEmpty", 2, 1,
     "1일 1회 2캡슐 (홍삼은 아침 공복 권장)",
     "https://www.pillyze.com/products/16641/%ED%99%8D%EC%82%BC-%EC%98%A5%ED%83%80%EC%BD%94%EC%82%AC%EB%86%80"),

    # ── 어린이 ───────────────────────────────────────────────
    ("atomy_kids_gummy",
     "withMeal", 2, 1,
     "1일 1회 2개 (씹어서)",
     "https://kr.atomy.com/product/004053"),
    ("cenovis_kids_multi",
     "withMeal", 2, 1,
     "1일 1회 2정",
     "https://www.cenovismall.co.kr/goods/goods_view.php?goodsNo=100012"),

    # ── 간 (밀크씨슬) ────────────────────────────────────────────
    ("now_milk_thistle",
     "dinnerAfter", 2, 1,
     "1일 1회 2캡슐 식후 (저녁 권장)",
     "https://www.pillyze.com/products/333/%EC%8B%A4%EB%A6%AC%EB%A7%88%EB%A6%B0-300mg"),

    # ── 남성 ─────────────────────────────────────────────────
    ("gnc_saw_palmetto",
     "dinnerAfter", 2, 1,
     "1일 1회 2정 저녁 식후 권장",
     "https://www.ople.com/m/shop/item.php?it_id=1341933335"),
]

# 라벨로 검증했으나 기존 1+N 값과 일치하는 제품들 — verified_date / source 만 갱신
CONFIRMED_NO_CHANGE = [
    ("ginexin_f_40",
     "1회 40mg 1일 3회 (약학정보원, 의약품)",
     "https://health.kr/searchDrug/result_take.asp?drug_cd=A11ABBBBB1014"),
    ("ginexin_f_120",
     "1회 120mg 1일 2회 (약학정보원, 의약품)",
     "https://www.health.kr/searchDrug/result_drug.asp?drug_cd=A11A1890B0008"),
    ("atomy_spirulina",
     "1일 3회 1캡슐",
     "https://kr.atomy.com/product/000178"),
    ("chondroitin_general",
     "1일 2정 식후 (분복 권장)",
     "https://prod.danawa.com/info/?pcode=13412984"),
    ("glucosamine_general",
     "1일 1500mg 분복 식후 (1500mg/일 권장량)",
     "https://gradium.co.kr/glucosamine/"),
    ("garcinia_general",
     "1일 3회 식전 30분 (HCA 750-2800mg/일)",
     "https://www.kpanews.co.kr/article/show.asp?category=H&idx=213882"),
    ("aronamin_gold",
     "1회 1정 1일 2회 식후 (의약품)",
     "https://www.health.kr/searchDrug/result_drug.asp?drug_cd=A11A0340A0195"),
    ("yuhan_beecom_c",
     "1회 1정 1일 2회 (아침/저녁) - 의약품",
     "https://www.health.kr/searchDrug/result_drug.asp?drug_cd=2012100400021"),
    ("aronamin_c_plus",
     "1회 1정 1일 2회 또는 1일 1회 2정 (의약품)",
     "https://nedrug.mfds.go.kr/pbp/CCBBB01/getItemDetailCache?cacheSeq=200400325aupdateTs2024-07-19+13:46:36.0b"),
    ("yuhan_vit_cd",
     "1회 1정 1일 1~2회 (의약품)",
     "https://www.health.kr/searchDrug/result_drug.asp?drug_cd=2019103100014"),
    ("solgar_l_theanine_150",
     "1일 2회 1캡슐 (스트레스 분복) - 수면 시 1회 통합 가능",
     "https://prod.danawa.com/info/?pcode=7862869"),
    ("ckd_glucosamine_plus",
     "1일 2회 1정 (1500mg 글루코사민)",
     "https://prod.danawa.com/info/?pcode=1780625"),
    ("ckd_joint_pain_quick",
     "1일 3정 (1800mg 콘드로이친, 분복 권장)",
     "https://a.mansurkim.com/m/219"),
    ("ckd_olallme_collagen_3270",
     "1일 2회 1포 (스틱형 분말)",
     "https://prod.danawa.com/info/?pcode=14622788"),
    ("ckd_allatme_collagen_3270",
     "1일 2회 1포 (스틱형 분말)",
     "https://prod.danawa.com/info/?pcode=14622788"),
    ("atomy_psyllium",
     "1일 3회 1포 (충분한 물과 함께)",
     "https://kr.atomy.com/product/004072"),
    ("meditree_psyllium",
     "1일 2회 1포 (찬물에 타서)",
     "https://www.meditree.kr/goods/goods_view.php?goodsNo=1000000600"),
    ("now_magtein",
     "1일 3캡슐 분복 (아침 1 + 취침 2시간 전 2)",
     "https://kr.iherb.com/pr/now-foods-magtein-magnesium-l-threonate-90-veg-capsules/57577"),
    ("atomy_color_multi",
     "1일 2회 2정씩 (4정/일, 4종 색깔 분배)",
     "https://kr.atomy.com/product/000181"),
    ("atomy_vital_color",
     "1일 2회 2정씩 (4정/일, 4종 색깔 분배)",
     "https://kr.atomy.com/product/000181"),
    ("atomy_vital_color_multi",
     "1일 2회 2정씩 (4정/일, 4종 색깔 분배)",
     "https://kr.atomy.com/product/000181"),
    ("solgar_ca_mg_d3",
     "1일 5정 (분복 권장, 알약 큼)",
     "https://prod.danawa.com/info/?pcode=17689739"),
    ("solgar_camg_citrate",
     "1일 5정 (분복 권장, 시트레이트형 흡수율 높음)",
     "https://prod.danawa.com/info/?pcode=17689739"),
    ("drbest_high_abs_mg_200",
     "1일 2회 1정 식사 무관 (글리시네이트형)",
     "https://prod.danawa.com/info/?pcode=11109768"),
    ("msm_general",
     "1일 1500-2000mg 분복 (식사 무관)",
     "https://gradium.co.kr/msm-benefits/"),
    ("curcumin_general",
     "1일 500-1000mg 식후 (지용성, 분복 가능)",
     "https://gradium.co.kr/turmeric/"),
    ("cla_general",
     "1일 3캡슐 식사와 함께 (체지방 감소)",
     "https://rpspharmacy.com/%EA%B3%B5%EC%95%A1-%EB%A6%AC%EB%86%80%EB%A0%88%EC%82%B0-%EC%B6%94%EC%B2%9C-%ED%9A%A8%EB%8A%A5-%EB%B6%80%EC%9E%91%EC%9A%A9-%EB%B3%B5%EC%9A%A9%EB%B2%95-cla/"),
    ("iherb_lcarnitine",
     "1일 1000-2000mg 운동 30분 전 공복 (분복 가능)",
     "https://gradium.co.kr/l-carnitine-benefits/"),
    ("solgar_l_arginine_1000",
     "1일 1-2캡슐 식간 (운동 전 공복)",
     "https://2pharmacy.gr/en/amino-acid/17144-solgar-l-arginine-1000mg-90caps.html"),
    ("now_arginine_1000",
     "1일 1-2캡슐 식간 (공복)",
     "https://www.iherb.com/pr/now-foods-l-arginine-1-000-mg-120-tablets/411"),
    ("myprotein_aakg",
     "1일 4정 (운동 전후 분복)",
     "https://www.myprotein.co.kr/sports-nutrition/aakg-tablets/10551038.html"),
    ("black_maca_general",
     "1일 1-3정 식사와 함께 (제품별 차이)",
     "https://doctornow.co.kr/content/magazine/6f0c7b479ca0479d91d2d3bff2f354d9"),
    ("natures_way_evening_primrose_1300",
     "1정 1일 2-3회 (감마리놀렌산 ~360-540mg)",
     "https://hilifevitamins.com/products/natures-way-033674154182"),
    ("esther_boswellia",
     "1일 2정 (라벨 1정 권장과 차이 — 제품 버전별 상이)",
     "https://m.esthermall.co.kr/goods/goods_view.php?goodsNo=15384"),
    ("atomy_hemohim_v2",
     "1일 2회 1포 (아침 1 + 저녁 1) 식전·식후 무관",
     "https://kr.atomy.com/product/000011"),
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
                  f"daily_dose={p['daily_dose']}; daily_dose unchanged")
        p["intake_timing"] = timing
        p["dose_per_intake"] = dose
        p["intakes_per_day"] = intakes
        p["intake_note"] = note
        p["data_source"] = source
        p["verified_date"] = VERIFIED_DATE
        if before != after:
            changed.append((pid, before, after))

    confirmed = []
    for pid, note, source in CONFIRMED_NO_CHANGE:
        p = products_by_id.get(pid)
        if p is None:
            not_found.append(pid)
            continue
        # Only refresh meta — don't touch timing/dose/intakes
        p["intake_note"] = note
        p["data_source"] = source
        p["verified_date"] = VERIFIED_DATE
        confirmed.append(pid)

    data["version"] = "2026.05.06-v7-multiple-verified"

    TARGET.write_text(
        json.dumps(data, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print(f"=== multiple timing 재검증 결과 ===")
    print(f"라벨 변경 적용: {len(changed)}")
    print(f"라벨 일치 (변경 없음, 메타만 갱신): {len(confirmed)}")
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
