"""
단계 3 — 250개 제품 사진 출처 분류.
products.json의 image_url 호스트를 기준으로 4 카테고리로 분류 후
assets/images/products/_LICENSES.md에 기록한다. 사진 폐기는 출시 직전.
"""
import json, sys, io
from collections import defaultdict
from datetime import datetime
from pathlib import Path
from urllib.parse import urlparse

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

ROOT = Path(__file__).resolve().parents[1]
PRODUCTS = json.loads((ROOT / 'assets/data/products.json').read_text(encoding='utf-8'))['products']
OUT = ROOT / 'assets/images/products/_LICENSES.md'

# 호스트별 분류. 각 항목은 (icon, label, license_note).
# 분류 기준:
#   🔴 = 출시 전 폐기 후보 (저작권 리스크 높음)
#   🟡 = 조건부 — 인용 컨텍스트면 가능 / 매체 협의 필요
#   🟢 = 공식·공공 — 사용 가능성 높음, 단 ToS 별도 확인
HOST_CLASS = {
    # 🔴 다나와 — 최다 출처. 가격비교 사이트 자체 캐싱본 — 폐기 대상
    'img.danuri.io':                         ('🔴', '다나와',           '가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기'),
    # 🔴 필라이즈 — 한국 영양제 추적 앱의 프록시 CDN. 또 다른 캐시본
    'imgproxy.pillyze.io':                   ('🔴', '필라이즈 프록시',     '제3자 앱 CDN (자체 캐시). 라이선스 없음'),
    'cdn.pillyze.io':                        ('🔴', '필라이즈 CDN',      '제3자 앱 CDN. 라이선스 없음'),
    # 🟢 약학정보원 (공공)
    'common.health.kr':                      ('🟢', '약학정보원',        '공공 의약품 정보 사이트. ToS 별도 확인 권고'),
    # 🟢 제조사 공식 / 공식 CDN
    'image.atomy.com':                       ('🟢', '애터미 공식',        '제조사 공식 CDN'),
    'cjwellcare.com':                        ('🟢', 'CJ웰케어 공식',     '제조사 공식 사이트'),
    'impactamin.kr':                         ('🟢', '임팩타민 공식',      '제조사 공식 사이트 (대웅제약)'),
    'hanminutrition.b-cdn.net':              ('🟢', '한미양행 공식',      '제조사 공식 CDN'),
    'www.duolac.co.kr':                      ('🟢', '듀오락 공식',        '제조사 공식 사이트'),
    'gradium.co.kr':                         ('🟢', '그라디움 공식',      '제조사 공식 사이트'),
    'image.greating.co.kr':                  ('🟢', '그리팅 공식',        '제조사 공식 사이트'),
    'healthmap.co.kr':                       ('🟢', '헬스맵 공식',        '제조사 공식 사이트'),
    'health-benefit.co.kr':                  ('🟢', '헬스베네핏 공식',    '제조사 공식 사이트'),
    'rpspharmacy.com':                       ('🟢', 'RPS 약국 공식',     '제조사 공식 사이트 (해외)'),
    # 🟡 아이허브 (마켓플레이스)
    'cloudinary.images-iherb.com':           ('🟡', '아이허브',          '마켓플레이스 CDN. 제품 표시 용도 일반적이나 ToS 확인 필요'),
    # 🟡 언론·보도자료 — 인용 컨텍스트만 가능
    'cdn.kpanews.co.kr':                     ('🟡', '약사공론',          '약사공론 (전문 매체). 보도 인용 가능, 앱 카탈로그 사용은 모호'),
    'img.khan.co.kr':                        ('🟡', '경향신문',          '경향신문 보도 이미지. 인용 외 사용 X'),
    'img1.daumcdn.net':                      ('🟡', '다음 캐시',          '다음 검색 캐시 — 원 출처 불명'),
    'images.ctfassets.net':                  ('🟡', 'Contentful CDN',   'Contentful 호스팅 CDN — 원 매체 확인 필요'),
    # 🔴 쇼핑몰·블로그·검색 fallback
    'cdn.shopify.com':                       ('🔴', 'Shopify 쇼핑몰',    '제3자 쇼핑몰 캐시. 라이선스 없음'),
    'godomall.speedycdn.net':                ('🔴', '고도몰',            '쇼핑몰 솔루션 CDN. 라이선스 없음'),
    'cdn-pro-web-251-108.cdn-nhncommerce.com': ('🔴', 'NHN 커머스',     '쇼핑몰 솔루션 CDN. 라이선스 없음'),
    'd2m9duoqjhyhsq.cloudfront.net':         ('🔴', 'CloudFront 익명',  'CloudFront 호스팅 — 원 출처 불명'),
    'hilifevitamins.com':                    ('🔴', 'HiLife (해외)',    '해외 쇼핑몰. 라이선스 모호'),
    '2pharmacy.gr':                          ('🔴', '그리스 약국',         '해외 약국 사이트. 라이선스 없음'),
    'www.costco.co.kr':                      ('🔴', '코스트코',           '대형 마트 사이트. 라이선스 없음'),
    'www.pharm.or.kr':                       ('🟡', '대한약사회',         '대한약사회 공식. ToS 확인 필요'),
}

UNKNOWN_CLASS = ('🔴', '출처 불명', '미분류 호스트 — 추가 조사 필요')

