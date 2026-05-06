"""Multi-strategy retry for products that earlier passes couldn't resolve.

Tries Danawa search with progressively simpler queries until a hit lands:
  1. `name` only (no brand prefix — earlier pass already tried brand+name)
  2. `english_name` (helps for Myprotein/iHerb/Solgar items)
  3. brand + first two words of `name` (drops "(한국)", "프리미어 원스" etc.)
  4. brand alone (last-ditch — gives any product from that brand)

If all four fail, leave the product alone — UI will fall back to category
emoji.

Usage:
    python scripts/retry_missing_images.py
    python scripts/retry_missing_images.py --ids id1,id2 --force
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from pathlib import Path
from typing import Iterable, Optional
from urllib.parse import quote

import requests

ROOT = Path(__file__).resolve().parent.parent
TARGET = ROOT / "assets" / "data" / "products.json"

UA = (
    "Mozilla/5.0 (Linux; Android 11) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36"
)

REQUEST_TIMEOUT = 12
SLEEP_BETWEEN_QUERIES = 0.4

_DANURI_RE = re.compile(
    r'src="(https?://img\.danuri\.io/catalog-image/[^"\s]+)"'
)


def _danawa(query: str) -> Optional[str]:
    if not query.strip():
        return None
    url = "https://search.danawa.com/dsearch.php?query=" + quote(query)
    try:
        resp = requests.get(
            url,
            timeout=REQUEST_TIMEOUT,
            headers={
                "User-Agent": UA,
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                "Accept-Language": "ko,en;q=0.8",
                "Referer": "https://search.danawa.com/",
            },
        )
    except requests.RequestException:
        return None
    if resp.status_code >= 400:
        return None
    if not resp.encoding or resp.encoding.lower() == "iso-8859-1":
        resp.encoding = resp.apparent_encoding or "utf-8"
    m = _DANURI_RE.search(resp.text)
    if not m:
        return None
    img = m.group(1)
    return re.sub(r"\?shrink=[^&]+(&_v=[^&]+)?", "", img)


def _strip_parenthetical(s: str) -> str:
    """Drop trailing '(한국)' / '(v2)' / '(국내)' annotations from product names."""
    return re.sub(r"\s*\([^)]*\)\s*$", "", s).strip()


def _candidate_queries(p: dict) -> Iterable[str]:
    seen: set[str] = set()
    name = _strip_parenthetical(p.get("name") or "")
    eng = (p.get("english_name") or "").strip()
    brand = (p.get("brand") or "").strip()

    def emit(q: str) -> Iterable[str]:
        q = q.strip()
        if not q or q in seen:
            return
        seen.add(q)
        yield q

    if name:
        yield from emit(name)
    if eng:
        # Strip trailing parentheticals from english_name too.
        yield from emit(_strip_parenthetical(eng))
    # Brand + first two words of the name (often a SKU spine).
    if brand and name:
        head = " ".join(name.split()[:2])
        yield from emit(f"{brand} {head}")
    # Last-ditch: brand alone.
    if brand:
        yield from emit(brand)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--ids", type=str, default=None)
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()

    data = json.loads(TARGET.read_text(encoding="utf-8"))
    products = data["products"]
    target_ids = (
        {x.strip() for x in args.ids.split(",") if x.strip()}
        if args.ids
        else None
    )

    todo = []
    for p in products:
        if target_ids is not None and p["id"] not in target_ids:
            continue
        if not args.force and p.get("image_url"):
            continue
        todo.append(p)

    print(f"=== retry_missing_images: {len(todo)} products ===")
    succeeded = 0
    failed: list[tuple[str, list[str]]] = []

    for i, p in enumerate(todo, 1):
        pid = p["id"]
        print(f"[{i}/{len(todo)}] {pid}")
        chose: Optional[str] = None
        chose_query = ""
        attempts: list[str] = []
        for q in _candidate_queries(p):
            attempts.append(q)
            print(f"  try '{q}'")
            img = _danawa(q)
            time.sleep(SLEEP_BETWEEN_QUERIES)
            if img:
                chose = img
                chose_query = q
                break
        if chose is None:
            failed.append((pid, attempts))
            continue
        p["image_url"] = chose
        print(f"  -> {chose}    (matched on '{chose_query}')")
        succeeded += 1

    TARGET.write_text(
        json.dumps(data, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print()
    print("=== summary ===")
    print(f"succeeded: {succeeded}")
    print(f"failed:    {len(failed)}")
    for pid, atts in failed:
        print(f"  - {pid}: tried {atts}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
