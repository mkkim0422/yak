// Supplement search, manual input, guide

function SearchBar({ value = '', placeholder = '영양제 이름이나 성분', icon = '🔍', right }) {
  return (
    <div style={{
      display:'flex', alignItems:'center', gap: 8,
      background: T.surface, borderRadius: 14, padding: '10px 14px',
      boxShadow: T.cardShadow,
    }}>
      <span style={{ fontSize: 16 }}>{icon}</span>
      <div style={{ flex: 1, fontSize: 14.5, color: value ? T.ink : T.faint, fontWeight: value ? 600 : 500 }}>
        {value || placeholder}
      </div>
      {right}
    </div>
  );
}

function SupplementSearchScreen({ state = 'results' }) {
  return (
    <Screen>
      <TopBar title="영양제 검색"/>
      <div style={{ padding: '0 20px 20px' }}>
        <SearchBar value={state === 'empty' ? '' : '센트룸'} right={
          <button style={{
            width: 30, height: 30, borderRadius: 8, border: 'none',
            background: T.primarySoft, display:'flex', alignItems:'center', justifyContent:'center', cursor:'pointer',
          }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
              <rect x="4" y="6" width="16" height="13" rx="2" stroke={T.primary} strokeWidth="1.8"/>
              <circle cx="12" cy="12.5" r="3.5" stroke={T.primary} strokeWidth="1.8"/>
              <path d="M9 6l1-2h4l1 2" stroke={T.primary} strokeWidth="1.8" strokeLinejoin="round"/>
            </svg>
          </button>
        }/>

        {state === 'empty' && (
          <div style={{ marginTop: 56, textAlign:'center' }}>
            <div style={{ fontSize: 44, marginBottom: 16 }}>💊</div>
            <div style={{ fontSize: 17, fontWeight: 700, letterSpacing:'-0.02em', marginBottom: 6 }}>
              어떤 영양제를 찾고 계세요?
            </div>
            <div style={{ fontSize: 13, color: T.muted, lineHeight: 1.5 }}>
              제품명, 성분, 브랜드로 검색할 수 있어요.<br/>
              사진으로도 검색해 보세요.
            </div>

            <div style={{ marginTop: 32, padding: '0 8px' }}>
              <div style={{ fontSize: 12, color: T.muted, fontWeight: 600, marginBottom: 8, textAlign:'left' }}>최근 검색</div>
              <div style={{ display:'flex', flexWrap:'wrap', gap: 8, justifyContent:'flex-start' }}>
                {['오메가3','마그네슘','비타민D','센트룸','GNC'].map((t,i)=>(
                  <Chip key={i}>{t}</Chip>
                ))}
              </div>
            </div>
          </div>
        )}

        {state === 'noresults' && (
          <div style={{ marginTop: 56, textAlign:'center' }}>
            <div style={{ fontSize: 44, marginBottom: 16 }}>🔎</div>
            <div style={{ fontSize: 17, fontWeight: 700, letterSpacing:'-0.02em', marginBottom: 6 }}>
              검색 결과가 없어요
            </div>
            <div style={{ fontSize: 13, color: T.muted, lineHeight: 1.5, marginBottom: 24 }}>
              검증된 제품 데이터베이스에<br/>아직 등록되지 않은 영양제예요.
            </div>
            <PrimaryButton size="md">📨 이 영양제 등록 요청하기</PrimaryButton>
          </div>
        )}

        {state === 'results' && (
          <>
            {/* Tier 1 */}
            <div style={{ marginTop: 20, marginBottom: 10, display:'flex', alignItems:'center', gap: 6, padding:'0 4px' }}>
              <span style={{ fontSize: 14, fontWeight: 700, letterSpacing:'-0.01em' }}>✅ 우리가 검증한 제품</span>
              <span style={{ fontSize: 11.5, color: T.muted, fontWeight: 600 }}>3</span>
            </div>
            <div style={{ display:'flex', flexDirection:'column', gap: 8 }}>
              {[
                { n:'센트룸 우먼', d:'1정/일 · 60정', ing:'비타민A,C,D,E... 14종' },
                { n:'센트룸 멀티비타민', d:'1정/일 · 100정', ing:'종합비타민 · 미네랄' },
                { n:'센트룸 실버', d:'1정/일 · 90정', ing:'50대 이상용 · 16종' },
              ].map((p,i)=>(
                <Card key={i} padding={14}>
                  <div style={{ display:'flex', alignItems:'center', gap: 12 }}>
                    <ProductPhoto label="제품" verified/>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 14.5, fontWeight: 700, letterSpacing:'-0.01em' }}>{p.n}</div>
                      <div style={{ fontSize: 12, color: T.muted, marginTop: 2 }}>{p.d}</div>
                      <div style={{ fontSize: 12, color: T.ink2, marginTop: 4, fontWeight: 500 }}>{p.ing}</div>
                      <div style={{
                        display:'inline-block', marginTop: 6, fontSize: 10.5, fontWeight: 700,
                        padding:'2px 7px', borderRadius: 999, background: T.okBg, color: T.okInk,
                      }}>✅ 정확 분석 가능</div>
                    </div>
                    <button style={{
                      padding:'6px 12px', borderRadius: 999, background: T.primary, color:'#fff',
                      border:'none', fontSize: 12, fontWeight: 700, cursor:'pointer', flexShrink:0,
                    }}>선택</button>
                  </div>
                </Card>
              ))}
            </div>

            {/* Tier 2 */}
            <div style={{ marginTop: 24, marginBottom: 10, display:'flex', alignItems:'center', gap: 6, padding:'0 4px' }}>
              <span style={{ fontSize: 14, fontWeight: 700, letterSpacing:'-0.01em' }}>🛒 네이버 검색 결과</span>
              <span style={{ fontSize: 11.5, color: T.muted, fontWeight: 600 }}>12</span>
            </div>
            <div style={{ display:'flex', flexDirection:'column', gap: 8 }}>
              {[
                { n:'센트룸 골드 30정', d:'정보 부족' },
                { n:'센트룸 키즈 츄어블', d:'정보 부족' },
              ].map((p,i)=>(
                <Card key={i} padding={14}>
                  <div style={{ display:'flex', alignItems:'center', gap: 12 }}>
                    <ProductPhoto label="네이버"/>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 14.5, fontWeight: 700, letterSpacing:'-0.01em' }}>{p.n}</div>
                      <div style={{ fontSize: 12, color: T.muted, marginTop: 2 }}>{p.d}</div>
                      <div style={{
                        display:'inline-block', marginTop: 6, fontSize: 10.5, fontWeight: 700,
                        padding:'2px 7px', borderRadius: 999, background: T.warnBg, color: T.warnInk,
                      }}>⚠️ 함량 정보 없음</div>
                    </div>
                    <button style={{
                      padding:'6px 10px', borderRadius: 999, background: T.surfaceMuted, color: T.ink2,
                      border:'none', fontSize: 11.5, fontWeight: 700, cursor:'pointer', flexShrink:0,
                    }}>📨 등록 요청</button>
                  </div>
                </Card>
              ))}
            </div>

            <div style={{ marginTop: 20 }}>
              <SecondaryButton full size="md">+ 직접 추가하기</SecondaryButton>
            </div>
          </>
        )}
      </div>
    </Screen>
  );
}

