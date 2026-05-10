# 제품 사진 출처 분류 — V1 출시 전 audit

시행일: 2026-05-09  (분류) / 2026-05-10 (폐기 처리)
대상: `assets/data/products.json` 250개 제품의 `image_url` 필드  
방법: URL host 기준 분류 (host 27종 → 3 카테고리)

## 분류 기준

| 아이콘 | 의미 | 처리 방향 | V1 출시 처리 |
|---|---|---|---|
| 🔴 | 라이선스 리스크 높음 — 출시 전 폐기 후보 | 자체 일러스트 또는 공식 출처로 교체 | **폐기 완료 (jpg 삭제)** |
| 🟡 | 조건부 — 인용 컨텍스트면 가능 / 매체 협의 필요 | 사용 시 ToS 검토 + 출처 표기 | **폐기 완료 (jpg 삭제, V1엔 안전 우선)** |
| 🟢 | 공식·공공 — 사용 가능성 높음 | 각 ToS 별도 확인 후 사용 | **잔존 (37 / 250)** |

## 요약

| 분류 | 분류 시점 | V1 출시 빌드 | 비율 |
|---|---|---|---|
| 🔴 | 203 | 0 (전부 폐기) | 81.2% → 0% |
| 🟡 | 10 | 0 (전부 폐기) | 4.0% → 0% |
| 🟢 | 37 | 37 (잔존) | 14.8% → 14.8% |
| **합계** | **250** | **37** | **100.0% → 14.8%** |

## 출시 처리 결과 — 2026-05-10

V1 출시 단계 14 부분 작업으로 라이선스 위험군 사진 213장(🔴 203 + 🟡 10) 일괄 폐기.
- 폐기 방식: `assets/images/products/{id}.jpg` 파일 삭제
- 자동 폴백: `lib/core/widgets/product_image.dart` 의 `Image.asset` `errorBuilder`
  → `_CategoryFallback` (카테고리별 이모지 + 부드러운 배경)
- `products.json` 의 `image_url` 메타는 별도 작업에서 처리 예정 (출시 단계 14 명시 범위 외)
- 회귀 가드: `test/product_image_purge_test.dart` — 잔존 37 셋 양방향 락
  (폐기된 jpg 가 다시 추가되거나, 잔존 jpg 가 사라지면 fail)

## 호스트별 분류

| 호스트 | 출처명 | 분류 | 라이선스 추정 | 제품 수 |
|---|---|---|---|---|
| `img.danuri.io` | 다나와 | 🔴 | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 156 |
| `imgproxy.pillyze.io` | 필라이즈 프록시 | 🔴 | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 35 |
| `image.atomy.com` | 애터미 공식 | 🟢 | 제조사 공식 CDN | 14 |
| `common.health.kr` | 약학정보원 | 🟢 | 공공 의약품 정보 사이트. ToS 별도 확인 권고 | 10 |
| `cdn.pillyze.io` | 필라이즈 CDN | 🔴 | 제3자 앱 CDN. 라이선스 없음 | 4 |
| `gradium.co.kr` | 그라디움 공식 | 🟢 | 제조사 공식 사이트 | 3 |
| `cdn.kpanews.co.kr` | 약사공론 | 🟡 | 약사공론 (전문 매체). 보도 인용 가능, 앱 카탈로그 사용은 모호 | 3 |
| `cloudinary.images-iherb.com` | 아이허브 | 🟡 | 마켓플레이스 CDN. 제품 표시 용도 일반적이나 ToS 확인 필요 | 3 |
| `cdn.shopify.com` | Shopify 쇼핑몰 | 🔴 | 제3자 쇼핑몰 캐시. 라이선스 없음 | 2 |
| `impactamin.kr` | 임팩타민 공식 | 🟢 | 제조사 공식 사이트 (대웅제약) | 2 |
| `cjwellcare.com` | CJ웰케어 공식 | 🟢 | 제조사 공식 사이트 | 2 |
| `www.costco.co.kr` | 코스트코 | 🔴 | 대형 마트 사이트. 라이선스 없음 | 1 |
| `godomall.speedycdn.net` | 고도몰 | 🔴 | 쇼핑몰 솔루션 CDN. 라이선스 없음 | 1 |
| `hilifevitamins.com` | HiLife (해외) | 🔴 | 해외 쇼핑몰. 라이선스 모호 | 1 |
| `d2m9duoqjhyhsq.cloudfront.net` | CloudFront 익명 | 🔴 | CloudFront 호스팅 — 원 출처 불명 | 1 |
| `cdn-pro-web-251-108.cdn-nhncommerce.com` | NHN 커머스 | 🔴 | 쇼핑몰 솔루션 CDN. 라이선스 없음 | 1 |
| `2pharmacy.gr` | 그리스 약국 | 🔴 | 해외 약국 사이트. 라이선스 없음 | 1 |
| `image.greating.co.kr` | 그리팅 공식 | 🟢 | 제조사 공식 사이트 | 1 |
| `www.duolac.co.kr` | 듀오락 공식 | 🟢 | 제조사 공식 사이트 | 1 |
| `hanminutrition.b-cdn.net` | 한미양행 공식 | 🟢 | 제조사 공식 CDN | 1 |
| `healthmap.co.kr` | 헬스맵 공식 | 🟢 | 제조사 공식 사이트 | 1 |
| `health-benefit.co.kr` | 헬스베네핏 공식 | 🟢 | 제조사 공식 사이트 | 1 |
| `rpspharmacy.com` | RPS 약국 공식 | 🟢 | 제조사 공식 사이트 (해외) | 1 |
| `img.khan.co.kr` | 경향신문 | 🟡 | 경향신문 보도 이미지. 인용 외 사용 X | 1 |
| `www.pharm.or.kr` | 대한약사회 | 🟡 | 대한약사회 공식. ToS 확인 필요 | 1 |
| `img1.daumcdn.net` | 다음 캐시 | 🟡 | 다음 검색 캐시 — 원 출처 불명 | 1 |
| `images.ctfassets.net` | Contentful CDN | 🟡 | Contentful 호스팅 CDN — 원 매체 확인 필요 | 1 |

