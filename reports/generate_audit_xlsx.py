"""
Generate the V1 product image audit xlsx from the Agent's research findings.
Inputs:
  - assets/data/products.json (250 entries)
  - findings hard-coded below from the Agent's structured report
Output:
  - reports/product_image_audit_2026-05-09.xlsx (4 sheets)
"""
import json
from pathlib import Path
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

ROOT = Path(__file__).resolve().parents[1]
PRODUCTS = json.loads((ROOT / "assets/data/products.json").read_text(encoding="utf-8"))["products"]
OUT = ROOT / "reports" / "product_image_audit_2026-05-09.xlsx"

# ---- Findings from the Agent's research (Part 1, Part 2) ----
# Per-brand assessment.
# match_class: "공공데이터" / "제조사보도자료" / "일러스트폴백" / "확인 필요"
# tos_clarity: "명시" / "모호" / "없음" / "확인 필요"
BRAND_FINDINGS = {
    # 보도자료/뉴스룸 페이지가 확인된 브랜드 (이미지 존재, ToS 모호)
    "대웅제약":          {"site": "https://daewoong.co.kr",                       "press": "https://newsroom.daewoong.co.kr/",                                "tos": "모호",  "match": "제조사보도자료", "note": "별도 뉴스룸 도메인. TLS 인증서 호스트명 오류로 직접 접근 불확실"},
    "임팩타민":          {"site": "https://daewoong.co.kr",                       "press": "https://newsroom.daewoong.co.kr/",                                "tos": "모호",  "match": "제조사보도자료", "note": "대웅제약 브랜드 — newsroom.daewoong.co.kr 공유"},
    "CJ 웰케어":         {"site": "https://cjwellcare.com/",                      "press": "https://cjnews.cj.net/tag/cj웰케어/",                              "tos": "모호",  "match": "제조사보도자료", "note": "CJ 그룹 통합 뉴스룸 32+건. 미디어 자산 라이브러리 언급"},
    "정관장":            {"site": "https://www.kgc.co.kr/",                       "press": "https://www.kgc.co.kr/media-center/kgc-notice/list.do",            "tos": "모호",  "match": "제조사보도자료", "note": "미디어센터 보유 (KGC소식·매거진·라이브KGC)"},
    "센트룸":            {"site": "https://www.pfizer.co.kr/",                    "press": "https://www.pfizer.co.kr/media/",                                  "tos": "모호",  "match": "제조사보도자료", "note": "한국화이자 미디어 섹션. 이미지 사용 가이드라인 명시 미발견"},
    "바이엘":            {"site": "https://www.bayer.com/ko/kr/korea-home",       "press": "https://www.bayer.com/en/kr/korea-local-news-",                    "tos": "모호",  "match": "제조사보도자료", "note": "글로벌 본사 가이드라인 적용 가능성"},
    "SK케미칼":          {"site": "https://www.skchemicals.com/",                 "press": "https://www.skchemicals.com/ir/ir_public.aspx",                    "tos": "모호",  "match": "제조사보도자료", "note": "IR 페이지에 보도자료. 봇 차단(403)으로 직접 확인 불가"},

    # 공식 사이트는 있으나 보도자료/뉴스룸 미확인 (사이트 자체에 미디어 섹션 없음)
    "종근당건강":        {"site": "https://www.ckdhc.com/",                       "press": "",                                                                  "tos": "없음",  "match": "일러스트폴백",   "note": "홈 메뉴에 뉴스룸 미노출. 모회사 종근당 IR 별도. 250개 중 최다 (40개) — PR팀 직접 협의 우선순위 1"},
    "종근당":            {"site": "https://www.ckdpharm.com/",                    "press": "",                                                                  "tos": "없음",  "match": "일러스트폴백",   "note": "종근당건강과 별도 법인. 자체 뉴스룸 미확인"},
    "솔가":              {"site": "http://solgarkorea.com/",                      "press": "",                                                                  "tos": "없음",  "match": "확인 필요",     "note": "한국 솔가(블루존닷컴 운영). 사이트 ECONNREFUSED. Solgar 영문 라벨과 합산 시 24개"},
    "Solgar":            {"site": "http://solgarkorea.com/",                      "press": "",                                                                  "tos": "없음",  "match": "확인 필요",     "note": "솔가와 동일 브랜드. brand 라벨 통합 권장"},
    "애터미":            {"site": "https://kr.atomy.com/main",                    "press": "https://ch.atomy.com",                                              "tos": "모호",  "match": "확인 필요",     "note": "채널애터미에 매거진/카탈로그. 보도자료 외부(newswire.co.kr) 의존. 라이선스 명시 X"},
    "나우푸드":          {"site": "https://nowfoods.co.kr/",                      "press": "",                                                                  "tos": "없음",  "match": "일러스트폴백",   "note": "한국 디스트리뷰터(드림리더) 쇼핑몰. 보도자료 섹션 없음"},
    "GNC":               {"site": "http://www.gnckorea.kr/",                      "press": "",                                                                  "tos": "없음",  "match": "확인 필요",     "note": "TLS 인증서 호스트명 오류로 접근 불가"},
    "노르딕내추럴스":     {"site": "https://nordicnaturals.kr/",                  "press": "",                                                                  "tos": "없음",  "match": "일러스트폴백",   "note": "한국 디스트리뷰터 사이트. 자체 뉴스룸 없음"},
    "고려은단":          {"site": "https://eundan.com/",                          "press": "",                                                                  "tos": "없음",  "match": "일러스트폴백",   "note": "YouTube/Instagram 운영. 자체 뉴스룸 미확인"},
    "마이프로틴":        {"site": "https://us.myprotein.com/",                    "press": "",                                                                  "tos": "없음",  "match": "일러스트폴백",   "note": "글로벌 사이트. 자체 한국 사이트 없음. 보도자료 외부(newswire) 배포"},
    "뉴트리":            {"site": "https://www.nutrione.co.kr/",                  "press": "",                                                                  "tos": "없음",  "match": "확인 필요",     "note": "쇼핑몰 위주. 코스닥 상장사 IR 별도"},
    "GNM자연의품격":     {"site": "https://gnmart.co.kr",                         "press": "",                                                                  "tos": "없음",  "match": "일러스트폴백",   "note": "CJ온스타일/올리브영 등 유통 의존. 자체 뉴스룸 미확인"},
    "유한양행 뉴오리진": {"site": "https://www.neworigin.co.kr/",                  "press": "",                                                                  "tos": "없음",  "match": "일러스트폴백",   "note": "홈에 뉴스룸 미노출. 모회사 유한양행/유한건강생활 IR 별도"},
    "유한양행":          {"site": "https://www.yuhan.co.kr/",                     "press": "",                                                                  "tos": "없음",  "match": "확인 필요",     "note": "Agent 미조사. 본사 IR 페이지 추정"},
    "다림바이오텍":      {"site": "",                                              "press": "",                                                                  "tos": "없음",  "match": "확인 필요",     "note": "공식 사이트 URL 미확정 — 추가 조사 필요"},

    # 다브랜드 (실제 브랜드 미확정)
    "다브랜드":          {"site": "",                                              "press": "",                                                                  "tos": "확인 필요", "match": "확인 필요",     "note": "products.json에 'brand=다브랜드' 23개 — 실제 제조사 식별 작업 필요"},
}

