// States: empty, error, loading, notifications, modals, app icon, splash

// ────────────────────────────────────────────────────────────
// AppIcon — original mark, no copyrighted brand
// ────────────────────────────────────────────────────────────
function AppIcon({ size = 96 }) {
  return (
    <div style={{
      width: size, height: size, borderRadius: size * 0.22,
      background: 'linear-gradient(135deg, #4A9BFF 0%, #3182F6 50%, #1B64DA 100%)',
      display:'flex', alignItems:'center', justifyContent:'center',
      boxShadow: '0 8px 24px rgba(49,130,246,0.35), inset 0 1px 0 rgba(255,255,255,0.25)',
      position:'relative', overflow:'hidden',
    }}>
      {/* the 알약 (pill) mark */}
      <svg width={size * 0.6} height={size * 0.6} viewBox="0 0 60 60" fill="none">
        <rect x="6" y="20" width="48" height="20" rx="10" fill="#fff"/>
        <rect x="6" y="20" width="24" height="20" rx="10" fill="#fff" fillOpacity="0.65"/>
        <circle cx="17" cy="30" r="2.5" fill={T.primary}/>
      </svg>
      <div style={{
        position:'absolute', top: -size * 0.2, right: -size * 0.2,
        width: size * 0.6, height: size * 0.6, borderRadius: '50%',
        background: 'rgba(255,255,255,0.08)',
      }}/>
    </div>
  );
}

function SplashScreen() {
  return (
    <Screen bg="#fff">
      <div style={{
        height: 'calc(100% - 0px)', display:'flex', flexDirection:'column',
        alignItems:'center', justifyContent:'center', padding: 32,
      }}>
        <AppIcon size={88}/>
        <div style={{ marginTop: 20, fontSize: 28, fontWeight: 800, letterSpacing:'-0.03em' }}>알약</div>
        <div style={{ marginTop: 6, fontSize: 13.5, color: T.muted, fontWeight: 500 }}>
          우리 가족 영양제 결정 도우미
        </div>
        <div style={{ position:'absolute', bottom: 56, fontSize: 11, color: T.faint, textAlign:'center', lineHeight: 1.5 }}>
          본 앱은 의료 행위가 아니며,<br/>의사·약사의 전문 진단을 대체하지 않습니다
        </div>
      </div>
    </Screen>
  );
}

// ────────────────────────────────────────────────────────────
// Loading state
// ────────────────────────────────────────────────────────────
function Skeleton({ w = '100%', h = 14, r = 6, mt = 0 }) {
  return (
    <div style={{
      width: w, height: h, borderRadius: r, marginTop: mt,
      background: 'linear-gradient(90deg, #ECEFF3 25%, #F5F7F9 50%, #ECEFF3 75%)',
      backgroundSize: '400px 100%',
      animation: 'alyak-shimmer 1.4s infinite linear',
    }}/>
  );
}

function LoadingScreen() {
  return (
    <Screen>
      <TopBar title="추천 만드는 중"/>
      <div style={{ padding:'0 20px 20px' }}>
        <div style={{ marginTop: 80, textAlign:'center' }}>
          <div style={{
            width: 64, height: 64, borderRadius: 999, margin: '0 auto',
            background: T.primarySoft, display:'flex', alignItems:'center', justifyContent:'center',
            position: 'relative',
          }}>
            <div style={{
              position:'absolute', inset: -6, borderRadius: 999,
              border: `3px solid ${T.primary}`, borderTopColor: 'transparent',
              animation: 'alyak-spin 0.9s linear infinite',
            }}/>
            <span style={{ fontSize: 28 }}>💊</span>
          </div>
          <div style={{ marginTop: 20, fontSize: 16, fontWeight: 700, letterSpacing:'-0.01em' }}>
            맞춤 추천을 만들고 있어요
          </div>
          <div style={{ marginTop: 6, fontSize: 13, color: T.muted }}>
            잠시만 기다려 주세요…
          </div>
        </div>

        <div style={{ marginTop: 40 }}>
          {[1,2,3].map(i=>(
            <Card key={i} padding={14} style={{ marginBottom: 8 }}>
              <Skeleton w="40%" h={14}/>
              <Skeleton w="100%" h={8} mt={12}/>
              <Skeleton w="80%" h={11} mt={10}/>
            </Card>
          ))}
        </div>
      </div>
      <style>{`@keyframes alyak-spin{from{transform:rotate(0)}to{transform:rotate(360deg)}}`}</style>
    </Screen>
  );
}

