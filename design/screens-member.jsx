// Member detail + Current check + Recommendation detail + Family edit

// ────────────────────────────────────────────────────────────
// MemberDetailScreen
// ────────────────────────────────────────────────────────────
function MemberDetailScreen({ m }) {
  const map = {
    ok:    { ink: T.okInk, bg: T.okBg, border: T.okBorder },
    warn:  { ink: T.warnInk, bg: T.warnBg, border: T.warnBorder },
    alert: { ink: T.alertInk, bg: T.alertBg, border: T.alertBorder },
  };
  const c = map[m.status];
  return (
    <Screen>
      <TopBar title="" right={
        <button style={{ ...iconBtnStyle, marginRight: 4 }}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
            <circle cx="12" cy="5" r="1.6" fill={T.ink}/>
            <circle cx="12" cy="12" r="1.6" fill={T.ink}/>
            <circle cx="12" cy="19" r="1.6" fill={T.ink}/>
          </svg>
        </button>
      }/>
      <div style={{ padding: '0 20px 20px', display:'flex', flexDirection:'column', gap: 16 }}>
        {/* Hero */}
        <div style={{ display:'flex', alignItems:'center', gap: 14 }}>
          <AvatarBadge emoji={m.emoji} status={m.status} size={72}/>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 22, fontWeight: 800, letterSpacing:'-0.025em' }}>{m.name}</div>
            <div style={{ fontSize: 13, color: T.muted, marginTop: 2 }}>{m.meta}</div>
          </div>
          <button style={{
            ...iconBtnStyle, background: T.surface, boxShadow: T.cardShadow,
          }}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
              <path d="M14 4l6 6-10 10H4v-6L14 4z" stroke={T.ink} strokeWidth="1.6" strokeLinejoin="round"/>
            </svg>
          </button>
        </div>

        {/* Status banner */}
        <Card padding={16} style={{
          border: `1.5px solid ${c.border}33`, background: c.bg,
        }}>
          <div style={{ display:'flex', alignItems:'center', gap: 12 }}>
            <div style={{
              width: 40, height: 40, borderRadius: 12, background: '#fff',
              display:'flex', alignItems:'center', justifyContent:'center', fontSize: 20,
            }}>{m.status === 'ok' ? '✅' : m.status === 'warn' ? '⚠️' : '🟠'}</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 15, fontWeight: 700, color: c.ink, letterSpacing:'-0.01em' }}>
                {m.status === 'ok' ? '충분히 챙기시는 중' : `${m.deficitCount}개의 영양소가 부족해요`}
              </div>
              <div style={{ fontSize: 12.5, color: T.ink2, marginTop: 2 }}>
                {m.status === 'ok' ? '권장 영양소 모두 섭취 중' : '오늘 추천을 확인해 보세요'}
              </div>
            </div>
          </div>
        </Card>

        {/* Quick actions */}
        <div style={{ display:'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          <PrimaryButton size="md" full>💊 영양제 새로 사기</PrimaryButton>
          <SecondaryButton size="md" full>⚠️ 지금 점검하기</SecondaryButton>
        </div>

        {/* Currently taking */}
        <div>
          <SectionHeader title={`💊 현재 복용 중 · ${m.taking}개`} action={<TextButton>+ 추가</TextButton>}/>
          <div style={{ display:'flex', flexDirection:'column', gap: 8 }}>
            {[
              { name:'센트룸 우먼', meta:'1정/일 · 종합비타민', verified:true, days: 18 },
              { name:'GNC 마그네슘', meta:'1정/일 · 마그네슘 250mg', verified:true, days: 3 },
              { name:'네이처메이드 비타민D', meta:'1정/일 · 함량 정보 없음', verified:false, days: 24 },
            ].slice(0, m.taking).map((p, i) => (
              <Card key={i} padding={14}>
                <div style={{ display:'flex', alignItems:'center', gap: 12 }}>
                  <ProductPhoto label="제품" verified={p.verified}/>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 14.5, fontWeight: 700, letterSpacing:'-0.01em' }}>{p.name}</div>
                    <div style={{ fontSize: 12, color: T.muted, marginTop: 2 }}>{p.meta}</div>
                    {p.days <= 5 && (
                      <div style={{ fontSize: 11.5, color: T.warnInk, marginTop: 4, fontWeight: 600 }}>
                        📦 약 {p.days}일 후 떨어져요
                      </div>
                    )}
                  </div>
                </div>
              </Card>
            ))}
          </div>
        </div>

        {/* Nutrient overview snippet */}
        <div>
          <SectionHeader title="영양소 현황" action={<TextButton>자세히 →</TextButton>}/>
          <Card padding={16}>
            <div style={{ display:'flex', justifyContent:'space-between', marginBottom: 4 }}>
              <span style={{ fontSize: 13, fontWeight: 600 }}>비타민D</span>
              <span style={{ fontSize: 12, color: T.alertInk, fontWeight: 700 }}>20%</span>
            </div>
            <CoverageBar pct={20} status="alert"/>
            <div style={{ height: 12 }}/>
            <div style={{ display:'flex', justifyContent:'space-between', marginBottom: 4 }}>
              <span style={{ fontSize: 13, fontWeight: 600 }}>마그네슘</span>
              <span style={{ fontSize: 12, color: T.warnInk, fontWeight: 700 }}>62%</span>
            </div>
            <CoverageBar pct={62} status="warn"/>
            <div style={{ height: 12 }}/>
            <div style={{ display:'flex', justifyContent:'space-between', marginBottom: 4 }}>
              <span style={{ fontSize: 13, fontWeight: 600 }}>비타민C</span>
              <span style={{ fontSize: 12, color: T.okInk, fontWeight: 700 }}>110%</span>
            </div>
            <CoverageBar pct={100} status="ok"/>
          </Card>
        </div>

        <DisclaimerFooter/>
      </div>
    </Screen>
  );
}