function ManualSupplementInputScreen() {
  return (
    <Screen>
      <TopBar title="직접 추가하기"/>
      <div style={{ padding:'0 20px 100px' }}>
        <div style={{ fontSize: 13, color: T.muted, marginBottom: 16, lineHeight: 1.5, padding:'0 4px' }}>
          검증된 제품에 없을 때 직접 추가할 수 있어요.<br/>
          성분 입력은 안 하셔도 돼요. 충돌·과다 분석은 어려워요.
        </div>

        {/* Photo */}
        <div style={{ marginBottom: 14 }}>
          <div style={{ fontSize: 12.5, color: T.muted, fontWeight: 600, marginBottom: 8, padding:'0 4px' }}>제품 사진</div>
          <div style={{
            height: 140, borderRadius: 14, border: `1.5px dashed ${T.hairline}`,
            display:'flex', alignItems:'center', justifyContent:'center', flexDirection:'column', gap: 6,
            color: T.muted, background: T.surface,
          }}>
            <div style={{ fontSize: 28 }}>📷</div>
            <div style={{ fontSize: 12.5, fontWeight: 600 }}>제품 사진 추가 (선택)</div>
          </div>
        </div>

        <Card padding="0 16px">
          <FieldRow label="제품명" value="네이처메이드 비타민D" />
          <FieldRow label="브랜드" value="" placeholder="브랜드를 입력하세요" optional/>
          <FieldRow label="복용 횟수 / 분량" value="하루 1정"/>
          <FieldRow label="총 정량" value="60정"/>
          <FieldRow label="복용 시작일" value="2026년 4월 15일"/>
          <FieldRow label="메모" value="" placeholder="자유롭게 적어주세요" optional/>
        </Card>

        <Card padding={14} style={{ marginTop: 16, background: T.warnBg, border: `1px solid ${T.warnBorder}33` }}>
          <div style={{ display:'flex', alignItems:'flex-start', gap: 10 }}>
            <span style={{ fontSize: 16 }}>⚠️</span>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13, fontWeight: 700, color: T.warnInk }}>함량 정보 없음</div>
              <div style={{ fontSize: 12, color: T.ink2, marginTop: 4, lineHeight: 1.5 }}>
                직접 추가한 제품은 충돌·과다 섭취 분석이 어려워요. 검증된 제품을 우선 검색해 주세요.
              </div>
            </div>
          </div>
        </Card>
      </div>

      <div style={{
        position:'absolute', bottom: 0, left: 0, right: 0, padding: 16,
        background: 'linear-gradient(180deg, rgba(247,248,250,0) 0%, #F7F8FA 30%)',
      }}>
        <PrimaryButton full>추가하기</PrimaryButton>
      </div>
    </Screen>
  );
}