# Default for brands the agent didn't survey: assume "일러스트폴백" with "Agent 미조사" note.
DEFAULT_FINDING = {"site": "", "press": "", "tos": "없음", "match": "일러스트폴백", "note": "Agent 미조사 (브랜드 단위 후속 조사 필요)"}

DATASETS = [
    {
        "name": "식품의약품안전처_건강기능식품정보 (OpenAPI)",
        "url": "https://www.data.go.kr/data/15056760/openapi.do",
        "agency": "식품의약품안전처",
        "kogl": "이용허락 제한 없음 (제1유형 상응)",
        "image_field": "없음",
        "api_auth": "필요 (개발 10,000건/일)",
        "matched": 0,
        "note": "텍스트 메타데이터만 — 업체명/제품명/품목제조관리번호/성상/용도용법/섭취량/유통기한. 이미지 필드 부재. 텍스트 무결성 검증용으로는 활용 가능",
    },
    {
        "name": "식품의약품안전처_건강기능식품 품목제조신고(원재료)",
        "url": "https://www.data.go.kr/data/15061756/openapi.do",
        "agency": "식품의약품안전처",
        "kogl": "이용허락 제한 없음",
        "image_field": "없음",
        "api_auth": "필요",
        "matched": 0,
        "note": "원재료/원료 정보 위주",
    },
    {
        "name": "식품의약품안전처_건강기능식품 영양DB",
        "url": "https://www.data.go.kr/data/15085712/openapi.do",
        "agency": "식품의약품안전처",
        "kogl": "이용허락 제한 없음",
        "image_field": "없음",
        "api_auth": "필요",
        "matched": 0,
        "note": "원료 분류·영양 정보",
    },
    {
        "name": "전국건강기능식품영양성분정보표준데이터",
        "url": "https://www.data.go.kr/data/15155983/standard.do",
        "agency": "식약처(표준)",
        "kogl": "표준데이터 (제1유형 통상)",
        "image_field": "없음",
        "api_auth": "파일다운로드",
        "matched": 0,
        "note": "영양성분 표준 — 이미지 부재",
    },
    {
        "name": "건강기능식품 종합정보 서비스 (data.mfds.go.kr)",
        "url": "https://data.mfds.go.kr/hid/main/main.do",
        "agency": "식약처",
        "kogl": "사이트 'All Rights Reserved' 표시 — 데이터 배포 X",
        "image_field": "카테고리 아이콘만 (제품 이미지 X)",
        "api_auth": "—",
        "matched": 0,
        "note": "일반 검색 서비스 (UI). 데이터 배포는 위 OpenAPI 우회",
    },
]


