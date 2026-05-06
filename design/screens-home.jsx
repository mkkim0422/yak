// Home screen — family cards + 5 entry points
// Multiple variants depending on family size.

// Sample family data
const FAMILY_DATA = {
  self:    { id: 's', emoji: '👤', name: '본인',  meta: '만 35세 여', status: 'warn',  deficitCount: 2, deficits: ['비타민D','마그네슘'], taking: 3 },
  husband: { id: 'h', emoji: '👨', name: '남편',  meta: '만 38세 남', status: 'alert', deficitCount: 4, deficits: ['오메가3','비타민D','아연'], taking: 1 },
  son:     { id: 'b', emoji: '👦', name: '아들',  meta: '만 9세 남',  status: 'ok',    deficitCount: 0, deficits: [], taking: 2 },
  daughter:{ id: 'd', emoji: '👧', name: '딸',    meta: '만 7세 여',  status: 'warn',  deficitCount: 1, deficits: ['철분'], taking: 1 },
  mom:     { id: 'm', emoji: '👵', name: '엄마',  meta: '만 67세 여', status: 'alert', deficitCount: 3, deficits: ['칼슘','비타민B12','비타민D'], taking: 4 },
};

function HomeHeader({ family }) {
  return (
    <div style={{ padding: '16px 20px 8px', display:'flex', alignItems:'center', justifyContent:'space-between' }}>
      <div>
        <div style={{ fontSize: 13, color: T.muted, fontWeight: 500 }}>안녕하세요 👋</div>
        <div style={{ fontSize: 22, fontWeight: 800, letterSpacing: '-0.025em', marginTop: 2 }}>
          우리 가족 영양제
        </div>
      </div>
      <button style={{
        width: 40, height: 40, borderRadius: 12, border: 'none',
        background: T.surface, boxShadow: T.cardShadow, cursor: 'pointer',
        display:'flex', alignItems:'center', justifyContent:'center', position:'relative',
      }} aria-label="알림">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
          <path d="M6 8a6 6 0 1 1 12 0c0 7 3 7 3 9H3c0-2 3-2 3-9z" stroke={T.ink} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
          <path d="M10 21a2 2 0 0 0 4 0" stroke={T.ink} strokeWidth="1.8" strokeLinecap="round"/>
        </svg>
        <span style={{
          position:'absolute', top: 9, right: 11,
          width: 7, height: 7, borderRadius: 999,
          background: T.alertBorder, border:'1.5px solid #fff',
        }}/>
      </button>
    </div>
  );
}

// ────────────────────────────────────────────────────────────
// FamilyCard — full / compact / mini variants
// ────────────────────────────────────────────────────────────
function FamilyCardLarge({ m }) {
  const map = {
    ok:    { border: T.okBorder, bg: T.okBg, label: '충분히 챙기시는 중', sub: '권장 영양소를 모두 섭취 중', ink: T.okInk },
    warn:  { border: T.warnBorder, bg: T.warnBg, label: `${m.deficitCount}개 부족`, sub: '조금만 더 챙겨주세요', ink: T.warnInk },
    alert: { border: T.alertBorder, bg: T.alertBg, label: `${m.deficitCount}개 부족`, sub: '오늘 점검이 필요해요', ink: T.alertInk },
  };
  const c = map[m.status];
  return (
    <div style={{
      background: T.surface, borderRadius: 20, padding: 18,
      boxShadow: T.cardShadow, border: `1.5px solid ${c.border}33`,
      position: 'relative', overflow: 'hidden',
    }}>
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0, height: 4,
        background: c.border,
      }}/>
      <div style={{ display:'flex', alignItems:'center', gap: 14, marginBottom: 14 }}>
        <AvatarBadge emoji={m.emoji} status={m.status} size={56}/>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 17, fontWeight: 700, letterSpacing:'-0.02em' }}>{m.name}</div>
          <div style={{ fontSize: 12.5, color: T.muted, marginTop: 2 }}>{m.meta}</div>
        </div>
        <StatusPill status={m.status}>{m.status === 'ok' ? '✅ 충분' : m.status === 'warn' ? '⚠️ 부족' : '🟠 많이 부족'}</StatusPill>
      </div>

      <div style={{
        background: c.bg, borderRadius: 12, padding: '10px 12px',
        display: 'flex', alignItems: 'center', gap: 10,
      }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 14, fontWeight: 700, color: c.ink, letterSpacing:'-0.01em' }}>
            {c.label}
          </div>
          {m.status !== 'ok' && (
            <div style={{ fontSize: 12, color: T.ink2, marginTop: 3, fontWeight: 500 }}>
              {m.deficits.slice(0,2).join(', ')}
              {m.deficits.length > 2 && <span style={{ color: T.muted }}> +{m.deficits.length - 2}개 더</span>}
            </div>
          )}
          {m.status === 'ok' && (
            <div style={{ fontSize: 12, color: T.ink2, marginTop: 3, fontWeight: 500 }}>{c.sub}</div>
          )}
        </div>
      </div>

      <div style={{
        marginTop: 12, display: 'flex', alignItems: 'center', gap: 6,
        fontSize: 12.5, color: T.muted, fontWeight: 500,
      }}>
        <span style={{ fontSize: 14 }}>💊</span>
        <span><b style={{ color: T.ink2 }}>{m.taking}개</b> 복용 중</span>
      </div>
    </div>
  );
}

