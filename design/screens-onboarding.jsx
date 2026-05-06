// Onboarding: Privacy, Welcome, FamilyAdd (chat), Notifications

function PrivacyConsentScreen() {
  return (
    <Screen>
      <div style={{ padding: '40px 24px 20px', display:'flex', flexDirection:'column', height:'100%' }}>
        <div style={{ display:'flex', alignItems:'center', gap: 10, marginBottom: 32 }}>
          <AlyakMark size={28}/>
          <span style={{ fontSize: 17, fontWeight: 800, letterSpacing:'-0.025em' }}>알약</span>
        </div>

        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 24, fontWeight: 800, letterSpacing:'-0.03em', lineHeight: 1.3 }}>
            시작하기 전에<br/>
            한 가지만 알려드릴게요
          </div>
          <div style={{ fontSize: 14, color: T.muted, marginTop: 12, lineHeight: 1.55 }}>
            가족 정보는 <b style={{ color: T.ink2 }}>이 폰에만</b> 저장돼요.<br/>
            서버로 보내지 않아요.
          </div>

          <div style={{ marginTop: 28, display:'flex', flexDirection:'column', gap: 10 }}>
            {[
              { i: '🔒', t: '내 폰에만 저장', s: '가족 정보, 영양제, 모든 기록' },
              { i: '🚫', t: '광고 없음', s: '제휴 / 추천 / 자사몰 없어요' },
              { i: '🩺', t: '의료 행위 아님', s: '의사·약사 진단을 대체하지 않아요' },
            ].map((x,i)=>(
              <Card key={i} padding={14}>
                <div style={{ display:'flex', alignItems:'center', gap: 12 }}>
                  <div style={{ width: 36, height: 36, borderRadius: 10, background: T.primarySoft,
                    display:'flex', alignItems:'center', justifyContent:'center', fontSize: 18 }}>{x.i}</div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 14, fontWeight: 700 }}>{x.t}</div>
                    <div style={{ fontSize: 12, color: T.muted, marginTop: 1 }}>{x.s}</div>
                  </div>
                </div>
              </Card>
            ))}
          </div>
        </div>

        <div style={{ paddingTop: 16 }}>
          <div style={{ fontSize: 11.5, color: T.muted, lineHeight: 1.5, marginBottom: 12, textAlign:'center' }}>
            계속 진행하면 <u>이용약관</u>과 <u>개인정보 처리방침</u>에<br/>동의하는 것으로 간주돼요
          </div>
          <PrimaryButton full>네, 시작할게요</PrimaryButton>
          <div style={{ height: 8 }}/>
          <button style={{
            width: '100%', height: 48, background:'transparent', border:'none',
            color: T.muted, fontSize: 14, fontWeight: 600, cursor:'pointer',
          }}>자세히 보기</button>
        </div>
      </div>
    </Screen>
  );
}