// ────────────────────────────────────────────────────────────
// Error state
// ────────────────────────────────────────────────────────────
function ErrorScreen() {
  return (
    <Screen>
      <TopBar title=""/>
      <div style={{
        padding: 32, textAlign:'center',
        height: '70%', display:'flex', flexDirection:'column', justifyContent:'center', alignItems:'center',
      }}>
        <div style={{ fontSize: 48, marginBottom: 16 }}>😵‍💫</div>
        <div style={{ fontSize: 20, fontWeight: 800, letterSpacing:'-0.025em', marginBottom: 8 }}>
          잠깐 문제가 생겼어요
        </div>
        <div style={{ fontSize: 13.5, color: T.muted, lineHeight: 1.55, marginBottom: 24 }}>
          네트워크 연결을 확인해 주세요.<br/>같은 문제가 계속되면 잠시 후 다시 시도해 주세요.
        </div>
        <PrimaryButton size="md">다시 시도</PrimaryButton>
        <div style={{ height: 8 }}/>
        <TextButton color={T.muted}>홈으로</TextButton>
      </div>
    </Screen>
  );
}

// ────────────────────────────────────────────────────────────
// Notifications (push appearance)
// ────────────────────────────────────────────────────────────
function PushNotif({ icon, app, time, title, body }) {
  return (
    <div style={{
      borderRadius: 18, padding: 12, background: 'rgba(245,247,250,0.92)',
      backdropFilter: 'blur(20px)', boxShadow: '0 4px 16px rgba(0,0,0,0.08)',
      border: '0.5px solid rgba(0,0,0,0.06)',
    }}>
      <div style={{ display:'flex', alignItems:'center', gap: 8, marginBottom: 6 }}>
        <div style={{
          width: 18, height: 18, borderRadius: 4,
          background: 'linear-gradient(135deg, #4A9BFF, #1B64DA)',
          display:'flex', alignItems:'center', justifyContent:'center',
        }}>
          <svg width="11" height="11" viewBox="0 0 60 60" fill="none">
            <rect x="6" y="20" width="48" height="20" rx="10" fill="#fff"/>
            <circle cx="17" cy="30" r="3" fill="#3182F6"/>
          </svg>
        </div>
        <span style={{ fontSize: 11.5, fontWeight: 600, color: T.ink2, letterSpacing:'0.01em' }}>{app}</span>
        <span style={{ fontSize: 11, color: T.muted, marginLeft:'auto' }}>{time}</span>
      </div>
      <div style={{ fontSize: 14, fontWeight: 700, letterSpacing:'-0.01em' }}>{title}</div>
      <div style={{ fontSize: 13, color: T.ink2, marginTop: 2, lineHeight: 1.4 }}>{body}</div>
    </div>
  );
}

function NotificationsScreen() {
  return (
    <Screen bg="linear-gradient(180deg, #1a1a2e 0%, #2d3142 60%, #4a5870 100%)">
      <div style={{ padding: 20, color: '#fff', height:'100%', display:'flex', flexDirection:'column' }}>
        <div style={{ textAlign:'center', marginBottom: 32, marginTop: 40 }}>
          <div style={{ fontSize: 78, fontWeight: 200, letterSpacing:'-0.04em', lineHeight: 1 }}>9:41</div>
          <div style={{ fontSize: 16, fontWeight: 600, marginTop: 4 }}>5월 4일 화요일</div>
        </div>

        <div style={{ display:'flex', flexDirection:'column', gap: 8 }}>
          <PushNotif app="알약" time="지금" 
            title="📦 마그네슘이 곧 떨어져요" 
            body="약 3일 후 예상 · 본인"/>
          <PushNotif app="알약" time="9:30" 
            title="💊 영양제 시간이에요" 
            body="편하실 때 챙기세요"/>
          <PushNotif app="알약" time="어제" 
            title="🩺 건강검진 받으신 지 1년 됐어요" 
            body="편하실 때 한 번 챙겨보세요"/>
        </div>

        <div style={{ flex: 1 }}/>
        <div style={{ textAlign:'center', fontSize: 12, opacity: 0.6, paddingBottom: 20 }}>
          ↑ 위로 밀어 잠금 해제
        </div>
      </div>
    </Screen>
  );
}

