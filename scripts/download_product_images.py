"""Download images recorded in products.json into assets/images/products/.

Pairs with `fetch_product_images.py`. Reads `image_url` for each product,
fetches the binary, validates it's a real product photo (rejects logos and
banners by min dimension + min byte threshold), then resizes to 240x240
center-cropped JPEG quality 80 and writes `assets/images/products/{id}.jpg`.

Idempotent: skips ids whose target file already exists. Pass `--force`
to re-download.

Usage:
    python scripts/download_product_images.py             # all
    python scripts/download_product_images.py --limit 30  # first 30 with image_url
    python scripts/download_product_images.py --ids id1,id2
    python scripts/download_product_images.py --force
"""

from __future__ import annotations

import argparse
import io
import json
import sys
import time
from pathlib import Path
from typing import Optional

import requests
from PIL import Image, ImageOps, UnidentifiedImageError

ROOT = Path(__file__).resolve().parent.parent
TARGET = ROOT / "assets" / "data" / "products.json"
ASSET_DIR = ROOT / "assets" / "images" / "products"

UA = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0 Safari/537.36"
)

REQUEST_TIMEOUT = 12
SLEEP_BETWEEN_REQUESTS = 0.3

# Rejection thresholds — branding/share logos are tiny.
MIN_BYTES = 4_000          # < 4KB = almost certainly a placeholder
MIN_DIMENSION = 120        # both width AND height must be >= this

# Output spec.
OUT_SIZE = 240
JPEG_QUALITY = 80


def fetch_image(url: str, referer: Optional[str] = None) -> Optional[bytes]:
    headers = {
        "User-Agent": UA,
        "Accept": "image/webp,image/avif,image/apng,image/*,*/*;q=0.8",
    }
    if referer:
        headers["Referer"] = referer
    try:
        resp = requests.get(
            url,
            timeout=REQUEST_TIMEOUT,
            headers=headers,
            allow_redirects=True,
            stream=False,
        )
    except requests.RequestException as exc:
        return None
    if resp.status_code >= 400:
        return None
    if not resp.content:
        return None
    return resp.content


def process_image(raw: bytes) -> Optional[bytes]:
    """Validate + resize to 240×240 JPEG. Returns None if image fails policy."""
    if len(raw) < MIN_BYTES:
        return None
    try:
        with Image.open(io.BytesIO(raw)) as im:
            im.load()  # force decode now
            w, h = im.size
            if w < MIN_DIMENSION or h < MIN_DIMENSION:
                return None
            # Convert any palette/RGBA to RGB on a white canvas.
            if im.mode != "RGB":
                bg = Image.new("RGB", im.size, (255, 255, 255))
                if "A" in im.mode:
                    bg.paste(im, mask=im.convert("RGBA").split()[-1])
                else:
                    bg.paste(im)
                im = bg
            cropped = ImageOps.fit(
                im, (OUT_SIZE, OUT_SIZE), method=Image.LANCZOS
            )
            buf = io.BytesIO()
            cropped.save(
                buf, format="JPEG", quality=JPEG_QUALITY, optimize=True
            )
            return buf.getvalue()
    except (UnidentifiedImageError, OSError, ValueError):
        return None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=None)
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

    ASSET_DIR.mkdir(parents=True, exist_ok=True)

    todo = []
    for p in products:
        if target_ids is not None and p["id"] not in target_ids:
            continue
        if not p.get("image_url"):
            continue
        out_path = ASSET_DIR / f"{p['id']}.jpg"
        if out_path.exists() and not args.force:
            continue
        todo.append(p)

    if args.limit:
        todo = todo[: args.limit]

    print(f"=== download_product_images: {len(todo)} products ===")
    succeeded: list[str] = []
    failed: list[tuple[str, str]] = []

    for i, p in enumerate(todo, 1):
        pid = p["id"]
        url = p["image_url"]
        ref = p.get("data_source")
        print(f"[{i}/{len(todo)}] {pid}")
        raw = fetch_image(url, referer=ref)
        if raw is None:
            failed.append((pid, "download error"))
            continue
        out = process_image(raw)
        if out is None:
            failed.append((pid, f"rejected ({len(raw)}B)"))
            continue
        (ASSET_DIR / f"{pid}.jpg").write_bytes(out)
        succeeded.append(pid)
        print(f"  saved -> {len(out)}B")
        time.sleep(SLEEP_BETWEEN_REQUESTS)

    # Tally on-disk assets
    on_disk = sorted(p.stem for p in ASSET_DIR.glob("*.jpg"))
    total_bytes = sum((ASSET_DIR / f"{x}.jpg").stat().st_size for x in on_disk)

    print()
    print("=== summary ===")
    print(f"saved this run: {len(succeeded)}")
    print(f"failed:         {len(failed)}")
    for pid, reason in failed[:20]:
        print(f"  - {pid}: {reason}")
    if len(failed) > 20:
        print(f"  ... and {len(failed) - 20} more")
    print(f"on disk total:  {len(on_disk)} files, {total_bytes / 1024:.1f} KB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
