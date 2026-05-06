// Symptom search, Settings, Family management, Privacy policy, Disclaimer

function SymptomSearchScreen() {
  return (
    <Screen>
      <TopBar title="증상에 맞는 영양제"/>
      <div style={{ padding:'0 20px 20px' }}>
        <div style={{ fontSize: 22, fontWeight: 800, letterSpacing:'-0.025em', marginBottom: 4 }}>
          어떤 증상이 있으세요?
        </div>
        <div style={{ fontSize: 13, color: T.muted, marginBottom: 16 }}>여러 개 선택할 수 있어요</div>

        <SearchBar placeholder="증상을 검색해 보세요"/>

        <div style={{ display:'flex', gap: 8, overflowX:'auto', marginTop: 14, paddingBottom: 4 }}>
          {['전체','피로','수면','소화','면역','피부','관절'].map((t,i)=>(
            <Chip key={i} active={i===1}>{t}</Chip>
          ))}
        </div>

        <div style={{ marginTop: 16, display:'grid', gridTemplateColumns:'1fr 1fr', gap: 10 }}>
          {[
            ['😴','잘 안 자요',true],
            ['😩','자주 피곤해요',true],
            ['🤧','감기 자주 걸려요',false],
            ['😬','속이 더부룩해요',false],
            ['🦵','근육 뭉침',false],
            ['😢','우울하고 처져요',false],
            ['💆‍♀️','두통이 잦아요',false],
            ['🦴','뼈·관절이 아파요',false],
          ].map(([e,t,active],i)=>(
            <button key={i} style={{
              padding: 14, borderRadius: 14,
              border: `1.5px solid ${active ? T.primary : T.hairline}`,
              background: active ? T.primarySoft : '#fff',
              cursor:'pointer', textAlign:'left',
              display:'flex', flexDirection:'column', alignItems:'flex-start', gap: 4,
            }}>
              <span style={{ fontSize: 22 }}>{e}</span>
              <span style={{ fontSize: 13, fontWeight: 700, color: T.ink, letterSpacing:'-0.01em' }}>{t}</span>
            </button>
          ))}
        </div>

        <Card padding={14} style={{ marginTop: 16, background: T.warnBg, border: `1px solid ${T.warnBorder}33` }}>
          <div style={{ fontSize: 13, color: T.ink2, lineHeight: 1.5 }}>
            <b style={{ color: T.warnInk }}>⚠️ 잠깐</b> · 2주 이상 지속되거나 심한 증상은 병원 진료를 받으세요. 영양제는 보조 수단이에요.
          </div>
        </Card>

        <div style={{ marginTop: 20 }}>
          <PrimaryButton full>추천 받기 (2개 선택됨)</PrimaryButton>
        </div>
      </div>
    </Screen>
  );
}

// ────────────────────────────────────────────────────────────
// Settings
// ────────────────────────────────────────────────────────────
function SettingItem({ icon, title, sub, right, color }) {
  return (
    <div style={{
      display:'flex', alignItems:'center', gap: 14, padding: '14px 16px',
      borderBottom: `1px solid ${T.divider}`,
    }}>
      <div style={{
        width: 32, height: 32, borderRadius: 8, background: T.surfaceMuted,
        display:'flex', alignItems:'center', justifyContent:'center', fontSize: 16, flexShrink:0,
      }}>{icon}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 14, fontWeight: 600, letterSpacing:'-0.01em', color: color || T.ink }}>{title}</div>
        {sub && <div style={{ fontSize: 12, color: T.muted, marginTop: 2 }}>{sub}</div>}
      </div>
      {right || <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
        <path d="M9 6l6 6-6 6" stroke={T.faint} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
      </svg>}
    </div>
  );
}