# ---- Style helpers ----
HEADER_FILL = PatternFill(start_color="1F4E78", end_color="1F4E78", fill_type="solid")
HEADER_FONT = Font(color="FFFFFF", bold=True, size=11)
HEADER_ALIGN = Alignment(horizontal="left", vertical="center", wrap_text=True)
BODY_ALIGN = Alignment(horizontal="left", vertical="top", wrap_text=True)
THIN = Side(border_style="thin", color="BFBFBF")
BORDER = Border(left=THIN, right=THIN, top=THIN, bottom=THIN)

ROW_FILL_BY_MATCH = {
    "제조사보도자료": PatternFill(start_color="FFF4D6", end_color="FFF4D6", fill_type="solid"),
    "공공데이터":     PatternFill(start_color="D9F2D9", end_color="D9F2D9", fill_type="solid"),
    "확인 필요":      PatternFill(start_color="FCE5CD", end_color="FCE5CD", fill_type="solid"),
    "일러스트폴백":   PatternFill(start_color="F0F0F0", end_color="F0F0F0", fill_type="solid"),
}


def style_header(ws, row=1):
    for cell in ws[row]:
        cell.fill = HEADER_FILL
        cell.font = HEADER_FONT
        cell.alignment = HEADER_ALIGN
        cell.border = BORDER


def auto_width(ws, widths):
    for i, w in enumerate(widths, start=1):
        ws.column_dimensions[get_column_letter(i)].width = w


def add_borders(ws, max_row, max_col):
    for r in range(2, max_row + 1):
        for c in range(1, max_col + 1):
            cell = ws.cell(row=r, column=c)
            cell.border = BORDER
            cell.alignment = BODY_ALIGN


# ---- Build workbook ----
wb = Workbook()

# Sheet 1: 제품 매칭 결과
ws1 = wb.active
ws1.title = "제품 매칭 결과"
ws1.append(["제품ID", "제조사", "상품명", "카테고리", "매칭결과", "이미지URL후보", "라이선스근거", "비고"])
style_header(ws1)