function GuideRow({ name, line, expanded }) {
  return (
    <Card padding={0} style={{ overflow:'hidden' }}>
      <div style={{ padding: 14, display:'flex', alignItems:'flex-start', gap: 12 }}>
        <div style={{
          width: 36, height: 36, borderRadius: 10, background: T.primarySoft,
          display:'flex', alignItems:'center', justifyContent:'center', fontSize: 16, flexShrink:0, fontWeight: 800, color: T.primary,
        }}>{name[0]}</div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 15, fontWeight: 700, letterSpacing:'-0.01em' }}>{name}</div>
          <div style={{ fontSize: 12.5, color: T.muted, marginTop: 4, lineHeight: 1.5 }}>{line}</div>
          {expanded && (
            <div style={{ marginTop: 10, padding: 12, background: T.surfaceMuted, borderRadius: 10 }}>
              <div style={{ fontSize: 12, color: T.muted, fontWeight: 700, marginBottom: 4 }}>이런 분께 좋아요</div>
              <div style={{ fontSize: 12.5, color: T.ink2, lineHeight: 1.5 }}>
                실내 활동이 많은 분, 우유를 잘 안 드시는 분, 50대 이상.
              </div>
              <div style={{ fontSize: 12, color: T.muted, fontWeight: 700, marginTop: 8, marginBottom: 4 }}>섭취 팁</div>
              <div style={{ fontSize: 12.5, color: T.ink2, lineHeight: 1.5 }}>
                기름진 식사 후에 흡수가 잘 돼요. 한 번에 많이 드시기보다 매일 꾸준히.
              </div>
            </div>
          )}
        </div>
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" style={{
          flexShrink: 0, transform: expanded ? 'rotate(180deg)' : 'none', transition: 'transform .15s',
        }}>
          <path d="M6 9l6 6 6-6" stroke={T.muted} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      </div>
    </Card>
  );
}

function SupplementGuideScreen() {
  return (
    <Screen>
      <TopBar title="영양제 가이드"/>
      <div style={{ padding:'0 20px 20px' }}>
        <SearchBar placeholder="영양소를 검색해보세요"/>
        <div style={{ display:'flex', gap: 8, overflowX:'auto', marginTop: 14, paddingBottom: 4 }}>
          {['전체','비타민','미네랄','오메가/지방산','기능성'].map((t,i)=>(
            <Chip key={i} active={i===0}>{t}</Chip>
          ))}
        </div>

        <div style={{ marginTop: 16, display:'flex', flexDirection:'column', gap: 8 }}>
          <GuideRow name="비타민D" line="뼈 건강·면역에 도움. 햇빛으로 합성되지만 한국인 80%가 부족해요." expanded/>
          <GuideRow name="오메가3" line="혈행·뇌·눈 건강. 등푸른 생선에 많지만 매일 먹기 어려워요."/>
          <GuideRow name="마그네슘" line="근육·수면·스트레스 관리. 견과류·시금치에 풍부해요."/>
          <GuideRow name="비타민B군" line="에너지 대사·신경 기능. 피곤할 때 도움이 돼요."/>
          <GuideRow name="비타민C" line="항산화·면역. 매일 채소·과일을 잘 드시면 충분할 수 있어요."/>
          <GuideRow name="아연" line="면역·상처 치유. 굴·붉은 고기에 많아요."/>
          <GuideRow name="철분" line="여성·성장기에 중요. 칼슘과 함께 드시면 흡수가 떨어져요."/>
        </div>

        <DisclaimerFooter/>
      </div>
    </Screen>
  );
}

Object.assign(window, {
  SupplementSearchScreen, ManualSupplementInputScreen, SupplementGuideScreen,
  SearchBar, GuideRow,
});