function WelcomeScreen() {
  return (
    <Screen>
      <div style={{ padding: '24px 20px 20px', display:'flex', flexDirection:'column', height:'100%' }}>
        <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', marginBottom: 16 }}>
          <button style={iconBtnStyle}>
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
              <path d="M15 5l-7 7 7 7" stroke={T.ink} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </button>
          <StepIndicator step={1} total={4}/>
          <div style={{ width: 36 }}/>
        </div>

        <div style={{ flex: 1, display:'flex', flexDirection:'column' }}>
          <BotBubble withMark>안녕하세요 👋<br/>가족 영양제, 같이 챙겨봐요.</BotBubble>
          <BotBubble withMark>먼저 한 분만 등록해 주세요.<br/>나머지는 나중에 추가할 수 있어요.</BotBubble>
          <BotBubble withMark>본인부터 등록할까요,<br/>다른 가족부터 등록할까요?</BotBubble>
        </div>

        <div style={{ display:'flex', flexDirection:'column', gap: 10 }}>
          <Card padding={16} style={{ cursor:'pointer', border: `1.5px solid ${T.primarySoft}` }}>
            <div style={{ display:'flex', alignItems:'center', gap: 12 }}>
              <div style={{ width: 40, height: 40, borderRadius: 12, background: T.primarySoft, display:'flex', alignItems:'center', justifyContent:'center', fontSize: 20 }}>👤</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 15, fontWeight: 700 }}>본인부터 등록할게요</div>
                <div style={{ fontSize: 12, color: T.muted, marginTop: 1 }}>가장 일반적이에요</div>
              </div>
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
                <path d="M9 6l6 6-6 6" stroke={T.faint} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
            </div>
          </Card>
          <Card padding={16} style={{ cursor:'pointer' }}>
            <div style={{ display:'flex', alignItems:'center', gap: 12 }}>
              <div style={{ width: 40, height: 40, borderRadius: 12, background: T.surfaceMuted, display:'flex', alignItems:'center', justifyContent:'center', fontSize: 20 }}>👨‍👩‍👧</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 15, fontWeight: 700 }}>다른 가족부터요</div>
                <div style={{ fontSize: 12, color: T.muted, marginTop: 1 }}>아이, 부모님 먼저</div>
              </div>
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
                <path d="M9 6l6 6-6 6" stroke={T.faint} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
            </div>
          </Card>
        </div>
      </div>
    </Screen>
  );
}

function FamilyAddScreen() {
  // Show mid-flow: relationship picked, name + birth year + sex shown, current step is 식습관
  return (
    <Screen>
      <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', padding: '16px 20px 8px' }}>
        <button style={iconBtnStyle}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
            <path d="M15 5l-7 7 7 7" stroke={T.ink} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </button>
        <StepIndicator step={6} total={12}/>
        <button style={{ ...iconBtnStyle, fontSize: 13, fontWeight: 600, color: T.muted, width: 'auto', padding: '0 10px' }}>
          건너뛰기
        </button>
      </div>

      <div style={{ padding: '8px 20px 16px', display:'flex', flexDirection:'column', gap: 0 }}>
        <BotBubble withMark>관계가 어떻게 되세요?</BotBubble>
        <UserBubble>👤 본인</UserBubble>

        <BotBubble withMark>이름을 알려주세요.</BotBubble>
        <UserBubble>김지원</UserBubble>

        <BotBubble withMark>몇 년생이세요?</BotBubble>
        <UserBubble>1990년 (만 35세)</UserBubble>

        <BotBubble withMark>성별을 알려주세요.</BotBubble>
        <UserBubble>여성</UserBubble>

        <BotBubble withMark>식습관은 어떠세요?<br/>편하게 답해 주세요 🍽</BotBubble>

        <div style={{ display:'flex', flexDirection:'column', gap: 8, marginTop: 8 }}>
          {[
            { e:'🥗', t:'채식 위주' },
            { e:'🍱', t:'골고루 먹어요' },
            { e:'🍖', t:'육류 위주' },
            { e:'🍔', t:'외식·배달 자주' },
          ].map((x,i)=>(
            <button key={i} style={{
              padding: '14px 16px', borderRadius: 14, border: `1.5px solid ${i===0 ? T.primary : T.hairline}`,
              background: i===0 ? T.primarySoft : '#fff',
              fontSize: 14.5, fontWeight: 600, textAlign:'left', cursor:'pointer',
              display:'flex', alignItems:'center', gap: 12,
              color: T.ink,
            }}>
              <span style={{ fontSize: 20 }}>{x.e}</span>
              <span>{x.t}</span>
            </button>
          ))}
        </div>
      </div>
    </Screen>
  );
}