## 제품별 상세

각 제품의 사진 출처. **다운로드 일자**는 `products.json`의 `verified_date` 필드 (entry 검증 시점 — 이미지 확보 시점과 동일하거나 이전).

### 🔴 폐기 완료 — 203개 (2026-05-10, V1 출시 빌드에서 제거)

| 제품ID | 브랜드 | 상품명 | 사진 출처 | 라이선스 추정 | 다운로드 일자 |
|---|---|---|---|---|---|
| `black_maca_general` | 다브랜드 | 블랙 마카 (일반) | CloudFront 익명 (`d2m9duoqjhyhsq.cloudfront.net`) | CloudFront 호스팅 — 원 출처 불명 | 2026-05-06 |
| `natures_way_evening_primrose_1300` | 네이처스웨이 | 네이처스웨이 이브닝프림로즈 1300 | HiLife (해외) (`hilifevitamins.com`) | 해외 쇼핑몰. 라이선스 모호 | 2026-05-06 |
| `meditree_psyllium` | 메디트리 | 메디트리 비움 차전자피 식이섬유 | NHN 커머스 (`cdn-pro-web-251-108.cdn-nhncommerce.com`) | 쇼핑몰 솔루션 CDN. 라이선스 없음 | 2026-05-06 |
| `nordic_kids_dha_capsule` | 노르딕내추럴스 | 노르딕 내추럴스 어린이 DHA (캡슐) | Shopify 쇼핑몰 (`cdn.shopify.com`) | 제3자 쇼핑몰 캐시. 라이선스 없음 | 2026-05-06 |
| `nordic_ultimate_omega` | 노르딕내추럴스 | 노르딕 내추럴스 얼티메이트 오메가 | Shopify 쇼핑몰 (`cdn.shopify.com`) | 제3자 쇼핑몰 캐시. 라이선스 없음 | 2026-05-06 |
| `esther_boswellia` | 에스더포뮬러 | 여에스더 관절엔 보스웰리아 | 고도몰 (`godomall.speedycdn.net`) | 쇼핑몰 솔루션 CDN. 라이선스 없음 | 2026-05-06 |
| `solgar_l_arginine_1000` | 솔가 | 솔가 L-아르기닌 1000mg | 그리스 약국 (`2pharmacy.gr`) | 해외 약국 사이트. 라이선스 없음 | 2026-05-06 |
| `cj_byocore_100` | CJ 웰케어 | CJ 바이오코어 건강한 생유산균 100억 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `drbest_high_abs_mg_200` | Doctor's Best | 닥터스베스트 고흡수 마그네슘 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `gnc_lutein_20` | GNC | GNC 루테인 20mg | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `gnc_lutein_40` | GNC | GNC 루테인 40mg | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `gnc_saw_palmetto` | GNC | GNC 맨스 쏘팔메토 포뮬러 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `gnc_megamen` | GNC | GNC 메가맨 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `gnc_megaman` | GNC | GNC 메가맨 멀티비타민 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `gnc_selenium_100` | GNC | GNC 셀레늄 100mcg | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `gnc_zinc_30` | GNC | GNC 아연 30 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `gnc_womens_ultra_mega` | GNC | GNC 우먼스 울트라메가 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `gnc_womens_ultramega` | GNC | GNC 우먼스 울트라메가 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `gnm_milk_thistle_full` | GNM자연의품격 | GNM 건강한 간 밀크씨슬 (풀 패널) | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `gnm_multi_15` | GNM자연의품격 | GNM 종합비타민 미네랄 15 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `gnm_milk_thistle` | GNM자연의품격 | 지엔엠 건강한 간 밀크씨슬 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `lifeextension_bcomplex` | Life Extension | 라이프익스텐션 바이오액티브 컴플리트 B-컴플렉스 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `now_biotin_5000` | NOW Foods | NOW 비오틴 5000mcg | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `now_vit_d3_2000` | NOW Foods | NOW 비타민 D3 2000IU | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `solgar_men_multi` | Solgar | 솔가 남성용 멀티비타민&미네랄 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `solgar_b_complex_100_v2` | Solgar | 솔가 비타민B 컴플렉스 100 (정확 패널) | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `solgar_women_multi` | Solgar | 솔가 여성용 멀티비타민&미네랄 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `solgar_omega3_950` | Solgar | 솔가 오메가3 EPA & DHA 950 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `solgar_camg_citrate` | Solgar | 솔가 칼슘 마그네슘 시트레이트 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `solgar_coq10_100` | Solgar | 솔가 코엔자임 Q10 100mg | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `thorne_basic_b` | Thorne Research | 쏜리서치 베이직 B 컴플렉스 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `eundan_vit_c_1000` | 고려은단 | 고려은단 비타민C 1000 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `eundan_vit_c_easy_d` | 고려은단 | 고려은단 비타민C 1000 이지 + 비타민D | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `eundan_vit_c_gold_plus` | 고려은단 | 고려은단 비타민C 골드플러스 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `eundan_kids_multi` | 고려은단 | 고려은단 키즈 멀티비타민 츄정 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `kwangdong_vita500_stick` | 광동제약 | 광동 비타500 데일리 스틱 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `now_adam` | 나우푸드 | 나우푸드 ADAM 슈피리어 맨스 멀티 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `now_coq10_100` | 나우푸드 | 나우푸드 CoQ10 100mg | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `now_eve` | 나우푸드 | 나우푸드 EVE 슈페리어 우먼스 멀티 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `now_l_theanine_200` | 나우푸드 | 나우푸드 L-테아닌 200mg | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `now_d3_1000` | 나우푸드 | 나우푸드 비타민D3 1000IU | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `now_selenium_100` | 나우푸드 | 나우푸드 셀레늄 100mcg | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `now_zinc_50` | 나우푸드 | 나우푸드 아연 50mg | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `now_psyllium_husk` | 나우푸드 | 나우푸드 차전자피 분말 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `estrog100` | 내츄럴엔도텍 | EstroG-100 (백수오 등 복합추출물) | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `naturebon_vit_d_5000` | 네이처본 | 네이처본 비타민D 5000IU | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `nordic_baby_dha` | 노르딕내추럴스 | 노르딕 내추럴스 베이비 DHA | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `nordic_kids_dha` | 노르딕내추럴스 | 노르딕 내추럴스 어린이 DHA 리퀴드 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `nordic_omega_2x_mini` | 노르딕내추럴스 | 노르딕 내추럴스 얼티메이트 오메가 2X 미니 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `nordic_complete_junior` | 노르딕내추럴스 | 노르딕 내추럴스 컴플리트 주니어 오메가3 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `hansamin_kids_redginseng` | 농협홍삼 한삼인 | 농협 한삼인 아이홍삼 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `bblab_collagen_1500` | 뉴트리원 비비랩 | 비비랩 더 콜라겐 1500 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `bblab_zino_free_vag` | 뉴트리원 비비랩 | 비비랩 지노프리 질유산균 리스펙타프로 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `eaa_general` | 다브랜드 | EAA 필수 아미노산 9종 (일반) | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `nac_general` | 다브랜드 | N-아세틸시스테인 NAC 600 (일반) | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `glucosamine_general` | 다브랜드 | 글루코사민 1500 (일반) | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `krill_oil_general` | 다브랜드 | 남극 크릴 오일 1000mg (일반) | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `lipo_vit_c_general` | 다브랜드 | 리포좀 비타민C 1000 (일반) | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `spirulina_powder_general` | 다브랜드 | 스피루리나 분말 (일반) | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `astaxanthin_general` | 다브랜드 | 아스타잔틴 영양제 (일반) | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `alpha_lipoic_acid_general` | 다브랜드 | 알파리포산 600mg (일반) | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `lcarnitine_2000` | 다브랜드 | 엘카슬림 L-카르니틴 2000mg (일반) | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `chondroitin_general` | 다브랜드 | 콘드로이틴 1200 (일반) | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `cranberry_general` | 다브랜드 | 크랜베리 추출물 (Cran-Max) 500 (일반) | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `resveratrol_general` | 다브랜드 | 트랜스 레스베라트롤 (일반) | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `active_folate_general` | 다브랜드 | 활성형 엽산 5-MTHF (일반) | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `doctorlin_lutein_zeaxanthin_24` | 닥터린 | 닥터린 루테인 지아잔틴 24 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `doctorlin_melavine` | 닥터린 | 닥터린 멜라바인 (식물성 멜라토닌) | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `orthomol_immun_kr` | 동아제약 | 오쏘몰 이뮨 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `duolac_gold` | 듀오락 | 듀오락 골드 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `lacfido_kids_d_1000` | 락피도 | 락피도 비타민D 츄어블 1000IU 키즈 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `myprotein_l_glutamine` | 마이프로틴 | 마이프로틴 L-글루타민 파우더 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `myprotein_the_whey` | 마이프로틴 | 마이프로틴 THE 웨이 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `myprotein_beta_alanine` | 마이프로틴 | 마이프로틴 베타알라닌 파우더 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `myprotein_citrulline_malate` | 마이프로틴 | 마이프로틴 시트룰린 말레이트 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `myprotein_aakg` | 마이프로틴 | 마이프로틴 아르기닌 알파 케토글루타레이트 (AAKG) | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `selex_core_protein_plus` | 매일헬스뉴트리션 | 셀렉스 코어 프로틴 플러스 (액상) | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `movita_iron_chewable` | 메디포스트 | 메디포스트 모비타 철분 츄어블 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `berocca_bayer` | 바이엘 | 바이엘 베로카 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `elenew_1` | 바이엘 | 바이엘 엘레뉴 1단계 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `elenew_2` | 바이엘 | 바이엘 엘레뉴 2단계 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `elenew_1_full` | 바이엘 | 엘레뉴 1단계 (풀 패널) | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `elevit` | 바이엘 | 엘레비트 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `elevit_pregnancy` | 바이엘 | 엘레비트 임산부 종합비타민 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `desimone_capsule` | 바이오일레븐 | 드시모네 캡슐 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `vitalbeautie_probio_gold` | 바이탈뷰티 | 바이탈뷰티 프로바이오틱스 골드 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `bblab_low_collagen_5000` | 비비랩 | 비비랩 저분자 콜라겐 5000 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `cenovis_men_multi` | 세노비스 | 세노비스 남성 멀티비타민 미네랄 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `cenovis_vit_d_2000` | 세노비스 | 세노비스 비타민D 2000IU | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `cenovis_kids_multi` | 세노비스 | 세노비스 키즈 멀티비타민미네랄 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `centrum_man` | 센트룸 | 센트룸 맨 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `centrum_man_kr` | 센트룸 | 센트룸 맨 (국내) | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `centrum_kids_gummy` | 센트룸 | 센트룸 멀티 구미 키즈 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `centrum_advance_50plus` | 센트룸 | 센트룸 어드밴스 50+ | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `centrum_woman` | 센트룸 | 센트룸 우먼 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `centrum_woman_kr_v2` | 센트룸 | 센트룸 우먼 (국내, 풀 패널) | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `centrum_woman_double_up` | 센트룸 | 센트룸 우먼 더블업 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `centrum_kids` | 센트룸 | 센트룸 포 키즈 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `celltrion_kids_d_2000` | 셀트리온 | 셀트리온 츄어블 비타민D 2000IU | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `solgar_b_complex_100` | 솔가 | 솔가 B-콤플렉스 100 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `solgar_l_theanine_150` | 솔가 | 솔가 L-테아닌 150mg | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `solgar_multi_man` | 솔가 | 솔가 남성용 멀티비타민&미네랄 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `solgar_lutein_40` | 솔가 | 솔가 루테인 40mg | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `solgar_d3_5000` | 솔가 | 솔가 비타민D3 5000IU | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `solgar_selenium_200` | 솔가 | 솔가 셀레늄 200mcg | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `solgar_zinc_50` | 솔가 | 솔가 아연 50 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `solgar_multi_woman` | 솔가 | 솔가 여성용 멀티비타민&미네랄 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `solgar_ca_mg_d3` | 솔가 | 솔가 칼슘 마그네슘 위드 비타민D3 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `solgar_coq10_200` | 솔가 | 솔가 코엔자임 큐텐 200mg | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `solgar_collagen_hyaluronic` | 솔가 | 솔가 콜라겐 히알루론산 콤플렉스 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `tobicom_gold` | 안국약품 | 토비콤 골드 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `tobicom_lutein_zeaxanthin` | 안국약품 | 토비콤 루테인 지아잔틴 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `atomy_vital_color` | 애터미 | 애터미 바이탈컬러 멀티비타민 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `atomy_vital_color_multi` | 애터미 | 애터미 바이탈컬러 멀티비타민 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `atomy_color_multi` | 애터미 | 애터미 컬러푸드 멀티비타민 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `bnr17_bienalsin_pro` | 에이스바이옴 | BNR17 다이어트 유산균 비에날씬 프로 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `njorigin_saw_palmetto_1100` | 엔젯오리진 | 엔젯오리진 쏘팔메토 파워맥스 1100 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `tanacia_q` | 유유제약 | 타나시아큐 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `yuhan_vit_c_1000` | 유한양행 | 유한 비타민C 정 1000mg | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `neworigin_lutein_astaxanthin` | 유한양행 뉴오리진 | 뉴오리진 루테인 아스타잔틴 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `neworigin_lutein_zeaxanthin_astaxanthin` | 유한양행 뉴오리진 | 뉴오리진 루테인지아잔틴 & 아스타잔틴 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `neworigin_vit_d_mushroom` | 유한양행 뉴오리진 | 뉴오리진 비타민D (버섯 비타민D) | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `aronamin_c_plus` | 일동제약 | 아로나민 씨플러스 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `imp_premium` | 임팩타민 | 임팩타민 프리미엄 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `imp_premium_ones` | 임팩타민 | 임팩타민 프리미엄 원스 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `jamieson_kids_d_chewable` | 자미에슨 | 자미에슨 키즈 츄어블 비타민D | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `kgc_hongsam_jung` | 정관장 | 정관장 홍삼정 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `jks_red_ginseng_extract` | 정관장 | 정관장 홍삼정 (홍삼농축액) | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `choa_vit_d_4000_chewable` | 조아제약 | 조아제약 츄어블 비타민D 4000IU | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `ckd_bolgre_prenatal` | 종근당 | 종근당 볼그레 (임산부 철분제) | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `ckd_zinc_plus_30` | 종근당 | 종근당 아연 플러스 30mg | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `ckd_eyeclear_lutein_zea` | 종근당건강 | 아이클리어 루테인지아잔틴 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `ckd_imbita_high_b` | 종근당건강 | 아임비타 고함량 비타민B 컴플렉스 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `ckd_imbita_daily` | 종근당건강 | 아임비타 멀티비타민 데일리 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `ckd_imbita_allinone` | 종근당건강 | 아임비타 멀티비타민미네랄 올인원 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `ckd_glucosamine_premium` | 종근당건강 | 종근당 글루코사민 프리미엄 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `ckd_mg_plus` | 종근당건강 | 종근당 마그네슘 플러스 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `ckd_belderwell_omega3` | 종근당건강 | 종근당 벨더웰 초임계 알티지 오메가3 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `ckd_boswellia_7days` | 종근당건강 | 종근당 보스웰리아 7Days | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `ckd_vit_c_1000` | 종근당건강 | 종근당 비타민C 1000 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `ckd_vit_c_1000_v2` | 종근당건강 | 종근당 비타민C 1000 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `ckd_vit_d_1000` | 종근당건강 | 종근당 비타민D 1000IU | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `ckd_vit_d_1000_v2` | 종근당건강 | 종근당 비타민D 1000IU | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `ckd_vit_d_2000` | 종근당건강 | 종근당 비타민D 2000IU (아임비타) | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `ckd_vit_d_2000_zn` | 종근당건강 | 종근당 비타민D 2000IU + 아연 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `ckd_lutein_zeaxanthin_astaxanthin` | 종근당건강 | 종근당 아이클리어 루테인지아잔틴아스타잔틴 플러스 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `ckd_elastin_collagen` | 종근당건강 | 종근당 엘라스틴 저분자 피쉬 콜라겐 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `ckd_olallme_collagen_3270` | 종근당건강 | 종근당 올앳미 콜라겐 3270 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `ckd_coq10_99` | 종근당건강 | 종근당 코엔자임Q10 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `ckd_krill_oil` | 종근당건강 | 종근당 크릴 오일 1000mg | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `ckd_kids_multivit` | 종근당건강 | 종근당 키즈 멀티비타민 미네랄 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `ckd_active_vit_b_plus` | 종근당건강 | 종근당 활력 비타민B 플러스 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `ckd_glucosamine_plus` | 종근당건강 | 종근당건강 글루코사민 플러스 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `ckd_allatme_303_lcarnitine` | 종근당건강 | 종근당건강 올앳미 303 L-카르니틴 다이어트 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `ckd_allatme_collagen_3270` | 종근당건강 | 종근당건강 올앳미 어린슈퍼콜라겐 3270 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `promega_dual` | 종근당건강 | 프로메가 알티지 오메가3 듀얼 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `promega_triple` | 종근당건강 | 프로메가 오메가3 트리플 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `ckd_promega_triple` | 종근당건강 | 프로메가 오메가3 트리플 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `thegm_more_heme_iron_woman` | 지엠팜 | 더헴철포우먼 (가용성 헴철) | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `kidsten_multi` | 키즈텐 | 키즈텐 어린이 종합비타민 미네랄 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `trueen_rtg_omega3` | 트루엔 | 트루엔 알티지 오메가3 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `oscal_calcium_d` | 한독 | 오스칼 칼슘+D3 | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `hamsoa_kids_red_ginseng` | 함소아제약 | 함소아 홍키통키 프리미어 블루 (어린이 홍삼) | 다나와 (`img.danuri.io`) | 가격비교 사이트 캐시. 라이선스 없음. 출시 전 폐기 | 2026-05-06 |
| `hurum_lutein` | 휴럼 | 휴럼 아이편안 루테인 지아잔틴 | 코스트코 (`www.costco.co.kr`) | 대형 마트 사이트. 라이선스 없음 | 2026-05-06 |
| `orthomol_immun` | 동아제약 / Orthomol | 오쏘몰 이뮨 (동아제약) | 필라이즈 CDN (`cdn.pillyze.io`) | 제3자 앱 CDN. 라이선스 없음 | 2026-05-06 |
| `ckd_coq10_plus_30` | 종근당 | 종근당 코엔자임 Q10 플러스 (30캡슐) | 필라이즈 CDN (`cdn.pillyze.io`) | 제3자 앱 CDN. 라이선스 없음 | 2026-05-06 |
| `ckd_milk_thistle` | 종근당건강 | 종근당 밀크씨슬 | 필라이즈 CDN (`cdn.pillyze.io`) | 제3자 앱 CDN. 라이선스 없음 | 2026-05-06 |
| `ckd_coq10` | 종근당건강 | 종근당 코큐텐 플러스 | 필라이즈 CDN (`cdn.pillyze.io`) | 제3자 앱 CDN. 라이선스 없음 | 2026-05-06 |
| `eundan_megadose_c` | 고려은단 | 고려은단 메가도스C 3000 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `now_milk_thistle` | 나우푸드 | 나우푸드 실리마린 밀크씨슬 익스트랙 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `nordic_omega3_basic` | 노르딕내추럴스 | 노르딕 내추럴스 오메가-3 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `evercollagen_in_up_plus` | 뉴트리 | 에버콜라겐 인앤업 플러스 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `evercollagen_time` | 뉴트리 | 에버콜라겐 타임 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `evercollagen_time_full` | 뉴트리 | 에버콜라겐 타임 (풀 패널) | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `evercollagen_time_biotin` | 뉴트리 | 에버콜라겐 타임 비오틴 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `denps_truvitamin` | 덴프스 | 덴프스 트루바이타민 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `selex_core_protein_pro` | 매일헬스뉴트리션 | 셀렉스 코어 프로틴 프로 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `centrum_silver_man` | 센트룸 | 센트룸 실버 맨 50+ | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `solgar_mg_citrate` | 솔가 | 솔가 마그네슘 시트레이트 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `solgar_mg_b6` | 솔가 | 솔가 마그네슘 위드 비타민B6 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `solgar_milk_thistle_300` | 솔가 | 솔가 밀크씨슬 300 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `solgar_ca_mg_zn` | 솔가 | 솔가 칼슘 마그네슘 플러스 아연 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `aminovital_pro_3800` | 아지노모토 | 아미노바이탈 프로 3800 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `atomy_chinaeng_lacto` | 애터미 | 애터미 친생유산균 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `jks_everytime_limited` | 정관장 | 정관장 에브리타임 리미티드 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `jks_everytime_regular` | 정관장 | 정관장 홍삼정 에브리타임 레귤러 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `jks_everytime_balance` | 정관장 | 정관장 홍삼정 에브리타임 밸런스 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `jks_everytime_soft` | 정관장 | 정관장 홍삼정 에브리타임 소프트 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `lactofit_gold` | 종근당건강 | 락토핏 생유산균 골드 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `lactofit_core` | 종근당건강 | 락토핏 생유산균 코어 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `lactofit_kids` | 종근당건강 | 락토핏 생유산균 키즈 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `lactofit_kids_v2` | 종근당건강 | 락토핏 생유산균 키즈 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `ckd_iron_folate_d_plus` | 종근당건강 | 종근당 철분 엽산 비타민D 플러스 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `ckd_iron_folate_d` | 종근당건강 | 종근당 철분 엽산 비타민D 플러스 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `ckd_ca_mg_d_zn` | 종근당건강 | 종근당 칼슘 앤 마그네슘 비타민D 아연 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `ckd_camgd_zn_v2` | 종근당건강 | 종근당 칼슘 앤 마그네슘 비타민D 아연 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `ckd_ca_mg_d_zn_v2` | 종근당건강 | 종근당 칼슘 앤 마그네슘 비타민D 아연 (1000mg) | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `promega_dual_plus` | 종근당건강 | 프로메가 알티지 오메가3 듀얼 플러스 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `frombio_joint_boswellia` | 프롬바이오 | 프롬바이오 관절연골엔 보스웰리아 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `frombio_boswellia` | 프롬바이오 | 프롬바이오 관절연골엔 보스웰리아 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `pilly_red_ginseng_octacosanol` | 필리 | 필리 홍삼 옥타코사놀 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `yakult_cuperz` | 한국야쿠르트 | 한국야쿠르트 헛개나무 프로젝트 쿠퍼스 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |
| `huons_menolacto` | 휴온스 | 엘루비 메노락토 프로바이오틱스 | 필라이즈 프록시 (`imgproxy.pillyze.io`) | 제3자 앱 CDN (자체 캐시). 라이선스 없음 | 2026-05-06 |

