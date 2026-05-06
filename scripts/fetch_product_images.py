"""Fetch a representative image URL for each product in products.json.

Strategy
--------
For every product whose `image_url` is missing, fetch its `data_source` URL
and extract an image candidate in this priority order:
  1. `<meta property="og:image" content="...">` (most reliable)
  2. `<meta name="twitter:image" content="...">`
  3. `<link rel="image_src" href="...">`
  4. The first `<img>` whose src contains "product" / the product id /
     a /goods/ path component (last-ditch heuristic).

Idempotent — products that already carry `image_url` are skipped, so the
script can be re-run after manual edits.

Usage:
    python scripts/fetch_product_images.py            # all missing
    python scripts/fetch_product_images.py --limit 20 # first 20 missing
    python scripts/fetch_product_images.py --ids id1,id2  # specific ids
    python scripts/fetch_product_images.py --force    # re-fetch all
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from html.parser import HTMLParser
from pathlib import Path
from typing import Optional
from urllib.parse import urljoin

import requests

ROOT = Path(__file__).resolve().parent.parent
TARGET = ROOT / "assets" / "data" / "products.json"

UA = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0 Safari/537.36"
)

REQUEST_TIMEOUT = 12
SLEEP_BETWEEN_REQUESTS = 0.4  # be polite


class _MetaImageParser(HTMLParser):
    """Strict, fast HTML parser that snaps onto known meta tags only."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.og: Optional[str] = None
        self.twitter: Optional[str] = None
        self.image_src: Optional[str] = None
        self.first_product_img: Optional[str] = None

    def handle_starttag(self, tag: str, attrs: list[tuple[str, Optional[str]]]) -> None:
        a = {k.lower(): (v or "") for k, v in attrs}
        if tag == "meta":
            prop = (a.get("property") or a.get("name") or "").lower()
            content = a.get("content") or ""
            if prop == "og:image" and self.og is None and content:
                self.og = content
            elif prop == "twitter:image" and self.twitter is None and content:
                self.twitter = content
        elif tag == "link":
            rel = (a.get("rel") or "").lower()
            if rel == "image_src" and self.image_src is None:
                self.image_src = a.get("href")
        elif tag == "img" and self.first_product_img is None:
            src = a.get("src") or a.get("data-src") or ""
            # Heuristics: bigger images on shopping pages live under /goods/
            # /image/ /product/ /img/ paths.
            if any(k in src for k in ("/goods/", "/product/", "/img/", "/image/")):
                self.first_product_img = src


_BAD_MARKERS = (
    "pixel", "1x1", "blank.gif", "no_image", "noimage",
    "og_image", "og-image", "og_default",
    "share.png", "share.jpg", "share-image",
    "default.png", "default.jpg",
    "logo.png", "logo.jpg", "_logo_", "/logo/",
    "/common/", "/share/",
    "/brands/menu/", "/main/", "/banner",
    "favicon",
)


def _normalize(candidate: str, page_url: str) -> Optional[str]:
    candidate = candidate.strip()
    if not candidate:
        return None
    if candidate.startswith("//"):
        candidate = "https:" + candidate
    elif candidate.startswith("/"):
        candidate = urljoin(page_url, candidate)
    if not re.match(r"^https?://", candidate):
        return None
    lc = candidate.lower()
    if any(m in lc for m in _BAD_MARKERS):
        return None
    return candidate


def extract_image_url(page_url: str, html: str) -> Optional[str]:
    parser = _MetaImageParser()
    try:
        parser.feed(html)
    except Exception:
        # Resilient against parser errors on broken HTML — keep whatever we have.
        pass
    # Try each candidate in priority order, skip share/branding placeholders.
    for raw in (
        parser.og,
        parser.twitter,
        parser.image_src,
        parser.first_product_img,
    ):
        if raw:
            url = _normalize(raw, page_url)
            if url:
                return url
    return None


def fetch_html(url: str) -> Optional[str]:
    try:
        resp = requests.get(
            url,
            timeout=REQUEST_TIMEOUT,
            headers={
                "User-Agent": UA,
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                "Accept-Language": "ko,en;q=0.8",
            },
            allow_redirects=True,
        )
    except requests.RequestException as exc:
        print(f"  fetch error: {exc}")
        return None
    if resp.status_code >= 400:
        print(f"  HTTP {resp.status_code}")
        return None
    # Some Korean shop pages serve EUC-KR — let requests guess but fall back.
    if not resp.encoding or resp.encoding.lower() == "iso-8859-1":
        resp.encoding = resp.apparent_encoding or "utf-8"
    return resp.text


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=None,
                    help="Only process the first N missing products.")
    ap.add_argument("--ids", type=str, default=None,
                    help="Comma-separated product ids to (re-)fetch.")
    ap.add_argument("--force", action="store_true",
                    help="Re-fetch even when image_url is already set.")
    args = ap.parse_args()

    data = json.loads(TARGET.read_text(encoding="utf-8"))
    products = data["products"]

    target_ids: Optional[set[str]] = None
    if args.ids:
        target_ids = {x.strip() for x in args.ids.split(",") if x.strip()}

    todo = []
    for p in products:
        if target_ids is not None and p["id"] not in target_ids:
            continue
        if not args.force and p.get("image_url"):
            continue
        if not p.get("data_source"):
            continue
        todo.append(p)

    if args.limit:
        todo = todo[: args.limit]

    print(f"=== fetch_product_images: {len(todo)} products to process ===")
    succeeded = 0
    failed: list[tuple[str, str]] = []
    for i, p in enumerate(todo, 1):
        pid = p["id"]
        src = p["data_source"]
        print(f"[{i}/{len(todo)}] {pid} <- {src}")
        html = fetch_html(src)
        if html is None:
            failed.append((pid, "fetch failed"))
            continue
        img = extract_image_url(src, html)
        if not img:
            failed.append((pid, "no og:image / candidate"))
            continue
        p["image_url"] = img
        print(f"  -> {img}")
        succeeded += 1
        time.sleep(SLEEP_BETWEEN_REQUESTS)

    # Persist after every run — partial progress survives interruption.
    TARGET.write_text(
        json.dumps(data, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print()
    print(f"=== summary ===")
    print(f"succeeded: {succeeded}")
    print(f"failed:    {len(failed)}")
    for pid, reason in failed[:30]:
        print(f"  - {pid}: {reason}")
    if len(failed) > 30:
        print(f"  ... and {len(failed) - 30} more")
    return 0


if __name__ == "__main__":
    sys.exit(main())
