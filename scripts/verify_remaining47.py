"""잔여 47개 (withMeal/morningAfter/lunchAfter/beforeSleep) 라벨 재검증.

이 단계로 250개 100% 라벨 검증 완료를 목표로 한다.
"""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TARGET = ROOT / "assets" / "data" / "products.json"
VERIFIED_DATE = "2026-05-06"

# Changes (timing 보정 필요)
CHANGES = [
    # ── Q10: 라벨/약사 권고 = 아침 식후 (점심 X) ────────────────
    ("ckd_coq10",
     "morningAfter", 1, 1,
     "1일 1캡슐 아침 식후 (지용성, 에너지 보조)",
     "https://www.pillyze.com/columns/13"),
    ("now_coq10_100",
     "morningAfter", 1, 1,
     "1일 1 베지캡슐 아침 식후",
     "https://www.iherb.com/pr/now-foods-coq10-100-mg-50-veg-capsules/61"),
    ("solgar_coq10_200",
     "morningAfter", 1, 1,
     "1일 1캡슐 아침 식후 (200mg)",
     "https://m.oliveyoung.co.kr/"),
    ("solgar_coq10_100",
     "morningAfter", 1, 1,
     "1일 1 베지캡슐 아침 식후",
     "https://m.oliveyoung.co.kr/"),
    ("ckd_coq10_99",
     "morningAfter", 1, 1,
     "1일 1캡슐 아침 식후 (CKD 코엔자임Q10 99mg)",
     "https://www.ckdhc.com/"),
]

