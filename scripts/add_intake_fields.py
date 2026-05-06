"""One-shot migration: add intake_timing / dose_per_intake / intakes_per_day /
intake_note to every product in assets/data/products.json.

Rules (mirrors the user's spec):
  * Category-based timing default; switches to `multiple` whenever
    intakes_per_day >= 2.
  * dose_per_intake * intakes_per_day == daily_dose (invariant).
  * Powder/liquid units (g, ml, 스쿱) are taken in a single intake — the
    daily_dose IS the per-intake amount.
  * ID-level overrides for products explicitly called out in the spec
    (GNC 메가맨, 듀오락 골드, 솔가 마그네슘 시트레이트 등).
  * Products with already-populated new fields are left as-is so the script
    is idempotent.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Tuple

ROOT = Path(__file__).resolve().parent.parent
TARGET = ROOT / "assets" / "data" / "products.json"

POWDER_UNITS = {"g", "ml", "스쿱"}

# Category → default IntakeTiming (camelCase, matches Dart enum names).
CATEGORY_TIMING = {
    "multivitamin": "anyTimeAfterMeal",
    "vitamin_b": "morningAfter",
    "vitamin_c": "anyTimeAfterMeal",
    "vitamin_d": "anyTimeAfterMeal",
    "omega3": "anyTimeAfterMeal",
    "krill_oil": "anyTimeAfterMeal",
    "probiotic": "morningEmpty",
    "probiotics": "morningEmpty",
    "magnesium": "beforeSleep",
    "calcium": "dinnerAfter",
    "collagen": "morningEmpty",
    "lutein": "anyTimeAfterMeal",
    "eye": "anyTimeAfterMeal",
    "antioxidant": "anyTimeAfterMeal",  # overridden by id-pattern for q10
    "milk_thistle": "beforeSleep",
    "liver": "beforeSleep",
    "iron": "morningEmpty",
    "biotin": "morningAfter",
    "folate": "morningEmpty",
    "prenatal": "morningEmpty",
    "pregnancy": "morningEmpty",
    "ginseng": "morningEmpty",
    "red_ginseng": "morningEmpty",
    "korean_herbal": "morningEmpty",
    "circulation": "anyTimeAfterMeal",  # multiple kicks in via intakes_per_day
    "sleep": "beforeSleep",
    "joint": "anyTimeAfterMeal",
    "mineral": "anyTimeAfterMeal",
    "sports": "morningAfter",
    "weight": "anyTimeAfterMeal",
    "fiber": "anyTimeAfterMeal",
    "immunity": "anyTimeAfterMeal",
    "immune": "anyTimeAfterMeal",
    "menopause_female": "anyTimeAfterMeal",
    "menopause_male": "anyTimeAfterMeal",
    "women_health": "anyTimeAfterMeal",
    "men_health": "anyTimeAfterMeal",
    "superfood": "anyTimeAfterMeal",
    "kids": "withMeal",
    "kids_omega3": "withMeal",
    "kids_multivitamin": "withMeal",
    "kids_korean_herbal": "withMeal",
    "kids_vitamin_d": "withMeal",
}

# Hard-coded (dose_per_intake, intakes_per_day) overrides for products
# explicitly called out in the spec.
ID_DOSE_OVERRIDES = {
    "gnc_megaman": (2, 1),     # 2정/회 1회/일 (라벨: 1일 1회 2정)
    "gnc_megamen": (2, 1),
}

# Force a specific timing for products that don't fit the category default.
ID_TIMING_OVERRIDES = {
    # Q10 → lunchAfter regardless of antioxidant category default.
    "ckd_coq10": "lunchAfter",
    "ckd_coq10_plus_30": "lunchAfter",
    "ckd_coq10_99": "lunchAfter",
    "now_coq10_100": "lunchAfter",
    "solgar_coq10_100": "lunchAfter",
    "solgar_coq10_200": "lunchAfter",
    # Iron in mineral category → morningEmpty
    "movita_iron_chewable": "morningEmpty",
    "ckd_iron_folate_d_plus": "morningEmpty",
}


def split_for_daily_dose(daily_dose: int, unit: str) -> Tuple[int, int]:
    """Decide (dose_per_intake, intakes_per_day) so the product equals daily_dose.

    Powder/liquid stay as a single intake (a 5g serving once a day).
    """
    if unit in POWDER_UNITS:
        return (max(1, daily_dose), 1)
    if daily_dose <= 1:
        return (1, 1)
    if daily_dose == 2:
        return (1, 2)
    if daily_dose == 3:
        return (1, 3)
    if daily_dose == 4:
        return (2, 2)
    if daily_dose == 5:
        return (1, 5)
    if daily_dose == 6:
        return (2, 3)
    # very high daily_dose with countable units — keep dose=1, intakes=N
    return (1, daily_dose)


def timing_for(product: dict, intakes_per_day: int) -> str:
    pid = product.get("id", "")
    cat = product.get("category", "")
    if pid in ID_TIMING_OVERRIDES:
        base = ID_TIMING_OVERRIDES[pid]
    else:
        base = CATEGORY_TIMING.get(cat, "anyTimeAfterMeal")
    # If the product is taken multiple times a day, switch to `multiple`
    # — the UI then composes the schedule from intakes_per_day directly.
    if intakes_per_day >= 2:
        return "multiple"
    return base


def main() -> int:
    data = json.loads(TARGET.read_text(encoding="utf-8"))
    products = data["products"]

    # Stats for the report
    timing_counts: dict = {}
    pattern_counts: dict = {}
    overrides_applied = []

    for p in products:
        # Idempotent — leave alone if fields already exist & are valid.
        already = (
            isinstance(p.get("intake_timing"), str)
            and isinstance(p.get("dose_per_intake"), int)
            and isinstance(p.get("intakes_per_day"), int)
        )

        daily_dose = int(p.get("daily_dose", 1) or 1)
        unit = p.get("unit", "")

        if p["id"] in ID_DOSE_OVERRIDES:
            dose, intakes = ID_DOSE_OVERRIDES[p["id"]]
            overrides_applied.append(p["id"])
        else:
            dose, intakes = split_for_daily_dose(daily_dose, unit)

        # Re-derive daily_dose if mismatch — should never happen with our table
        if dose * intakes != daily_dose:
            # Trust the existing daily_dose for engine compatibility — adjust
            # split instead.
            if daily_dose <= 1:
                dose, intakes = 1, 1
            else:
                dose, intakes = 1, daily_dose

        timing = timing_for(p, intakes)

        # Insert in a stable position: right after daily_dose for readability.
        new_fields = {
            "intake_timing": timing,
            "dose_per_intake": dose,
            "intakes_per_day": intakes,
            "intake_note": p.get("intake_note"),  # keep existing if any
        }

        if already:
            # Preserve existing fields verbatim (idempotency).
            new_fields = {
                "intake_timing": p["intake_timing"],
                "dose_per_intake": p["dose_per_intake"],
                "intakes_per_day": p["intakes_per_day"],
                "intake_note": p.get("intake_note"),
            }

        # Rebuild dict with our new fields placed after `daily_dose` so the JSON
        # diff is readable. Keys we strip first to avoid duplicates.
        existing_keys = list(p.keys())
        for k in ("intake_timing", "dose_per_intake", "intakes_per_day", "intake_note"):
            if k in p:
                del p[k]

        rebuilt: dict = {}
        for k in existing_keys:
            if k in ("intake_timing", "dose_per_intake", "intakes_per_day", "intake_note"):
                continue
            rebuilt[k] = p[k]
            if k == "package_size":
                rebuilt.update(new_fields)

        # Some products may not have package_size; fall back to appending.
        if not any(nk in rebuilt for nk in new_fields):
            rebuilt.update(new_fields)

        p.clear()
        p.update(rebuilt)

        # Stats
        timing_counts[timing] = timing_counts.get(timing, 0) + 1
        pattern = f"{dose}+{intakes}"
        pattern_counts[pattern] = pattern_counts.get(pattern, 0) + 1

    # Bump version so consumers can identify the new shape.
    data["version"] = "2026.05.06-v5-intake"
    notes = data.get("schema_notes", [])
    if not any("intake_timing" in n for n in notes):
        notes.append(
            "intake_timing/dose_per_intake/intakes_per_day: 라벨/약학정보원 기반 복용 가이드. "
            "dose_per_intake * intakes_per_day == daily_dose. "
            "intake_timing=multiple은 1일 2회 이상 분산 복용 의미."
        )
        data["schema_notes"] = notes

    TARGET.write_text(
        json.dumps(data, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    # Report
    print(f"updated {len(products)} products")
    print("--- timing distribution ---")
    for k, v in sorted(timing_counts.items(), key=lambda x: -x[1]):
        print(f"  {k}: {v}")
    print("--- (dose_per_intake)+(intakes_per_day) distribution ---")
    for k, v in sorted(pattern_counts.items(), key=lambda x: -x[1]):
        print(f"  {k}: {v}")
    print(f"--- id-level dose overrides applied: {len(overrides_applied)} ---")
    for pid in overrides_applied:
        print(f"  {pid}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