function FamilyCardCompact({ m, full }) {
  const map = {
    ok:    { border: T.okBorder, bg: T.okBg, ink: T.okInk, label: '충분' },
    warn:  { border: T.warnBorder, bg: T.warnBg, ink: T.warnInk, label: `${m.deficitCount}개 부족` },
    alert: { border: T.alertBorder, bg: T.alertBg, ink: T.alertInk, label: `${m.deficitCount}개 부족` },
  };
  const c = map[m.status];
  return (
    <div style={{
      background: T.surface, borderRadius: 16, padding: 14,
      boxShadow: T.cardShadow, border: `1.5px solid ${c.border}33`,
      flex: full ? '1 1 100%' : '1 1 0',
      minWidth: 0, position: 'relative', overflow:'hidden',
    }}>
      <div style={{ position:'absolute', top:0, left:0, bottom:0, width:3, background: c.border }}/>
      <div style={{ display:'flex', alignItems:'center', gap: 10, marginBottom: 10 }}>
        <AvatarBadge emoji={m.emoji} status={m.status} size={40}/>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 14.5, fontWeight: 700, letterSpacing:'-0.02em', whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>
            {m.name}
          </div>
          <div style={{ fontSize: 11, color: T.muted, marginTop: 1 }}>{m.meta}</div>
        </div>
      </div>
      <div style={{
        fontSize: 12, fontWeight: 700, color: c.ink,
        background: c.bg, padding: '6px 8px', borderRadius: 8,
        textAlign: 'center', letterSpacing:'-0.01em',
      }}>{c.label}</div>
      {m.status !== 'ok' && m.deficits.length > 0 && (
        <div style={{ fontSize: 11.5, color: T.ink2, marginTop: 8, fontWeight: 500, lineHeight:1.4 }}>
          {m.deficits.slice(0,2).join(', ')}
          {m.deficits.length > 2 && <span style={{ color: T.muted }}> +{m.deficits.length - 2}</span>}
        </div>
      )}
      <div style={{ fontSize: 11, color: T.muted, marginTop: 8, fontWeight: 500 }}>
        💊 {m.taking}개 복용 중
      </div>
    </div>
  );
}

function FamilyCardMini({ m }) {
  const map = {
    ok:    T.okBorder, warn: T.warnBorder, alert: T.alertBorder,
  };
  return (
    <div style={{
      flex: '0 0 110px', background: T.surface, borderRadius: 14,
      padding: 12, boxShadow: T.cardShadow, position:'relative', overflow:'hidden',
      border: `1px solid ${T.hairline}`,
    }}>
      <div style={{ position:'absolute', top:0, left:0, right:0, height:3, background: map[m.status] }}/>
      <AvatarBadge emoji={m.emoji} status={m.status} size={36}/>
      <div style={{ marginTop: 8, fontSize: 13, fontWeight: 700, letterSpacing:'-0.02em' }}>{m.name}</div>
      <div style={{ fontSize: 10.5, color: T.muted, marginTop: 1 }}>{m.meta.replace('만 ','')}</div>
      <div style={{ fontSize: 11, fontWeight: 700, marginTop: 6, color: m.status === 'ok' ? T.okInk : m.status === 'warn' ? T.warnInk : T.alertInk }}>
        {m.status === 'ok' ? '✅ 충분' : `${m.deficitCount}개 부족`}
      </div>
    </div>
  );
}