# Build per-product rows
for p in PRODUCTS:
    brand = p.get("brand", "")
    f = BRAND_FINDINGS.get(brand, DEFAULT_FINDING)
    image_url_candidate = f["press"] if f["match"] == "제조사보도자료" else ""
    license_basis = "보도자료 ToS 모호 — PR팀 협의 필요" if f["match"] == "제조사보도자료" else ("없음" if f["match"] == "일러스트폴백" else "확인 필요")
    ws1.append([
        p["id"],
        brand,
        p.get("name", ""),
        p.get("category", ""),
        f["match"],
        image_url_candidate,
        license_basis,
        f["note"],
    ])

# Apply row tint by match class
for r in range(2, ws1.max_row + 1):
    match_class = ws1.cell(row=r, column=5).value
    fill = ROW_FILL_BY_MATCH.get(match_class)
    if fill is not None:
        for c in range(1, 9):
            ws1.cell(row=r, column=c).fill = fill

add_borders(ws1, ws1.max_row, 8)
auto_width(ws1, [16, 18, 38, 18, 16, 50, 30, 60])
ws1.freeze_panes = "A2"

# Sheet 2: 제조사 정보
ws2 = wb.create_sheet("제조사 정보")
ws2.append(["제조사명", "사이트URL", "보도자료URL", "ToS명시", "보도자료보유", "매칭결과(브랜드)", "제품수", "비고"])
style_header(ws2)

# Aggregate product counts per brand from products.json
import collections
brand_counts = collections.Counter(p.get("brand", "") for p in PRODUCTS)

# Order: brands surveyed by Agent first (descending product count), then default brands
surveyed = sorted(BRAND_FINDINGS.keys(), key=lambda b: -brand_counts.get(b, 0))
for brand in surveyed:
    f = BRAND_FINDINGS[brand]
    n = brand_counts.get(brand, 0)
    ws2.append([
        brand,
        f["site"],
        f["press"],
        f["tos"],
        "있음" if f["press"] else "없음",
        f["match"],
        n,
        f["note"],
    ])

# Append "Agent 미조사" brands (count any brand not in BRAND_FINDINGS)
unsurveyed = sorted([b for b in brand_counts if b not in BRAND_FINDINGS], key=lambda b: -brand_counts[b])
for brand in unsurveyed:
    n = brand_counts[brand]
    ws2.append([
        brand,
        "",
        "",
        "확인 필요",
        "확인 필요",
        "확인 필요",
        n,
        "Agent 미조사 — 후속 브랜드 단위 조사 필요",
    ])

# tint
for r in range(2, ws2.max_row + 1):
    match_class = ws2.cell(row=r, column=6).value
    fill = ROW_FILL_BY_MATCH.get(match_class)
    if fill is not None:
        for c in range(1, 9):
            ws2.cell(row=r, column=c).fill = fill

add_borders(ws2, ws2.max_row, 8)
auto_width(ws2, [22, 40, 50, 12, 14, 16, 8, 60])
ws2.freeze_panes = "A2"

# Sheet 3: 공공데이터 데이터셋
ws3 = wb.create_sheet("공공데이터 데이터셋")
ws3.append(["데이터셋명", "URL", "발급기관", "KOGL등급", "이미지필드", "API인증", "매칭성공", "비고"])
style_header(ws3)
for d in DATASETS:
    ws3.append([d["name"], d["url"], d["agency"], d["kogl"], d["image_field"], d["api_auth"], d["matched"], d["note"]])
add_borders(ws3, ws3.max_row, 8)
auto_width(ws3, [42, 55, 18, 32, 28, 22, 10, 60])
ws3.freeze_panes = "A2"

# Sheet 4: 요약
ws4 = wb.create_sheet("요약")
total = len(PRODUCTS)

# Totals by match class
by_match = collections.Counter()
for p in PRODUCTS:
    f = BRAND_FINDINGS.get(p.get("brand", ""), DEFAULT_FINDING)
    by_match[f["match"]] += 1