// ────────────────────────────────────────────────────────────
// CurrentCheckScreen — conflicts & overdose check
// ────────────────────────────────────────────────────────────
function CurrentCheckScreen() {
  return (
    <Screen>
      <TopBar title="지금 먹는 것 점검"/>
      <div style={{ padding:'0 20px 20px', display:'flex', flexDirection:'column', gap: 16 }}>
        <div>
          <div style={{ fontSize: 22, fontWeight: 800, letterSpacing:'-0.025em', marginBottom: 4 }}>
            지금 먹는 것을<br/>점검해드릴게요
          </div>
          <div style={{ fontSize: 13.5, color: T.muted }}>충돌과 과다 섭취를 체크해드려요</div>
        </div>

        {/* Member selector */}
        <div style={{ display:'flex', gap: 8, overflowX:'auto', paddingBottom: 4 }}>
          {Object.values(FAMILY_DATA).slice(0,4).map((m,i) => (
            <button key={m.id} style={{
              flex: '0 0 auto', display:'flex', alignItems:'center', gap: 8,
              padding: '10px 14px', borderRadius: 999, border: 'none',
              background: i === 0 ? T.primary : T.surface,
              color: i === 0 ? '#fff' : T.ink,
              boxShadow: i === 0 ? 'none' : T.cardShadow,
              fontSize: 13, fontWeight: 700, cursor:'pointer',
            }}>
              <span>{m.emoji}</span>{m.name}
            </button>
          ))}
        </div>

        {/* Conflict warning */}
        <Card padding={16} style={{ background: T.alertBg, border: `1.5px solid ${T.alertBorder}33` }}>
          <div style={{ display:'flex', alignItems:'flex-start', gap: 10 }}>
            <div style={{ fontSize: 20 }}>⚠️</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 15, fontWeight: 700, color: T.alertInk, letterSpacing:'-0.01em' }}>
                충돌이 감지됐어요
              </div>
              <div style={{ fontSize: 13, color: T.ink2, marginTop: 6, lineHeight: 1.5 }}>
                <b>철분</b>과 <b>칼슘</b>은 함께 드시면 흡수가 떨어져요. 최소 2시간 간격을 두는 게 좋아요.
              </div>
            </div>
          </div>
        </Card>

        {/* Overdose */}
        <Card padding={16} style={{ background: T.warnBg, border: `1.5px solid ${T.warnBorder}33` }}>
          <div style={{ display:'flex', alignItems:'flex-start', gap: 10 }}>
            <div style={{ fontSize: 20 }}>🔺</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 15, fontWeight: 700, color: T.warnInk, letterSpacing:'-0.01em' }}>
                비타민A를 너무 많이 드시고 있어요
              </div>
              <div style={{ fontSize: 13, color: T.ink2, marginTop: 6, lineHeight: 1.5 }}>
                권장 섭취량의 <b>240%</b>를 드시고 있어요. 종합비타민 + 별도 비타민A를 함께 드시고 있어요.
              </div>
            </div>
          </div>
        </Card>

        {/* OK */}
        <Card padding={16} style={{ background: T.okBg, border: `1.5px solid ${T.okBorder}33` }}>
          <div style={{ display:'flex', alignItems:'flex-start', gap: 10 }}>
            <div style={{ fontSize: 20 }}>✅</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 15, fontWeight: 700, color: T.okInk, letterSpacing:'-0.01em' }}>
                다른 영양소는 잘 드시고 계세요
              </div>
              <div style={{ fontSize: 13, color: T.ink2, marginTop: 6, lineHeight: 1.5 }}>
                마그네슘, 비타민D, 오메가3, 비타민C — 적정 범위 안에서 드시는 중이에요.
              </div>
            </div>
          </div>
        </Card>

        <DisclaimerFooter/>
      </div>
    </Screen>
  );
}