// ────────────────────────────────────────────────────────────
// Modals
// ────────────────────────────────────────────────────────────
function ModalShell({ children, sheet, height = 'auto' }) {
  return (
    <Screen>
      <div style={{ position: 'relative', height: '100%', background: 'rgba(0,0,0,0.4)' }}>
        {/* dim'd home behind */}
        <div style={{
          position: 'absolute', inset: 0, padding: 20, opacity: 0.18, pointerEvents:'none',
        }}>
          <div style={{ height: 24, background:'#fff', borderRadius: 12, marginBottom: 16 }}/>
          {[1,2,3,4].map(i => <div key={i} style={{
            height: 60, background:'#fff', borderRadius: 12, marginBottom: 8,
          }}/>)}
        </div>

        {sheet ? (
          <div style={{
            position:'absolute', bottom: 0, left: 0, right: 0,
            background: T.surface, borderRadius: '20px 20px 0 0',
            padding: '12px 20px 24px', height,
          }}>
            <div style={{
              width: 36, height: 4, background: T.hairline,
              borderRadius: 999, margin: '4px auto 16px',
            }}/>
            {children}
          </div>
        ) : (
          <div style={{
            position:'absolute', top: '50%', left: 24, right: 24, transform:'translateY(-50%)',
            background: T.surface, borderRadius: 20, padding: 24,
          }}>
            {children}
          </div>
        )}
      </div>
    </Screen>
  );
}

function QuickActionSheet() {
  return (
    <ModalShell sheet>
      <div style={{ display:'flex', alignItems:'center', gap: 12, marginBottom: 20 }}>
        <AvatarBadge emoji="👤" status="warn" size={48}/>
        <div>
          <div style={{ fontSize: 16, fontWeight: 700 }}>본인</div>
          <div style={{ fontSize: 12, color: T.muted, marginTop: 1 }}>만 35세 여 · 2개 부족</div>
        </div>
      </div>

      <div style={{ display:'flex', flexDirection:'column', gap: 4 }}>
        {[
          { e:'💊', t:'영양제 새로 사기', s:'부족한 영양소 채우기' },
          { e:'⚠️', t:'지금 먹는 것 점검', s:'충돌·과다 체크' },
          { e:'➕', t:'복용 영양제 추가' },
          { e:'✏️', t:'정보 수정' },
        ].map((x,i)=>(
          <button key={i} style={{
            display:'flex', alignItems:'center', gap: 14, padding: 14,
            background: 'transparent', border: 'none', cursor: 'pointer', textAlign:'left',
            borderRadius: 12,
          }}>
            <div style={{ width: 36, height: 36, borderRadius: 10, background: T.surfaceMuted,
              display:'flex', alignItems:'center', justifyContent:'center', fontSize: 18 }}>{x.e}</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 15, fontWeight: 600 }}>{x.t}</div>
              {x.s && <div style={{ fontSize: 12, color: T.muted, marginTop: 2 }}>{x.s}</div>}
            </div>
          </button>
        ))}
      </div>

      <div style={{ marginTop: 12 }}>
        <SecondaryButton full size="md">닫기</SecondaryButton>
      </div>
    </ModalShell>
  );
}