function SettingsScreen() {
  return (
    <Screen>
      <TopBar title="설정"/>
      <div style={{ padding:'0 16px 20px' }}>
        <div style={{ fontSize: 12, color: T.muted, fontWeight: 600, padding:'8px 4px' }}>알림</div>
        <Card padding={0} style={{ overflow:'hidden' }}>
          <SettingItem icon="📦" title="영양제 떨어짐 알림" right={<ToggleSwitch on/>}/>
          <SettingItem icon="🩺" title="건강검진 알림" right={<ToggleSwitch on/>}/>
          <SettingItem icon="💊" title="복용 시간 알림" sub="편하실 때 챙기세요" right={<ToggleSwitch on={false}/>}/>
        </Card>

        <div style={{ fontSize: 12, color: T.muted, fontWeight: 600, padding:'20px 4px 8px' }}>가족</div>
        <Card padding={0} style={{ overflow:'hidden' }}>
          <SettingItem icon="👨‍👩‍👧" title="가족 관리" sub="4명 등록됨"/>
          <SettingItem icon="📥" title="데이터 백업" sub="이 폰 → 다른 폰"/>
        </Card>

        <div style={{ fontSize: 12, color: T.muted, fontWeight: 600, padding:'20px 4px 8px' }}>앱</div>
        <Card padding={0} style={{ overflow:'hidden' }}>
          <SettingItem icon="🔒" title="개인정보 처리방침"/>
          <SettingItem icon="📜" title="이용약관"/>
          <SettingItem icon="⚠️" title="의료 면책 조항"/>
          <SettingItem icon="ℹ️" title="앱 정보" sub="버전 1.0.0"/>
        </Card>

        <div style={{ fontSize: 12, color: T.muted, fontWeight: 600, padding:'20px 4px 8px' }}>지원</div>
        <Card padding={0} style={{ overflow:'hidden' }}>
          <SettingItem icon="📨" title="영양제 등록 요청"/>
          <SettingItem icon="💬" title="문의하기"/>
          <SettingItem icon="⭐" title="앱 평가하기"/>
        </Card>

        <div style={{ marginTop: 24, padding: '12px 4px' }}>
          <button style={{
            background:'none', border:'none', color: T.alertInk,
            fontSize: 13.5, fontWeight: 600, cursor:'pointer', padding: 0,
          }}>모든 데이터 삭제</button>
        </div>

        <DisclaimerFooter/>
      </div>
    </Screen>
  );
}

// ────────────────────────────────────────────────────────────
// FamilyManagement
// ────────────────────────────────────────────────────────────
function FamilyManagementScreen() {
  const members = [FAMILY_DATA.self, FAMILY_DATA.husband, FAMILY_DATA.son, FAMILY_DATA.daughter];
  return (
    <Screen>
      <TopBar title="가족 관리" right={
        <button style={{
          padding:'8px 14px', borderRadius: 999, border:'none',
          background: T.primary, color:'#fff', fontSize: 13, fontWeight: 700,
          cursor:'pointer', marginRight: 8,
        }}>+ 추가</button>
      }/>
      <div style={{ padding:'0 20px 20px' }}>
        <div style={{ fontSize: 13, color: T.muted, marginBottom: 14, padding:'0 4px' }}>
          한 폰에서 최대 4명까지 관리할 수 있어요. (현재 {members.length}/4)
        </div>

        <div style={{ display:'flex', flexDirection:'column', gap: 8 }}>
          {members.map((m,i)=>(
            <Card key={m.id} padding={14}>
              <div style={{ display:'flex', alignItems:'center', gap: 12 }}>
                <AvatarBadge emoji={m.emoji} status={m.status} size={48}/>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 14.5, fontWeight: 700, letterSpacing:'-0.01em' }}>
                    {m.name}{i === 0 && <span style={{
                      fontSize: 10, fontWeight: 700, padding:'2px 6px', borderRadius: 999,
                      background: T.primarySoft, color: T.primary, marginLeft: 6,
                    }}>나</span>}
                  </div>
                  <div style={{ fontSize: 12, color: T.muted, marginTop: 2 }}>{m.meta}</div>
                </div>
                <button style={iconBtnStyle}>
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
                    <path d="M14 4l6 6-10 10H4v-6L14 4z" stroke={T.muted} strokeWidth="1.6" strokeLinejoin="round"/>
                  </svg>
                </button>
                <button style={iconBtnStyle}>
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
                    <circle cx="12" cy="5" r="1.5" fill={T.muted}/>
                    <circle cx="12" cy="12" r="1.5" fill={T.muted}/>
                    <circle cx="12" cy="19" r="1.5" fill={T.muted}/>
                  </svg>
                </button>
              </div>
            </Card>
          ))}

          {/* Add slot */}
          <button style={{
            padding: 14, borderRadius: 16, border: `1.5px dashed ${T.hairline}`,
            background: 'transparent', cursor:'pointer',
            display:'flex', alignItems:'center', gap: 12,
          }}>
            <div style={{
              width: 48, height: 48, borderRadius: 14, background: T.surfaceMuted,
              display:'flex', alignItems:'center', justifyContent:'center', fontSize: 22, color: T.muted,
            }}>＋</div>
            <div style={{ textAlign:'left' }}>
              <div style={{ fontSize: 14, fontWeight: 700, color: T.ink }}>가족 추가하기</div>
              <div style={{ fontSize: 12, color: T.muted, marginTop: 2 }}>1분이면 끝나요</div>
            </div>
          </button>
        </div>
      </div>
    </Screen>
  );
}