// ────────────────────────────────────────────────────────────
// RecommendationDetailScreen — 6 sections
// ────────────────────────────────────────────────────────────
function RecCard({ status, name, pct, currentMg, recMg, reason }) {
  return (
    <Card padding={14}>
      <div style={{ display:'flex', justifyContent:'space-between', alignItems:'baseline', marginBottom: 8 }}>
        <div style={{ fontSize: 15, fontWeight: 700, letterSpacing:'-0.01em' }}>{name}</div>
        <div style={{ fontSize: 13, fontWeight: 700, color: status === 'alert' ? T.alertInk : status === 'warn' ? T.warnInk : T.okInk }}>
          {pct}%
        </div>
      </div>
      <CoverageBar pct={pct} status={status}/>
      <div style={{ marginTop: 10, fontSize: 12.5, color: T.ink2, lineHeight: 1.5 }}>
        <div>· 현재 <b>{currentMg}</b> / 권장 <b>{recMg}</b></div>
        <div style={{ color: T.muted, marginTop: 2 }}>· {reason}</div>
      </div>
    </Card>
  );
}

function ProductRecCard({ tag, name, meta }) {
  return (
    <Card padding={14}>
      <div style={{ display:'flex', alignItems:'center', gap: 12 }}>
        <ProductPhoto label="제품" verified/>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{
            display:'inline-block', fontSize: 10.5, fontWeight: 700,
            padding:'2px 7px', borderRadius: 999,
            background: tag === '적정 함량' ? T.primarySoft : T.surfaceMuted,
            color: tag === '적정 함량' ? T.primaryInk : T.ink2,
            marginBottom: 4, letterSpacing: '-0.01em',
          }}>{tag}</div>
          <div style={{ fontSize: 14, fontWeight: 700, letterSpacing:'-0.01em' }}>{name}</div>
          <div style={{ fontSize: 11.5, color: T.muted, marginTop: 2 }}>{meta}</div>
        </div>
      </div>
    </Card>
  );
}