// Layout: dynamic by member count
function FamilyCardGrid({ members }) {
  if (members.length === 0) {
    return (
      <div style={{
        background: T.surface, borderRadius: 20, padding: '32px 20px',
        boxShadow: T.cardShadow, textAlign: 'center',
        border: `1.5px dashed ${T.hairline}`,
      }}>
        <div style={{ fontSize: 36, marginBottom: 8 }}>👨‍👩‍👧‍👦</div>
        <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 6, letterSpacing:'-0.02em' }}>
          가족을 추가해 주세요
        </div>
        <div style={{ fontSize: 13, color: T.muted, marginBottom: 16, lineHeight:1.5 }}>
          한 폰에서 4명까지 관리할 수 있어요.<br/>
          1분이면 끝나요.
        </div>
        <PrimaryButton size="md">+ 가족 추가하기</PrimaryButton>
      </div>
    );
  }
  if (members.length === 1) {
    return <FamilyCardLarge m={members[0]}/>;
  }
  if (members.length === 2) {
    return (
      <div style={{ display: 'flex', gap: 10 }}>
        {members.map(m => <FamilyCardCompact key={m.id} m={m}/>)}
      </div>
    );
  }
  if (members.length === 3) {
    return (
      <div style={{ display:'flex', flexDirection:'column', gap: 10 }}>
        <FamilyCardLarge m={members[0]}/>
        <div style={{ display:'flex', gap: 10 }}>
          {members.slice(1).map(m => <FamilyCardCompact key={m.id} m={m}/>)}
        </div>
      </div>
    );
  }
  if (members.length === 4) {
    return (
      <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap: 10 }}>
        {members.map(m => <FamilyCardCompact key={m.id} m={m}/>)}
      </div>
    );
  }
  // 5+
  return (
    <div style={{ display:'flex', flexDirection:'column', gap: 10 }}>
      <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap: 10 }}>
        {members.slice(0,4).map(m => <FamilyCardCompact key={m.id} m={m}/>)}
      </div>
      <div style={{ display:'flex', gap: 10, overflowX:'auto', paddingBottom: 4, margin: '0 -20px', padding: '0 20px 4px' }}>
        {members.slice(4).map(m => <FamilyCardMini key={m.id} m={m}/>)}
        <div style={{
          flex:'0 0 110px', borderRadius: 14,
          border: `1.5px dashed ${T.hairline}`,
          display:'flex', alignItems:'center', justifyContent:'center',
          flexDirection:'column', gap: 4,
          color: T.muted, fontSize: 12, fontWeight: 600,
        }}>
          <span style={{ fontSize: 18 }}>＋</span>
          <span>가족 추가</span>
        </div>
      </div>
    </div>
  );
}

// ────────────────────────────────────────────────────────────
// 5 entry points
// ────────────────────────────────────────────────────────────
function EntryList() {
  return (
    <div style={{ display:'flex', flexDirection:'column', gap: 8 }}>
      <EntryRow icon="💊" title="영양제 새로 사고 싶어요"
        sub="부족한 영양소와 추천 제품을 알려드려요" accent="#EAF2FE"/>
      <EntryRow icon="⚠️" title="지금 먹는 것 점검하기"
        sub="충돌과 과다 섭취를 체크해드려요" accent="#FFF8E1"/>
      <EntryRow icon="🤒" title="증상에 맞는 영양제"
        sub="어떤 증상이 있으세요?" accent="#FFE8E8"/>
      <EntryRow icon="🔍" title="영양제 가이드 보기"
        sub="각 영양소의 효능과 섭취법" accent="#E8F5E9"/>
      <EntryRow icon="👨‍👩‍👧" title="가족 관리"
        sub="가족 추가, 정보 수정" accent="#F2F4F7"/>
    </div>
  );
}

function NotificationsBlock() {
  return (
    <div>
      <SectionHeader title="🔔 알림" action={<TextButton>모두 보기</TextButton>}/>
      <div style={{ display:'flex', flexDirection:'column', gap: 8 }}>
        <Card padding={14}>
          <div style={{ display:'flex', alignItems:'flex-start', gap: 12 }}>
            <div style={{ width: 32, height: 32, borderRadius: 10, background: T.warnBg,
              display:'flex', alignItems:'center', justifyContent:'center', fontSize: 16, flexShrink:0 }}>📦</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14, fontWeight: 600, letterSpacing:'-0.01em' }}>
                <b>마그네슘</b>이 곧 떨어져요
              </div>
              <div style={{ fontSize: 12, color: T.muted, marginTop: 2 }}>약 3일 후 예상 · 본인</div>
            </div>
          </div>
        </Card>
        <Card padding={14}>
          <div style={{ display:'flex', alignItems:'flex-start', gap: 12 }}>
            <div style={{ width: 32, height: 32, borderRadius: 10, background: T.primarySoft,
              display:'flex', alignItems:'center', justifyContent:'center', fontSize: 16, flexShrink:0 }}>🩺</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14, fontWeight: 600, letterSpacing:'-0.01em' }}>
                건강검진 받으신 지 1년 됐어요
              </div>
              <div style={{ fontSize: 12, color: T.muted, marginTop: 2 }}>편하실 때 한 번 챙겨보세요</div>
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
}

// ────────────────────────────────────────────────────────────
// HomeScreen — main composer, takes member list
// ────────────────────────────────────────────────────────────
function HomeScreen({ members, showNotifs = true }) {
  return (
    <Screen>
      <HomeHeader family={members}/>
      <div style={{ padding: '8px 20px 20px', display:'flex', flexDirection:'column', gap: 24 }}>
        <FamilyCardGrid members={members}/>

        <div>
          <SectionHeader title="🎯 무엇을 도와드릴까요?"/>
          <EntryList/>
        </div>

        {showNotifs && members.length > 0 && <NotificationsBlock/>}

        <DisclaimerFooter style={{ marginTop: 4 }}/>
      </div>
    </Screen>
  );
}

Object.assign(window, {
  FAMILY_DATA, HomeScreen, FamilyCardGrid, FamilyCardLarge, FamilyCardCompact, FamilyCardMini,
  HomeHeader, EntryList, NotificationsBlock,
});