// ────────────────────────────────────────────────────────────
// Privacy policy
// ────────────────────────────────────────────────────────────
function PrivacyPolicyScreen() {
  return (
    <Screen>
      <TopBar title="개인정보 처리방침"/>
      <div style={{ padding:'0 20px 20px' }}>
        <div style={{ fontSize: 22, fontWeight: 800, letterSpacing:'-0.025em', lineHeight: 1.3, marginBottom: 8 }}>
          쉽게 정리해 드릴게요
        </div>
        <div style={{ fontSize: 13, color: T.muted, marginBottom: 20 }}>
          최종 업데이트: 2026년 4월 30일
        </div>

        <Card padding={16} style={{ marginBottom: 12, background: T.primarySoft, border:'none' }}>
          <div style={{ fontSize: 14, fontWeight: 700, color: T.primaryInk, marginBottom: 6 }}>
            🔒 핵심 한 줄
          </div>
          <div style={{ fontSize: 14, color: T.ink, lineHeight: 1.55 }}>
            가족 정보·영양제·기록은 <b>이 폰에만</b> 저장돼요. 서버로 보내지 않아요.
          </div>
        </Card>

        {[
          { t:'1. 우리가 저장하는 정보', s:'관계, 이름, 출생연도, 성별, 키·몸무게, 생활습관, 복용 영양제. 모두 이 폰의 로컬 저장소에만 저장돼요.' },
          { t:'2. 외부로 나가는 정보', s:'영양제 검색 시 네이버 쇼핑 API를 이용해요. 검색어만 전송돼요. 가족 정보는 절대 나가지 않아요.' },
          { t:'3. 광고 / 제휴', s:'없어요. 추천 제품에 광고비를 받지 않아요. 자사몰도 없어요.' },
          { t:'4. 데이터 삭제', s:'설정 > 모든 데이터 삭제로 한 번에 지울 수 있어요. 앱을 지워도 모든 정보가 함께 삭제돼요.' },
          { t:'5. 백업', s:'다른 폰으로 옮기실 때만 백업 파일이 만들어져요. 그 외에는 저장하지 않아요.' },
        ].map((x,i)=>(
          <Card key={i} padding={14} style={{ marginBottom: 8 }}>
            <div style={{ fontSize: 14, fontWeight: 700, letterSpacing:'-0.01em' }}>{x.t}</div>
            <div style={{ fontSize: 13, color: T.ink2, marginTop: 6, lineHeight: 1.6 }}>{x.s}</div>
          </Card>
        ))}

        <DisclaimerFooter/>
      </div>
    </Screen>
  );
}

// ────────────────────────────────────────────────────────────
// Disclaimer
// ────────────────────────────────────────────────────────────
function DisclaimerScreen() {
  return (
    <Screen>
      <TopBar title="의료 면책 조항"/>
      <div style={{ padding:'0 20px 20px' }}>
        <div style={{
          margin: '0 0 20px', padding: 20, borderRadius: 16,
          background: T.warnBg, border: `1.5px solid ${T.warnBorder}33`,
        }}>
          <div style={{ fontSize: 32, marginBottom: 8 }}>⚠️</div>
          <div style={{ fontSize: 18, fontWeight: 800, letterSpacing:'-0.025em', color: T.warnInk, lineHeight: 1.35 }}>
            알약은 의사·약사를<br/>대체하지 않아요
          </div>
        </div>

        {[
          { t:'정보 제공 목적', s:'알약은 영양제 결정을 돕기 위한 정보 제공 앱이에요. 의학적 진단·치료·처방을 하지 않아요.' },
          { t:'권장 섭취량 기준', s:'한국영양학회와 식약처 권장량을 기준으로 해요. 개인 건강 상태에 따라 적정량은 다를 수 있어요.' },
          { t:'언제 병원에 가야 할까요', s:'· 2주 이상 지속되는 증상\n· 심한 통증·발열\n· 약 복용 중인 분의 영양제 추가\n· 임산부·수유부\n· 만 4세 미만 아동' },
          { t:'알레르기·상호작용', s:'알레르기 정보를 입력하시면 가능한 범위에서 안내해드려요. 그러나 모든 상호작용을 완전히 검출하기는 어려워요.' },
          { t:'데이터의 한계', s:'함량 정보가 없는 영양제는 정확한 분석이 어려워요. ⚠️ 함량 정보 없음 표시를 확인해 주세요.' },
        ].map((x,i)=>(
          <Card key={i} padding={14} style={{ marginBottom: 8 }}>
            <div style={{ fontSize: 14, fontWeight: 700, letterSpacing:'-0.01em' }}>{x.t}</div>
            <div style={{ fontSize: 13, color: T.ink2, marginTop: 6, lineHeight: 1.6, whiteSpace:'pre-line' }}>{x.s}</div>
          </Card>
        ))}
      </div>
    </Screen>
  );
}

Object.assign(window, {
  SymptomSearchScreen, SettingsScreen, FamilyManagementScreen,
  PrivacyPolicyScreen, DisclaimerScreen, SettingItem,
});