function RecommendationDetailScreen() {
  return (
    <Screen>
      <TopBar title="영양제 추천"/>
      <div style={{ padding:'0 20px 24px', display:'flex', flexDirection:'column', gap: 20 }}>
        {/* Section 1: Summary */}
        <Card padding={18} style={{ background: 'linear-gradient(135deg, #EAF2FE 0%, #F2F4F7 100%)', border: 'none' }}>
          <div style={{ fontSize: 13, color: T.primaryInk, fontWeight: 700, marginBottom: 8 }}>본인 · 만 35세 여</div>
          <div style={{ fontSize: 17, fontWeight: 800, letterSpacing:'-0.02em', marginBottom: 14 }}>
            영양 상태 요약
          </div>
          <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr 1fr', gap: 8 }}>
            {[
              { v: '8종', l: '잘 챙기심', c: T.okInk, e: '✅' },
              { v: '3종', l: '부족함', c: T.warnInk, e: '⚠️' },
              { v: '2개', l: '추천 제품', c: T.primaryInk, e: '💊' },
            ].map((x, i) => (
              <div key={i} style={{
                background: '#fff', borderRadius: 12, padding: 12, textAlign:'center',
              }}>
                <div style={{ fontSize: 16, marginBottom: 4 }}>{x.e}</div>
                <div style={{ fontSize: 18, fontWeight: 800, color: x.c, letterSpacing:'-0.02em' }}>{x.v}</div>
                <div style={{ fontSize: 11, color: T.muted, marginTop: 1 }}>{x.l}</div>
              </div>
            ))}
          </div>
        </Card>

        {/* Section 2: 우선 보충 필요 */}
        <div>
          <SectionHeader title="🔴 우선 보충 필요"/>
          <div style={{ display:'flex', flexDirection:'column', gap: 8 }}>
            <RecCard status="alert" name="비타민D" pct={20} currentMg="200IU" recMg="1000IU"
              reason="실내 활동이 많은 30대 여성에게 권장"/>
            <RecCard status="alert" name="오메가3" pct={35} currentMg="350mg" recMg="1000mg"
              reason="생선 섭취가 적어 부족 가능성"/>
            <RecCard status="warn" name="마그네슘" pct={62} currentMg="200mg" recMg="320mg"
              reason="수면·스트레스 관리에 도움"/>
          </div>
        </div>

        {/* Section 3: 추가로 챙기시면 좋아요 */}
        <Card padding={0} style={{ overflow: 'hidden' }}>
          <div style={{
            padding: '14px 16px', display:'flex', alignItems:'center', justifyContent:'space-between',
            cursor:'pointer',
          }}>
            <div>
              <div style={{ fontSize: 14, fontWeight: 700, letterSpacing:'-0.01em' }}>🟡 추가로 챙기시면 좋아요</div>
              <div style={{ fontSize: 11.5, color: T.muted, marginTop: 2 }}>5개 영양소</div>
            </div>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
              <path d="M6 9l6 6 6-6" stroke={T.muted} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </div>
        </Card>

        {/* Section 4: 잘 챙기시는 것 */}
        <Card padding={0} style={{ overflow: 'hidden' }}>
          <div style={{
            padding: '14px 16px', display:'flex', alignItems:'center', justifyContent:'space-between',
            cursor:'pointer',
          }}>
            <div>
              <div style={{ fontSize: 14, fontWeight: 700, letterSpacing:'-0.01em' }}>✅ 잘 챙기시는 것</div>
              <div style={{ fontSize: 11.5, color: T.muted, marginTop: 2 }}>충분한 영양소 8개</div>
            </div>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
              <path d="M6 9l6 6 6-6" stroke={T.muted} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </div>
        </Card>

        {/* Section 5: 추천 제품 */}
        <div>
          <SectionHeader title="💊 추천 제품"/>
          <div style={{ fontSize: 12.5, color: T.muted, marginBottom: 10, padding: '0 4px' }}>
            <b style={{ color: T.ink2 }}>비타민D</b>를 위한 추천이에요
          </div>
          <div style={{ display:'flex', flexDirection:'column', gap: 8, marginBottom: 14 }}>
            <ProductRecCard tag="적정 함량" name="나우푸드 비타민D3 1000IU"
              meta="1정/일 · 120정 · 250개 검증 제품 중"/>
            <ProductRecCard tag="판매량" name="GNC 비타민D 2000IU"
              meta="1정/일 · 90정 · 누적 판매 1위"/>
          </div>
          <div style={{ fontSize: 12.5, color: T.muted, marginBottom: 10, padding: '0 4px' }}>
            <b style={{ color: T.ink2 }}>오메가3</b>를 위한 추천이에요
          </div>
          <div style={{ display:'flex', flexDirection:'column', gap: 8 }}>
            <ProductRecCard tag="적정 함량" name="알티지 오메가3 1100mg"
              meta="2정/일 · 60정"/>
            <ProductRecCard tag="판매량" name="네추럴리 알티지 오메가3"
              meta="1정/일 · 90정"/>
          </div>
        </div>

        {/* Section 6: 충돌 / 시너지 */}
        <div>
          <SectionHeader title="⚠️ 충돌 / 시너지"/>
          <Card padding={14} style={{ background: T.okBg, border:`1px solid ${T.okBorder}33` }}>
            <div style={{ display:'flex', alignItems:'center', gap: 10 }}>
              <span style={{ fontSize: 18 }}>✨</span>
              <div style={{ fontSize: 14, fontWeight: 700, color: T.okInk, letterSpacing:'-0.01em' }}>
                잘 드시고 계세요
              </div>
            </div>
            <div style={{ fontSize: 12.5, color: T.ink2, marginTop: 6, lineHeight: 1.5 }}>
              현재 드시는 영양제 사이에 충돌은 없어요. 비타민D는 식사 후에 드시면 흡수가 더 좋아요.
            </div>
          </Card>
        </div>

        <DisclaimerFooter/>
      </div>
    </Screen>
  );
}