n_press   = by_match.get("제조사보도자료", 0)
n_data    = by_match.get("공공데이터", 0)
n_check   = by_match.get("확인 필요", 0)
n_illust  = by_match.get("일러스트폴백", 0)

press_brands_with_url = sum(1 for v in BRAND_FINDINGS.values() if v["press"])
tos_explicit = sum(1 for v in BRAND_FINDINGS.values() if v["tos"] == "명시")

ws4.append(["[제품 매칭 분포 — 250개 기준]"])
ws4.append([])
ws4.append(["분류", "건수", "비율"])
style_header(ws4, row=3)
ws4.append(["공공데이터 매칭",      n_data,   f"{n_data/total*100:.1f}%"])
ws4.append(["제조사 보도자료 매칭",  n_press,  f"{n_press/total*100:.1f}%"])
ws4.append(["확인 필요",             n_check,  f"{n_check/total*100:.1f}%"])
ws4.append(["일러스트 폴백 필요",    n_illust, f"{n_illust/total*100:.1f}%"])
ws4.append(["합계",                  total,    "100.0%"])
ws4.append([])
ws4.append(["[조사 통계]"])
ws4.append([])
ws4.append(["항목", "값"])
style_header(ws4, row=11)
ws4.append(["조사한 브랜드",                          len(BRAND_FINDINGS)])
ws4.append(["전체 브랜드(products.json)",             len(brand_counts)])
ws4.append(["보도자료 페이지 URL 보유 브랜드",         press_brands_with_url])
ws4.append(["ToS 명시 보유 브랜드",                    tos_explicit])
ws4.append(["발견된 공공데이터 데이터셋",              len(DATASETS)])
ws4.append(["이미지 필드 보유 데이터셋",                0])
ws4.append([])
ws4.append(["[핵심 결론]"])
ws4.append([])
notes = [
    "1. 공공데이터(data.go.kr / 식약처 API)에는 제품 이미지 필드가 부재 — 매칭 0건",
    "2. 제조사 보도자료/뉴스룸 보유 브랜드: 6개 (대웅제약·임팩타민, CJ웰케어, 정관장, 센트룸/화이자, 바이엘, SK케미칼) — 합계 약 32개 제품",
    "3. 단, 모든 브랜드의 ToS는 '모호' — 보도자료 이미지를 앱 카탈로그에 상시 노출하는 권리는 별도 협의 필요",
    "4. 솔가(18) + Solgar(6) = 24개는 동일 브랜드, products.json brand 라벨 통합 권장",
    "5. '다브랜드' 23개는 실제 제조사 미확정 — 후속 식별 작업 필요",
    "6. 외국계 브랜드 한국 지사 사이트 다수 접근 불가 (GNC TLS 오류, 솔가 ECONNREFUSED, SK케미칼 403)",
    "",
    "[권고]",
    "A. 보도자료 매칭 가능 브랜드(상위 6개, 32개 제품)에 대해서만 PR팀 메일 협의 → 명시적 라이선스 확보",
    "B. 그 외 ~218개 제품(87%)은 카테고리/원료 아이콘 기반 일러스트 폴백으로 우선 출시",
    "C. 식약처 OpenAPI(KOGL 1유형, 인증키 필요)는 텍스트 무결성 검증용으로 별도 단계에서 활용",
    "D. 다음 단계 진행 전 사용자 결정: 보도자료 이미지를 '뉴스 인용' 명목으로 일부 활용할지 vs. 100% 자체 일러스트로 단순화할지",
]
for line in notes:
    ws4.append([line])

auto_width(ws4, [60, 12, 12])
ws4.freeze_panes = "A2"

OUT.parent.mkdir(parents=True, exist_ok=True)
wb.save(OUT)
print(f"WROTE {OUT}")
print(f"  rows: 제품={ws1.max_row-1}, 제조사={ws2.max_row-1}, 데이터셋={ws3.max_row-1}")
print(f"  match split — 보도자료:{n_press}, 공공:{n_data}, 확인필요:{n_check}, 폴백:{n_illust}")