function FamilyAddRelationshipScreen() {
  return (
    <Screen>
      <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', padding: '16px 20px 8px' }}>
        <button style={iconBtnStyle}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
            <path d="M15 5l-7 7 7 7" stroke={T.ink} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </button>
        <StepIndicator step={1} total={12}/>
        <div style={{ width: 36 }}/>
      </div>
      <div style={{ padding: '8px 20px 16px' }}>
        <BotBubble withMark>관계가 어떻게 되세요?</BotBubble>
        <div style={{
          display:'grid', gridTemplateColumns:'1fr 1fr', gap: 10, marginTop: 4,
        }}>
          {[
            ['👤','본인'],['👨','남편'],['👩','아내'],['👦','아들'],
            ['👧','딸'],['👨','아빠'],['👩','엄마'],['👤','기타'],
          ].map(([e,l],i)=>(
            <button key={i} style={{
              padding: 16, borderRadius: 14, border: `1.5px solid ${i===0 ? T.primary : T.hairline}`,
              background: i===0 ? T.primarySoft : '#fff',
              display:'flex', flexDirection:'column', alignItems:'center', gap: 6,
              cursor:'pointer',
            }}>
              <span style={{ fontSize: 28 }}>{e}</span>
              <span style={{ fontSize: 13, fontWeight: 700, color: T.ink }}>{l}</span>
            </button>
          ))}
        </div>
      </div>
    </Screen>
  );
}

function NotificationSetupScreen() {
  return (
    <Screen>
      <div style={{ display:'flex', alignItems:'center', padding: '16px 20px 8px' }}>
        <button style={iconBtnStyle}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
            <path d="M15 5l-7 7 7 7" stroke={T.ink} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </button>
      </div>
      <div style={{ padding: '12px 24px', display:'flex', flexDirection:'column', height: 'calc(100% - 60px)' }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 24, fontWeight: 800, letterSpacing:'-0.03em', lineHeight: 1.3 }}>
            알림은 가볍게,<br/>
            꼭 필요한 것만 알려드려요
          </div>
          <div style={{ fontSize: 13.5, color: T.muted, marginTop: 12, lineHeight: 1.5 }}>
            매일 챙기라고 재촉하지 않아요.<br/>
            결정이 필요한 순간에만 살짝 알려드려요.
          </div>

          <div style={{ marginTop: 28, display:'flex', flexDirection:'column', gap: 10 }}>
            {[
              { e:'📦', t:'영양제가 곧 떨어질 때', s:'3일 전쯤 한 번 알려드려요' },
              { e:'🩺', t:'건강검진 때가 됐을 때', s:'1년에 한 번' },
              { e:'💊', t:'복용 시간 알림', s:'편하실 때 챙기세요 (선택)' },
            ].map((x,i)=>(
              <Card key={i} padding={14}>
                <div style={{ display:'flex', alignItems:'center', gap: 12 }}>
                  <div style={{ width: 36, height: 36, borderRadius: 10, background: T.surfaceMuted,
                    display:'flex', alignItems:'center', justifyContent:'center', fontSize: 18 }}>{x.e}</div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 14, fontWeight: 700 }}>{x.t}</div>
                    <div style={{ fontSize: 12, color: T.muted, marginTop: 1 }}>{x.s}</div>
                  </div>
                  <ToggleSwitch on={i!==2}/>
                </div>
              </Card>
            ))}
          </div>
        </div>

        <div>
          <PrimaryButton full>알림 받을게요</PrimaryButton>
          <div style={{ height: 8 }}/>
          <button style={{
            width:'100%', height: 48, background:'transparent', border:'none',
            color: T.muted, fontSize: 14, fontWeight: 600, cursor:'pointer',
          }}>나중에 설정할게요</button>
        </div>
      </div>
    </Screen>
  );
}

function ToggleSwitch({ on }) {
  return (
    <div style={{
      width: 44, height: 26, borderRadius: 999, padding: 3,
      background: on ? T.primary : T.hairline, transition: 'background .2s',
      display:'flex', alignItems:'center', justifyContent: on ? 'flex-end' : 'flex-start',
    }}>
      <div style={{ width: 20, height: 20, borderRadius: 999, background: '#fff', boxShadow:'0 1px 3px rgba(0,0,0,.2)' }}/>
    </div>
  );
}

Object.assign(window, {
  PrivacyConsentScreen, WelcomeScreen, FamilyAddScreen, FamilyAddRelationshipScreen,
  NotificationSetupScreen, ToggleSwitch,
});