// ────────────────────────────────────────────────────────────
// FamilyEditScreen — form
// ────────────────────────────────────────────────────────────
function FieldRow({ label, value, placeholder, optional }) {
  return (
    <div style={{ padding: '14px 0', borderBottom: `1px solid ${T.divider}` }}>
      <div style={{ fontSize: 12.5, color: T.muted, fontWeight: 500, marginBottom: 4 }}>
        {label}{optional && <span style={{ color: T.faint, marginLeft: 4 }}>(선택)</span>}
      </div>
      <div style={{ fontSize: 15, fontWeight: 600, color: value ? T.ink : T.faint }}>
        {value || placeholder}
      </div>
    </div>
  );
}

function FamilyEditScreen() {
  return (
    <Screen>
      <TopBar title="가족 정보 수정"/>
      <div style={{ padding:'0 20px 100px' }}>
        {/* Avatar block */}
        <div style={{ display:'flex', alignItems:'center', gap: 14, padding: '4px 0 12px' }}>
          <AvatarBadge emoji="👤" status="warn" size={64}/>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 16, fontWeight: 700 }}>본인</div>
            <div style={{ fontSize: 12, color: T.muted, marginTop: 2 }}>탭하여 이모지 변경</div>
          </div>
        </div>

        <Card padding="0 16px">
          <FieldRow label="관계" value="본인"/>
          <FieldRow label="이름" value="김지원"/>
          <FieldRow label="출생연도" value="1990년 (만 35세)"/>
          <FieldRow label="성별" value="여성"/>
          <FieldRow label="키 / 몸무게" value="163cm · 54kg" optional/>
          <FieldRow label="임신·수유 중" value="해당 없음"/>
          <FieldRow label="흡연" value="안 함"/>
          <FieldRow label="음주" value="가끔 (주 1-2회)"/>
          <FieldRow label="식습관" value="채식 위주"/>
          <FieldRow label="수면" value="하루 6-7시간"/>
          <FieldRow label="스트레스" value="중간"/>
          <FieldRow label="알레르기" value="없음" optional/>
          <FieldRow label="복용 중인 약" value="없음" optional/>
          <FieldRow label="복용 중인 영양제" value="3개"/>
        </Card>

        <div style={{ marginTop: 24 }}>
          <button style={{
            width: '100%', height: 48, border: `1px solid ${T.alertBorder}33`,
            background: '#fff', color: T.alertInk, borderRadius: 12,
            fontSize: 14, fontWeight: 700, cursor:'pointer',
          }}>가족 구성원 삭제</button>
        </div>
      </div>

      {/* sticky save */}
      <div style={{
        position:'absolute', bottom: 0, left: 0, right: 0, padding: 16,
        background: 'linear-gradient(180deg, rgba(247,248,250,0) 0%, #F7F8FA 30%)',
      }}>
        <PrimaryButton full>저장</PrimaryButton>
      </div>
    </Screen>
  );
}

Object.assign(window, {
  MemberDetailScreen, CurrentCheckScreen, RecommendationDetailScreen, FamilyEditScreen,
  RecCard, ProductRecCard,
});