### 🟡 폐기 완료 — 10개 (2026-05-10, V1엔 안전 우선)

| 제품ID | 브랜드 | 상품명 | 사진 출처 | 라이선스 추정 | 다운로드 일자 |
|---|---|---|---|---|---|
| `sportsresearch_omega3_triple` | Sports Research | 스포츠리서치 트리플 스트렝스 오메가3 | Contentful CDN (`images.ctfassets.net`) | Contentful 호스팅 CDN — 원 매체 확인 필요 | 2026-05-06 |
| `solgar_d3_chewable` | 솔가 | 솔가 츄어블 비타민D3 1000IU | 경향신문 (`img.khan.co.kr`) | 경향신문 보도 이미지. 인용 외 사용 X | 2026-05-06 |
| `ckd_joint_pain_quick` | 종근당건강 | 종근당 관절통쾌 콘드로이친 | 다음 캐시 (`img1.daumcdn.net`) | 다음 검색 캐시 — 원 출처 불명 | 2026-05-06 |
| `ginexin_f_40` | SK케미칼 | 기넥신에프정 40mg | 대한약사회 (`www.pharm.or.kr`) | 대한약사회 공식. ToS 확인 필요 | 2026-05-06 |
| `now_magtein` | NOW Foods | NOW 마그테인 마그네슘 L-트레오네이트 | 아이허브 (`cloudinary.images-iherb.com`) | 마켓플레이스 CDN. 제품 표시 용도 일반적이나 ToS 확인 필요 | 2026-05-06 |
| `now_b50` | 나우푸드 | 나우푸드 B-50 | 아이허브 (`cloudinary.images-iherb.com`) | 마켓플레이스 CDN. 제품 표시 용도 일반적이나 ToS 확인 필요 | 2026-05-06 |
| `now_arginine_1000` | 나우푸드 | 나우푸드 L-아르기닌 1000mg | 아이허브 (`cloudinary.images-iherb.com`) | 마켓플레이스 CDN. 제품 표시 용도 일반적이나 ToS 확인 필요 | 2026-05-06 |
| `bcaa_general` | 다브랜드 | BCAA 분지사슬 아미노산 (일반) | 약사공론 (`cdn.kpanews.co.kr`) | 약사공론 (전문 매체). 보도 인용 가능, 앱 카탈로그 사용은 모호 | 2026-05-06 |
| `garcinia_general` | 다브랜드 | 가르시니아 캄보지아 추출물 (일반) | 약사공론 (`cdn.kpanews.co.kr`) | 약사공론 (전문 매체). 보도 인용 가능, 앱 카탈로그 사용은 모호 | 2026-05-06 |
| `creatine_monohydrate` | 다브랜드 | 크레아틴 모노하이드레이트 (일반) | 약사공론 (`cdn.kpanews.co.kr`) | 약사공론 (전문 매체). 보도 인용 가능, 앱 카탈로그 사용은 모호 | 2026-05-06 |