def classify(url: str):
    if not url:
        return ('🔴', 'URL 없음', 'image_url 누락')
    host = urlparse(url).netloc.lower()
    return HOST_CLASS.get(host, UNKNOWN_CLASS)

# Bucket products
buckets = defaultdict(list)  # icon → list of (id, brand, name, host, license_note, verified_date)
for p in PRODUCTS:
    url = p.get('image_url', '')
    icon, label, note = classify(url)
    host = urlparse(url).netloc.lower() if url else ''
    buckets[icon].append({
        'id': p['id'],
        'brand': p.get('brand', ''),
        'name': p.get('name', ''),
        'host': host,
        'source': label,
        'note': note,
        'verified_date': p.get('verified_date', ''),
    })

# Order: 🔴 → 🟡 → 🟢
ORDER = ['🔴', '🟡', '🟢']
total = len(PRODUCTS)
count_by_icon = {k: len(v) for k, v in buckets.items()}

# ---- Compose markdown ----
today = '2026-05-09'
md = []
md.append('# 제품 사진 출처 분류 — V1 출시 전 audit\n')
md.append(f'시행일: {today}  ')
md.append('대상: `assets/data/products.json` 250개 제품의 `image_url` 필드  ')
md.append('방법: URL host 기준 분류 (host 27종 → 4 카테고리)\n')

md.append('## 분류 기준\n')
md.append('| 아이콘 | 의미 | 처리 방향 |')
md.append('|---|---|---|')
md.append('| 🔴 | 라이선스 리스크 높음 — 출시 전 폐기 후보 | 자체 일러스트 또는 공식 출처로 교체 |')
md.append('| 🟡 | 조건부 — 인용 컨텍스트면 가능 / 매체 협의 필요 | 사용 시 ToS 검토 + 출처 표기 |')
md.append('| 🟢 | 공식·공공 — 사용 가능성 높음 | 각 ToS 별도 확인 후 사용 |')
md.append('')

md.append('## 요약\n')
md.append('| 분류 | 건수 | 비율 |')
md.append('|---|---|---|')
for icon in ORDER:
    n = count_by_icon.get(icon, 0)
    md.append(f'| {icon} | {n} | {n/total*100:.1f}% |')
md.append(f'| **합계** | **{total}** | **100.0%** |')
md.append('')

md.append('## 호스트별 분류\n')
md.append('| 호스트 | 출처명 | 분류 | 라이선스 추정 | 제품 수 |')
md.append('|---|---|---|---|---|')
host_counts = defaultdict(int)
for items in buckets.values():
    for it in items:
        host_counts[it['host']] += 1
for host, n in sorted(host_counts.items(), key=lambda x: -x[1]):
    icon, label, note = HOST_CLASS.get(host, UNKNOWN_CLASS) if host else ('🔴', 'URL 없음', 'image_url 누락')
    md.append(f'| `{host or "(없음)"}` | {label} | {icon} | {note} | {n} |')
md.append('')

md.append('## 제품별 상세\n')
md.append('각 제품의 사진 출처. **다운로드 일자**는 `products.json`의 `verified_date` 필드 (entry 검증 시점 — 이미지 확보 시점과 동일하거나 이전).\n')

for icon in ORDER:
    items = buckets.get(icon, [])
    if not items:
        continue
    section_title = {
        '🔴': '🔴 폐기 후보',
        '🟡': '🟡 조건부 (ToS 검토 필요)',
        '🟢': '🟢 공식·공공 (사용 가능성 높음)',
    }[icon]
    md.append(f'### {section_title} — {len(items)}개\n')
    md.append('| 제품ID | 브랜드 | 상품명 | 사진 출처 | 라이선스 추정 | 다운로드 일자 |')
    md.append('|---|---|---|---|---|---|')
    items_sorted = sorted(items, key=lambda x: (x['source'], x['brand'], x['name']))
    for it in items_sorted:
        md.append(
            f"| `{it['id']}` | {it['brand']} | {it['name']} | "
            f"{it['source']} (`{it['host'] or '없음'}`) | {it['note']} | {it['verified_date']} |"
        )
    md.append('')

md.append('## 권고\n')
md.append(
    '- 🔴 분류 ' f'{count_by_icon.get("🔴", 0)}개는 출시 전 폐기 대상. '
    '자체 카테고리 일러스트 폴백 또는 공식 출처 재수집으로 교체.\n'
    '- 🟡 ' f'{count_by_icon.get("🟡", 0)}개는 사용 시 출처 표기 + ToS 검토 필수.\n'
    '- 🟢 ' f'{count_by_icon.get("🟢", 0)}개는 각 제조사·기관 ToS 확인 후 사용 가능성 높음.\n'
    '- 후속 단계 (출시 직전):\n'
    '  - 🔴 사진 파일 (`assets/images/products/{id}.jpg`) 일괄 삭제 → ProductImage 위젯이 카테고리 일러스트로 폴백\n'
    '  - 🟡 / 🟢 보존하되 출처 명시 (이용약관/면책 화면)\n'
    '  - V1.x: 사용자가 직접 등록한 사진(이미 manual entry에 도입됨)이 누적되면 큐레이션 사진 의존도 감소\n'
)

OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_text('\n'.join(md), encoding='utf-8')

print(f'WROTE {OUT}')
print(f'  rows: {total}')
for icon in ORDER:
    n = count_by_icon.get(icon, 0)
    print(f'  {icon}: {n} ({n/total*100:.1f}%)')