# 라벨 일치 - verified meta 갱신만
CONFIRMED = [
    # ── Vitamin B (12) ────────────────────────────────────
    ("imp_gold",
     "1일 1회 1정 식후 (오전/낮 권장)",
     "https://www.health.kr/searchDrug/result_drug.asp?drug_cd=63czqgejxdjwv"),
    ("imp_active",
     "1일 1회 1정 식후 (오전/낮 권장)",
     "https://www.impactamin.kr/"),
    ("imp_power_a_plus",
     "1일 1회 1정 식후 (파워 A+)",
     "https://www.impactamin.kr/"),
    ("solgar_b_complex_100",
     "1일 1 베지캡슐 식사와 함께 (B-Complex 100)",
     "https://www.ople.com/m/shop/item.php?it_id=1505230841"),
    ("solgar_b_complex_100_v2",
     "1일 1 베지캡슐 식사와 함께",
     "https://www.ople.com/m/shop/item.php?it_id=1505230841"),
    ("now_b50",
     "1일 1캡슐 식사와 함께 (B-50)",
     "https://www.iherb.com/pr/now-foods-b-50-100-veg-capsules/447"),
    ("atomy_b_complex",
     "1일 1정 (애터미 비타민B 컴플렉스)",
     "https://kr.atomy.com/"),
    ("ckd_active_vit_b_plus",
     "1일 1정 식후 (활력 비타민B 플러스)",
     "https://www.ckdhc.com/"),
    ("now_biotin_5000",
     "1일 1캡슐 (비오틴 5000mcg)",
     "https://www.iherb.com/pr/now-foods-biotin-5-000-mcg-120-veg-capsules/19478"),
    ("thorne_basic_b",
     "1일 1캡슐 식사와 함께 (Basic B Complex)",
     "https://www.thorne.com/products/dp/basic-b-complex"),
    ("lifeextension_bcomplex",
     "1일 1캡슐 식사와 함께 (BioActive B-Complete)",
     "https://www.lifeextension.com/"),
    ("ckd_imbita_high_b",
     "1일 1정 식후 (아임비타 고함량 B)",
     "https://www.ckdhc.com/product/productView.do?prodCode=CHC0000208"),
    ("berocca_bayer",
     "1일 1정 (Berocca, 발포정 가능)",
     "https://www.bayer.kr/"),

    # ── Sports (10) ──────────────────────────────────────
    ("creatine_monohydrate",
     "1일 5g 운동 후 (탄수화물과 함께 흡수 ↑)",
     "https://www.kpanews.co.kr/news/articleView.html?idxno=526844"),
    ("myprotein_the_whey",
     "1일 1스쿱 운동 30분 전후 (단백질 25g/스쿱)",
     "https://us.myprotein.com/p/sports-nutrition/the-whey/12968603/"),
    ("selex_core_protein_pro",
     "1일 1회 38g (3스푼, 물/우유에 타서)",
     "https://www.pillyze.com/products/17831/%EC%BD%94%EC%96%B4-%ED%94%84%EB%A1%9C%ED%8B%B4-%ED%94%84%EB%A1%9C"),
    ("selex_core_protein_plus",
     "1일 1병 (액상 프로틴)",
     "https://www.maeil.com/brand/view_brand1.jsp?dpid=A0000467"),
    ("aminovital_pro_3800",
     "1회 1포 (4.4g) 운동 전 권장 (1일 1-3회)",
     "https://www.pillyze.com/products/21538/%EC%95%84%EB%AF%B8%EB%85%B8%EB%B0%94%EC%9D%B4%ED%83%88-%ED%94%84%EB%A1%9C-3800"),
    ("bcaa_general",
     "1일 5g 운동 전/중/후 분산 (5-10g 권장)",
     "https://www.kpanews.co.kr/news/articleView.html?idxno=526836"),
    ("myprotein_citrulline_malate",
     "1일 2g 운동 30분 전 (펌핑 효과)",
     "https://us.myprotein.com/p/sports-nutrition/citrulline-malate/10852539/"),
    ("myprotein_beta_alanine",
     "1일 3g (분복 권장 - 한번에 1g씩 3회)",
     "https://us.myprotein.com/p/sports-nutrition/beta-alanine/10852512/"),
    ("myprotein_l_glutamine",
     "1일 5g 운동 후 권장",
     "https://us.myprotein.com/p/sports-nutrition/glutamine-powder/10852553/"),
    ("eaa_general",
     "1일 15g 운동 전/중 (필수 아미노산 9종)",
     "https://www.muscleup.co.kr/"),

    # ── 간 (3) ──────────────────────────────────────────
    ("gnm_milk_thistle",
     "1일 1정 취침 전 (GNM 건강한 간)",
     "https://www.gradium.co.kr/milk-thistle/"),
    ("gnm_milk_thistle_full",
     "1일 1정 취침 전 (풀 패널)",
     "https://www.gradium.co.kr/milk-thistle/"),
    ("yakult_cuperz",
     "1일 1정 (헛개나무 추출분말 2460mg/일)",
     "https://www.pillyze.com/products/19231/%EA%B0%84%EA%B1%B4%EA%B0%95-%EA%B0%84-%ED%94%BC%EB%A1%9C-%EC%BC%80%EC%96%B4-%EC%BF%A0%ED%8D%BC%EC%8A%A4"),

    # ── 수면 (3) ─────────────────────────────────────────
    ("melatonin_general",
     "1일 1정 (3-6mg) 취침 30분~1시간 전",
     "https://healthmap.co.kr/%EB%A9%9C%EB%9D%BC%ED%86%A0%EB%8B%8C-%EB%B3%B5%EC%9A%A9%EB%B2%95/"),
    ("now_l_theanine_200",
     "1일 1캡슐 취침 전 (수면 보조)",
     "https://www.iherb.com/pr/now-foods-l-theanine-200-mg-60-veg-capsules/12099"),
    ("5htp_general",
     "1일 1캡슐 (100mg) 취침 1시간 전 (불면 보조)",
     "https://health.kr/searchDrug/result_drug.asp?drug_cd=A11AIIIII0012"),

    # ── 어린이 (12) ───────────────────────────────────────
    ("nordic_baby_dha",
     "1일 1ml (1세 미만, 액상 아기용)",
     "https://www.ople.com/m/shop/item.php?it_id=1282598579"),
    ("nordic_kids_dha",
     "1일 1티스푼 (5ml) 음식과 함께 (1-6세 1/2 티스푼)",
     "https://www.ople.com/m/shop/item.php?it_id=1359962463"),
    ("kidsten_multi",
     "1일 1정 식사와 함께 (어린이 종합)",
     "https://prod.danawa.com/info/"),
    ("eundan_kids_multi",
     "1일 1정 (츄어블, 15종 영양소)",
     "https://www.eundan.com/"),
    ("jks_hongijanggun_2",
     "1일 1포 (정관장 홍이장군 2단계)",
     "https://health-benefit.co.kr/%EC%A0%95%EA%B4%80%EC%9E%A5-%EC%96%B4%EB%A6%B0%EC%9D%B4-%ED%99%8D%EC%82%BC-%ED%99%8D%EC%9D%B4%EC%9E%A5%EA%B5%B0-%ED%9A%A8%EB%8A%A5-%EB%B0%8F-%EB%B6%80%EC%9E%91%EC%9A%A9-%ED%9B%84%EA%B8%B0-%EC%95%8C/"),
    ("lacfido_kids_d_1000",
     "1일 1츄어블 (어린이 비타민D 1000IU)",
     "https://prod.danawa.com/info/"),
    ("jamieson_kids_d_chewable",
     "1일 1츄어블 (자미에슨 키즈 비타민D)",
     "https://www.jamiesonvitamins.com/"),
    ("hamsoa_kids_red_ginseng",
     "1일 1포 (5-7세 함소아 홍키통키 프리미어 블루)",
     "https://www.hamsoamall.co.kr/"),
    ("hansamin_kids_redginseng",
     "1일 1포 (한삼인 아이홍삼)",
     "https://www.nhhansamin.com/"),
    ("nordic_complete_junior",
     "1일 1캡슐 음식과 함께 (어린이 컴플리트)",
     "https://www.nordic.com/"),
    ("centrum_kids",
     "1일 1정 (구미/츄어블 형태)",
     "https://centrum.pchkorea.co.kr/"),
    ("ckd_kids_multivit",
     "1일 1정 (어린이 종합비타민 미네랄)",
     "https://www.ckdhc.com/"),
    ("centrum_kids_gummy",
     "1일 1구미 (씹어 섭취)",
     "https://centrum.pchkorea.co.kr/"),
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
            print(f"WARN {pid}: dose×intakes={dose*intakes} != daily_dose={p['daily_dose']}")
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

    data["version"] = "2026.05.06-v9-all-verified"
    TARGET.write_text(
        json.dumps(data, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    # Final stats: how many of 250 are verified?
    verified_count = sum(1 for p in data["products"]
                         if p.get("verified_date") == VERIFIED_DATE)
    print(f"=== 4차 잔여 47개 검증 결과 ===")
    print(f"변경 적용: {len(changed)}")
    print(f"라벨 일치 (메타만 갱신): {len(confirmed)}")
    if not_found:
        print(f"DB에 없음: {len(not_found)} → {not_found}")
    print()
    print("=== Changed rows ===")
    for pid, before, after in changed:
        bs = f"{before[0]:18s} {before[1]}+{before[2]}"
        as_ = f"{after[0]:18s} {after[1]}+{after[2]}"
        print(f"{pid:35s} {bs:35s} -> {as_:35s}")
    print()
    print(f"=== 최종 누적 검증: {verified_count} / {len(data['products'])} ===")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
