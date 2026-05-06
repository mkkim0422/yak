"""Fallback image fetcher: searches Danawa Shopping for products that
`fetch_product_images.py` couldn't resolve via og:image, and grabs the first
product photo from the search results page.

Use when a product has no `image_url` (or has a known-bad one) but does have
a name + brand. Danawa's search HTML embeds catalog photos directly via
`img.danuri.io/catalog-image/.../X.jpg?v=...`, so we just pick the first
match.

Usage:
    python scripts/search_product_images.py             # missing only
    python scripts/search_product_images.py --limit 20
    python scripts/search_product_images.py --ids id1,id2 --force
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from pathlib import Path
from typing import Optional
from urllib.parse import quote

import requests

ROOT = Path(__file__).resolve().parent.parent
TARGET = ROOT / "assets" / "data" / "products.json"

UA = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0 Safari/537.36"
)

REQUEST_TIMEOUT = 12
SLEEP_BETWEEN_REQUESTS = 0.5

# Match any /catalog-image/ URL on the danawa CDN. The very first hit in
# search results is the top product card → use that.
_DANURI_RE = re.compile(
    r'src="(https?://img\.danuri\.io/catalog-image/[^"\s]+)"'
)


def search_danawa(query: str) -> Optional[str]:
    url = (
        "https://search.danawa.com/dsearch.php?query=" + quote(query)
    )
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
    except requests.RequestException as exc:
        print(f"  danawa search error: {exc}")
        return None
    if resp.status_code >= 400:
        print(f"  danawa HTTP {resp.status_code}")
        return None
    if not resp.encoding or resp.encoding.lower() == "iso-8859-1":
        resp.encoding = resp.apparent_encoding or "utf-8"
    m = _DANURI_RE.search(resp.text)
    if not m:
        return None
    img = m.group(1)
    # Drop any low-res `?shrink=160:160` query — the CDN serves the original
    # at the same path without the modifier and the download script will
    # resize anyway.
    img = re.sub(r"\?shrink=[^&]+(&_v=[^&]+)?", "", img)
    return img


def build_query(product: dict) -> str:
    """Search query string. Brand first, then name — danawa search ranks
    brand-prefixed queries higher and surfaces the right SKU."""
    brand = (product.get("brand") or "").strip()
    name = (product.get("name") or "").strip()
    if brand and brand not in name:
        return f"{brand} {name}".strip()
    return name


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=None)
    ap.add_argument("--ids", type=str, default=None)
    ap.add_argument("--force", action="store_true",
                    help="Re-search even when image_url is set")
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
        if not (p.get("name") or "").strip():
            continue
        todo.append(p)

    if args.limit:
        todo = todo[: args.limit]

    print(f"=== search_product_images: {len(todo)} products ===")
    succeeded = 0
    failed: list[tuple[str, str]] = []

    for i, p in enumerate(todo, 1):
        pid = p["id"]
        q = build_query(p)
        print(f"[{i}/{len(todo)}] {pid} -- '{q}'")
        img = search_danawa(q)
        if not img:
            failed.append((pid, "no danawa hit"))
            continue
        p["image_url"] = img
        print(f"  -> {img}")
        succeeded += 1
        time.sleep(SLEEP_BETWEEN_REQUESTS)

    TARGET.write_text(
        json.dumps(data, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print()
    print("=== summary ===")
    print(f"succeeded: {succeeded}")
    print(f"failed:    {len(failed)}")
    for pid, reason in failed[:30]:
        print(f"  - {pid}: {reason}")
    if len(failed) > 30:
        print(f"  ... and {len(failed) - 30} more")
    return 0


if __name__ == "__main__":
    sys.exit(main())