### 🟢 공식·공공 — 37개 (V1 출시 빌드 잔존)

| 제품ID | 브랜드 | 상품명 | 사진 출처 | 라이선스 추정 | 다운로드 일자 |
|---|---|---|---|---|---|
| `cj_byocore_500` | CJ 웰케어 | CJ 바이오코어 건강한 생유산균 500억 | CJ웰케어 공식 (`cjwellcare.com`) | 제조사 공식 사이트 | 2026-05-06 |
| `cj_byocore_skin_immune` | CJ 웰케어 | CJ 바이오코어 피부면역 유산균 | CJ웰케어 공식 (`cjwellcare.com`) | 제조사 공식 사이트 | 2026-05-06 |
| `cla_general` | 다브랜드 | 공액리놀레산 CLA 다이어트 (일반) | RPS 약국 공식 (`rpspharmacy.com`) | 제조사 공식 사이트 (해외) | 2026-05-06 |
| `iherb_lcarnitine` | 다브랜드 | L-카르니틴 타르트레이트 500 (일반) | 그라디움 공식 (`gradium.co.kr`) | 제조사 공식 사이트 | 2026-05-06 |
| `msm_general` | 다브랜드 | MSM (식이유황, 일반) | 그라디움 공식 (`gradium.co.kr`) | 제조사 공식 사이트 | 2026-05-06 |
| `curcumin_general` | 다브랜드 | 강황 추출물 커큐민 95% (일반) | 그라디움 공식 (`gradium.co.kr`) | 제조사 공식 사이트 | 2026-05-06 |
| `solgar_d3_1000` | 솔가 | 솔가 비타민D3 1000IU | 그리팅 공식 (`image.greating.co.kr`) | 제조사 공식 사이트 | 2026-05-06 |
| `duolac_kids` | 듀오락 | 듀오락 키즈 | 듀오락 공식 (`www.duolac.co.kr`) | 제조사 공식 사이트 | 2026-05-06 |
| `atomy_propolis_gummy` | 애터미 | 애터미 그린 프로폴리스 면역 구미 | 애터미 공식 (`image.atomy.com`) | 제조사 공식 CDN | 2026-05-06 |
| `atomy_propolis_gummy_v2` | 애터미 | 애터미 그린 프로폴리스 면역 구미 | 애터미 공식 (`image.atomy.com`) | 제조사 공식 CDN | 2026-05-06 |
| `atomy_megavit_c_2000` | 애터미 | 애터미 바이탈 메가비타민C 2000 | 애터미 공식 (`image.atomy.com`) | 제조사 공식 CDN | 2026-05-06 |
| `atomy_b_complex` | 애터미 | 애터미 비타민B 컴플렉스 | 애터미 공식 (`image.atomy.com`) | 제조사 공식 CDN | 2026-05-06 |
| `atomy_rtg_omega3` | 애터미 | 애터미 알티지 오메가3 | 애터미 공식 (`image.atomy.com`) | 제조사 공식 CDN | 2026-05-06 |
| `atomy_saw_palmetto` | 애터미 | 애터미 오-쏘팔메토 | 애터미 공식 (`image.atomy.com`) | 제조사 공식 CDN | 2026-05-06 |
| `atomy_inner_collagen` | 애터미 | 애터미 이너콜라겐 | 애터미 공식 (`image.atomy.com`) | 제조사 공식 CDN | 2026-05-06 |
| `atomy_psyllium` | 애터미 | 애터미 차전자피 식이섬유 | 애터미 공식 (`image.atomy.com`) | 제조사 공식 CDN | 2026-05-06 |
| `atomy_kids_gummy` | 애터미 | 애터미 키즈 비건 구미 멀티비타민 | 애터미 공식 (`image.atomy.com`) | 제조사 공식 CDN | 2026-05-06 |
| `atomy_kids_probiotics` | 애터미 | 애터미 키즈 프로바이오틱스 | 애터미 공식 (`image.atomy.com`) | 제조사 공식 CDN | 2026-05-06 |
| `atomy_spirulina` | 애터미 | 애터미 퓨어 스피루리나 100% | 애터미 공식 (`image.atomy.com`) | 제조사 공식 CDN | 2026-05-06 |
| `atomy_proactamin` | 애터미 | 애터미 프로팩타민 | 애터미 공식 (`image.atomy.com`) | 제조사 공식 CDN | 2026-05-06 |
| `atomy_hemohim` | 애터미 | 애터미 헤모힘 | 애터미 공식 (`image.atomy.com`) | 제조사 공식 CDN | 2026-05-06 |
| `atomy_hemohim_v2` | 애터미 | 애터미 헤모힘 | 애터미 공식 (`image.atomy.com`) | 제조사 공식 CDN | 2026-05-06 |
| `ginexin_f_120` | SK케미칼 | 기넥신에프정 120mg | 약학정보원 (`common.health.kr`) | 공공 의약품 정보 사이트. ToS 별도 확인 권고 | 2026-05-06 |
| `ginexin_f_80` | SK케미칼 | 기넥신에프정 80mg | 약학정보원 (`common.health.kr`) | 공공 의약품 정보 사이트. ToS 별도 확인 권고 | 2026-05-06 |
| `dikamax_1000` | 다림바이오텍 | 디카맥스 1000 | 약학정보원 (`common.health.kr`) | 공공 의약품 정보 사이트. ToS 별도 확인 권고 | 2026-05-06 |
| `dikamax_d` | 다림바이오텍 | 디카맥스디 | 약학정보원 (`common.health.kr`) | 공공 의약품 정보 사이트. ToS 별도 확인 권고 | 2026-05-06 |
| `donga_dicamax_d` | 다림바이오텍 | 디카맥스디정 | 약학정보원 (`common.health.kr`) | 공공 의약품 정보 사이트. ToS 별도 확인 권고 | 2026-05-06 |
| `5htp_general` | 다브랜드 | 5-HTP 100 (일반) | 약학정보원 (`common.health.kr`) | 공공 의약품 정보 사이트. ToS 별도 확인 권고 | 2026-05-06 |
| `yuhan_beecom_c` | 유한양행 | 삐콤씨정 | 약학정보원 (`common.health.kr`) | 공공 의약품 정보 사이트. ToS 별도 확인 권고 | 2026-05-06 |
| `yuhan_vit_cd` | 유한양행 | 유한 비타민C·D정 | 약학정보원 (`common.health.kr`) | 공공 의약품 정보 사이트. ToS 별도 확인 권고 | 2026-05-06 |
| `aronamin_gold` | 일동제약 | 아로나민 골드 | 약학정보원 (`common.health.kr`) | 공공 의약품 정보 사이트. ToS 별도 확인 권고 | 2026-05-06 |
| `imp_gold` | 임팩타민 | 임팩타민 골드 | 약학정보원 (`common.health.kr`) | 공공 의약품 정보 사이트. ToS 별도 확인 권고 | 2026-05-06 |
| `imp_power_a_plus` | 대웅제약 | 임팩타민 파워 에이플러스 | 임팩타민 공식 (`impactamin.kr`) | 제조사 공식 사이트 (대웅제약) | 2026-05-06 |
| `imp_active` | 임팩타민 | 임팩타민 액티브 | 임팩타민 공식 (`impactamin.kr`) | 제조사 공식 사이트 (대웅제약) | 2026-05-06 |
| `hanmi_mothers_general` | 한미 | 한미 마더스 임산부 종합 | 한미양행 공식 (`hanminutrition.b-cdn.net`) | 제조사 공식 CDN | 2026-05-06 |
| `melatonin_general` | 다브랜드 | 멜라토닌 3mg (일반) | 헬스맵 공식 (`healthmap.co.kr`) | 제조사 공식 사이트 | 2026-05-06 |
| `jks_hongijanggun_2` | 정관장 | 정관장 홍이장군 2단계 (어린이 홍삼) | 헬스베네핏 공식 (`health-benefit.co.kr`) | 제조사 공식 사이트 | 2026-05-06 |

## 권고

- ✅ **🔴 + 🟡 폐기 완료** (2026-05-10) — V1 출시 빌드는 🟢 37장만 보유.
- 🟢 37개는 각 제조사·기관 ToS 별도 확인 후 사용. 출처 표기는 이용약관/면책 화면에 일괄.
- 후속:
  - 🟢 ToS 위반 발견 시 `kAllowedProductImageIds` (test) 에서 제외 + jpg 삭제로 같은 폴백 흐름.
  - V1.x: 사용자가 직접 등록한 사진(`UserProductPhoto`, 단계 7) 이 누적되면 큐레이션 사진 의존도 추가 감소.
  - `products.json` 의 `image_url` 외부 URL 필드 정리는 별도 작업 (V1 단계 14 명시 범위 외).