function AddSupplementSheet() {
  return (
    <ModalShell sheet>
      <div style={{ fontSize: 18, fontWeight: 800, letterSpacing:'-0.02em', marginBottom: 4 }}>영양제 추가</div>
      <div style={{ fontSize: 13, color: T.muted, marginBottom: 18 }}>본인이 드실 영양제를 추가해요</div>

      <div style={{ display:'flex', flexDirection:'column', gap: 8 }}>
        <button style={{
          padding: 16, borderRadius: 14, border: `1.5px solid ${T.primary}`,
          background: T.primarySoft, cursor:'pointer', textAlign:'left',
          display:'flex', alignItems:'center', gap: 14,
        }}>
          <div style={{ fontSize: 24 }}>🔍</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 15, fontWeight: 700, color: T.primaryInk }}>이름으로 검색</div>
            <div style={{ fontSize: 12, color: T.ink2, marginTop: 2 }}>250개 검증된 제품 중 찾기</div>
          </div>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
            <path d="M9 6l6 6-6 6" stroke={T.primary} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </button>

        <button style={{
          padding: 16, borderRadius: 14, border: `1.5px solid ${T.hairline}`,
          background: '#fff', cursor:'pointer', textAlign:'left',
          display:'flex', alignItems:'center', gap: 14,
        }}>
          <div style={{ fontSize: 24 }}>📷</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 15, fontWeight: 700 }}>사진으로 검색</div>
            <div style={{ fontSize: 12, color: T.muted, marginTop: 2 }}>제품 사진을 찍어보세요</div>
          </div>
        </button>

        <button style={{
          padding: 16, borderRadius: 14, border: `1.5px solid ${T.hairline}`,
          background: '#fff', cursor:'pointer', textAlign:'left',
          display:'flex', alignItems:'center', gap: 14,
        }}>
          <div style={{ fontSize: 24 }}>✏️</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 15, fontWeight: 700 }}>직접 입력</div>
            <div style={{ fontSize: 12, color: T.muted, marginTop: 2 }}>검증된 DB에 없을 때</div>
          </div>
        </button>
      </div>

      <div style={{ marginTop: 16 }}>
        <SecondaryButton full size="md">닫기</SecondaryButton>
      </div>
    </ModalShell>
  );
}

function DeleteConfirmModal() {
  return (
    <ModalShell>
      <div style={{ textAlign:'center', marginBottom: 16 }}>
        <div style={{
          width: 56, height: 56, borderRadius: 999, margin: '0 auto 14px',
          background: T.alertBg, display:'flex', alignItems:'center', justifyContent:'center', fontSize: 26,
        }}>🗑</div>
        <div style={{ fontSize: 17, fontWeight: 800, letterSpacing:'-0.02em' }}>
          남편 정보를 삭제할까요?
        </div>
        <div style={{ fontSize: 13, color: T.muted, marginTop: 8, lineHeight: 1.5 }}>
          복용 중인 영양제 1개와<br/>등록된 모든 정보가 함께 사라져요.<br/>
          되돌릴 수 없어요.
        </div>
      </div>
      <div style={{ display:'flex', gap: 8 }}>
        <SecondaryButton full size="md">취소</SecondaryButton>
        <button style={{
          flex: 1, height: 48, borderRadius: 12, border: 'none',
          background: T.alertInk, color: '#fff', fontSize: 15, fontWeight: 700, cursor:'pointer',
        }}>삭제</button>
      </div>
    </ModalShell>
  );
}

// ────────────────────────────────────────────────────────────
// Empty states
// ────────────────────────────────────────────────────────────
function EmptyMemberDetailScreen() {
  return (
    <Screen>
      <TopBar title=""/>
      <div style={{ padding:'0 20px' }}>
        <div style={{ display:'flex', alignItems:'center', gap: 14, marginBottom: 20 }}>
          <AvatarBadge emoji="👦" size={64}/>
          <div>
            <div style={{ fontSize: 22, fontWeight: 800, letterSpacing:'-0.025em' }}>아들</div>
            <div style={{ fontSize: 13, color: T.muted, marginTop: 2 }}>만 9세 남</div>
          </div>
        </div>

        <Card padding={24} style={{ textAlign:'center' }}>
          <div style={{ fontSize: 40, marginBottom: 12 }}>💊</div>
          <div style={{ fontSize: 16, fontWeight: 700, letterSpacing:'-0.02em' }}>
            아직 등록된 영양제가 없어요
          </div>
          <div style={{ fontSize: 13, color: T.muted, marginTop: 6, marginBottom: 20, lineHeight: 1.5 }}>
            드시는 영양제가 있다면 추가해 주세요.<br/>
            없다면 추천부터 받아볼 수 있어요.
          </div>
          <div style={{ display:'flex', gap: 8, justifyContent:'center' }}>
            <PrimaryButton size="md">+ 영양제 추가</PrimaryButton>
            <SecondaryButton size="md">추천 받기</SecondaryButton>
          </div>
        </Card>
      </div>
    </Screen>
  );
}

Object.assign(window, {
  AppIcon, SplashScreen, Skeleton, LoadingScreen, ErrorScreen,
  PushNotif, NotificationsScreen,
  ModalShell, QuickActionSheet, AddSupplementSheet, DeleteConfirmModal,
  EmptyMemberDetailScreen,
});
