// 알약 shared components — pill, card, status badge, chat bubble, top bar, etc.

// ────────────────────────────────────────────────────────────
// Brand mark — original "알약" identity
// A pill-shape lockup, divided horizontally, with a tiny dot signaling a single capsule.
// ────────────────────────────────────────────────────────────
function AlyakMark({ size = 28, color = T.primary }) {
  return (
    <svg width={size} height={size * (28/28)} viewBox="0 0 28 28" fill="none">
      <rect x="2.5" y="6" width="23" height="16" rx="8" fill={color}/>
      <rect x="2.5" y="6" width="11.5" height="16" rx="8" fill="#fff" fillOpacity="0.18"/>
      <circle cx="9" cy="14" r="1.6" fill="#fff"/>
    </svg>
  );
}

// ────────────────────────────────────────────────────────────
// PhoneShell — wraps content in AndroidDevice but with our chrome
// ────────────────────────────────────────────────────────────
function Screen({ children, bg = T.bg, dark, keyboard, statusDark }) {
  return (
    <AndroidDevice width={360} height={760} dark={dark} keyboard={keyboard}>
      <div style={{
        background: bg, minHeight: '100%',
        fontFamily: T.font, color: T.ink,
        WebkitFontSmoothing: 'antialiased',
      }} className="alyak">
        {children}
      </div>
    </AndroidDevice>
  );
}

// ────────────────────────────────────────────────────────────
// TopBar — title bar with optional back button + right action
// ────────────────────────────────────────────────────────────
function TopBar({ title, back, right, transparent, big }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 4,
      padding: '8px 8px 8px 4px', height: 52,
      background: transparent ? 'transparent' : T.bg,
      position: 'sticky', top: 0, zIndex: 5,
    }}>
      {back !== false ? (
        <button style={iconBtnStyle} aria-label="back">
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
            <path d="M15 5l-7 7 7 7" stroke={T.ink} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </button>
      ) : <div style={{ width: 8 }}/>}
      <div style={{
        flex: 1, fontSize: big ? 18 : 16, fontWeight: 600,
        letterSpacing: '-0.01em',
        textAlign: back === false ? 'left' : 'left',
      }}>{title}</div>
      {right}
    </div>
  );
}

const iconBtnStyle = {
  width: 36, height: 36, borderRadius: 10, border: 'none',
  background: 'transparent', display: 'inline-flex',
  alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
};

// ────────────────────────────────────────────────────────────
// Card — base surface
// ────────────────────────────────────────────────────────────
function Card({ children, style, onClick, padding = 16, radius = 16, border, bg = T.surface, shadow = T.cardShadow }) {
  return (
    <div onClick={onClick} style={{
      background: bg,
      borderRadius: radius,
      padding,
      boxShadow: shadow,
      border: border || 'none',
      cursor: onClick ? 'pointer' : 'default',
      ...style,
    }}>{children}</div>
  );
}

// ────────────────────────────────────────────────────────────
// Status pill (충분 / 부족 / 많이부족)
// ────────────────────────────────────────────────────────────
function StatusDot({ status }) {
  const map = {
    ok:    { c: T.okBorder },
    warn:  { c: T.warnBorder },
    alert: { c: T.alertBorder },
  };
  const { c } = map[status] || map.ok;
  return <span style={{ width: 8, height: 8, borderRadius: 999, background: c, display: 'inline-block' }}/>;
}

function StatusPill({ status, children }) {
  const map = {
    ok:    { bg: T.okBg, ink: T.okInk, border: T.okBorder },
    warn:  { bg: T.warnBg, ink: T.warnInk, border: T.warnBorder },
    alert: { bg: T.alertBg, ink: T.alertInk, border: T.alertBorder },
  };
  const { bg, ink, border } = map[status] || map.ok;
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      background: bg, color: ink, fontSize: 12, fontWeight: 600,
      padding: '4px 10px', borderRadius: 999,
      border: `1px solid ${border}33`,
    }}>{children}</span>
  );
}

// ────────────────────────────────────────────────────────────
// PrimaryButton, SecondaryButton, TextButton
// ────────────────────────────────────────────────────────────
function PrimaryButton({ children, full, disabled, onClick, size = 'lg' }) {
  const sz = size === 'sm'
    ? { h: 40, fs: 14, pad: '0 14px', r: 10 }
    : size === 'md'
    ? { h: 48, fs: 15, pad: '0 16px', r: 12 }
    : { h: 56, fs: 16, pad: '0 20px', r: 14 };
  return (
    <button onClick={onClick} disabled={disabled} style={{
      height: sz.h, padding: sz.pad, borderRadius: sz.r,
      width: full ? '100%' : undefined,
      background: disabled ? T.ghost : T.primary,
      color: '#fff', border: 'none', fontWeight: 700, fontSize: sz.fs,
      cursor: disabled ? 'not-allowed' : 'pointer',
      letterSpacing: '-0.01em',
    }}>{children}</button>
  );
}

function SecondaryButton({ children, full, onClick, size = 'lg' }) {
  const sz = size === 'sm'
    ? { h: 40, fs: 14, pad: '0 14px', r: 10 }
    : size === 'md'
    ? { h: 48, fs: 15, pad: '0 16px', r: 12 }
    : { h: 56, fs: 16, pad: '0 20px', r: 14 };
  return (
    <button onClick={onClick} style={{
      height: sz.h, padding: sz.pad, borderRadius: sz.r,
      width: full ? '100%' : undefined,
      background: T.surfaceMuted, color: T.ink,
      border: 'none', fontWeight: 600, fontSize: sz.fs,
      cursor: 'pointer', letterSpacing: '-0.01em',
    }}>{children}</button>
  );
}

function TextButton({ children, onClick, color = T.primary }) {
  return (
    <button onClick={onClick} style={{
      background: 'transparent', border: 'none',
      color, fontWeight: 600, fontSize: 14, padding: '6px 0',
      cursor: 'pointer',
    }}>{children}</button>
  );
}

// ────────────────────────────────────────────────────────────
// AvatarBadge — emoji-on-rounded-square avatar with status border
// ────────────────────────────────────────────────────────────
function AvatarBadge({ emoji = '👤', status, size = 56 }) {
  const map = {
    ok:    { border: T.okBorder, bg: T.okBg },
    warn:  { border: T.warnBorder, bg: T.warnBg },
    alert: { border: T.alertBorder, bg: T.alertBg },
  };
  const c = map[status];
  return (
    <div style={{
      width: size, height: size, borderRadius: size * 0.32,
      background: c ? c.bg : T.surfaceMuted,
      border: c ? `2px solid ${c.border}` : `2px solid ${T.hairline}`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontSize: size * 0.5, flexShrink: 0,
    }}>{emoji}</div>
  );
}

// ────────────────────────────────────────────────────────────
// Coverage bar — for nutrient adequacy %
// ────────────────────────────────────────────────────────────
function CoverageBar({ pct, status = 'alert' }) {
  const map = {
    ok:    T.okBorder,
    warn:  T.warnBorder,
    alert: T.alertBorder,
  };
  const c = map[status] || T.alertBorder;
  return (
    <div style={{
      height: 8, background: T.surfaceMuted, borderRadius: 999, overflow: 'hidden',
    }}>
      <div style={{
        width: `${Math.min(100, Math.max(0, pct))}%`,
        height: '100%', background: c, borderRadius: 999,
        transition: 'width .4s cubic-bezier(.2,.7,.3,1)',
      }}/>
    </div>
  );
}

// ────────────────────────────────────────────────────────────
// Chat bubbles
// ────────────────────────────────────────────────────────────
function BotBubble({ children, withMark, style }) {
  return (
    <div style={{
      display: 'flex', gap: 8, alignItems: 'flex-end', marginBottom: 12,
      animation: 'alyak-bubblein .25s ease both',
      ...style,
    }}>
      {withMark && (
        <div style={{
          width: 28, height: 28, borderRadius: 8,
          background: T.primarySoft, display: 'flex',
          alignItems: 'center', justifyContent: 'center', flexShrink: 0,
        }}>
          <AlyakMark size={18}/>
        </div>
      )}
      <div style={{
        maxWidth: '78%', background: T.surface,
        padding: '12px 14px', borderRadius: '4px 16px 16px 16px',
        fontSize: 15, lineHeight: 1.5, color: T.ink,
        boxShadow: T.cardShadow,
      }}>{children}</div>
    </div>
  );
}

function UserBubble({ children, style }) {
  return (
    <div style={{
      display: 'flex', justifyContent: 'flex-end', marginBottom: 12,
      animation: 'alyak-bubblein .2s ease both',
      ...style,
    }}>
      <div style={{
        maxWidth: '78%', background: T.primary, color: '#fff',
        padding: '12px 14px', borderRadius: '16px 4px 16px 16px',
        fontSize: 15, lineHeight: 1.5, fontWeight: 500,
      }}>{children}</div>
    </div>
  );
}

// ────────────────────────────────────────────────────────────
// Section header
// ────────────────────────────────────────────────────────────
function SectionHeader({ title, action, style }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
      padding: '0 4px', marginBottom: 12,
      ...style,
    }}>
      <div style={{ fontSize: 17, fontWeight: 700, letterSpacing: '-0.02em' }}>{title}</div>
      {action}
    </div>
  );
}

// ────────────────────────────────────────────────────────────
// Chip
// ────────────────────────────────────────────────────────────
function Chip({ children, active, onClick, color }) {
  return (
    <button onClick={onClick} style={{
      padding: '7px 12px', borderRadius: 999, border: 'none',
      fontSize: 13, fontWeight: 600, cursor: 'pointer',
      background: active ? (color || T.primary) : T.surfaceMuted,
      color: active ? '#fff' : T.ink2,
      letterSpacing: '-0.01em',
    }}>{children}</button>
  );
}

// ────────────────────────────────────────────────────────────
// Photo placeholder for product cards (no real images)
// ────────────────────────────────────────────────────────────
function ProductPhoto({ size = 56, label = '제품', verified }) {
  return (
    <div style={{
      width: size, height: size, borderRadius: 12,
      background: `repeating-linear-gradient(135deg, #F2F4F7 0 8px, #EAEDF1 8px 16px)`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      flexShrink: 0, position: 'relative', overflow: 'hidden',
    }}>
      <span style={{
        fontSize: 9, fontFamily: T.mono, color: T.muted,
        background: 'rgba(255,255,255,0.7)', padding: '2px 5px', borderRadius: 4,
      }}>{label}</span>
      {verified && (
        <span style={{
          position: 'absolute', top: 4, right: 4,
          width: 16, height: 16, borderRadius: 999, background: T.primary,
          color: '#fff', fontSize: 9, display: 'flex', alignItems: 'center',
          justifyContent: 'center', fontWeight: 800,
        }}>✓</span>
      )}
    </div>
  );
}

// ────────────────────────────────────────────────────────────
// EntryRow — large tappable entry on Home
// ────────────────────────────────────────────────────────────
function EntryRow({ icon, title, sub, accent, onClick }) {
  return (
    <button onClick={onClick} style={{
      width: '100%', display: 'flex', alignItems: 'center', gap: 14,
      padding: 16, background: T.surface, border: 'none',
      borderRadius: 16, boxShadow: T.cardShadow, cursor: 'pointer',
      textAlign: 'left',
    }}>
      <div style={{
        width: 44, height: 44, borderRadius: 12, flexShrink: 0,
        background: accent || T.primarySoft,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 22,
      }}>{icon}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 15, fontWeight: 700, letterSpacing: '-0.01em' }}>{title}</div>
        <div style={{ fontSize: 12.5, color: T.muted, marginTop: 2, lineHeight: 1.4 }}>{sub}</div>
      </div>
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" style={{ flexShrink: 0 }}>
        <path d="M9 6l6 6-6 6" stroke={T.faint} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
      </svg>
    </button>
  );
}

// ────────────────────────────────────────────────────────────
// Disclaimer footer — small grey
// ────────────────────────────────────────────────────────────
function DisclaimerFooter({ style }) {
  return (
    <div style={{
      fontSize: 11, lineHeight: 1.55, color: T.faint, padding: '20px 16px 12px',
      textAlign: 'center', letterSpacing: '-0.005em',
      ...style,
    }}>
      본 앱은 의료 행위가 아니며,<br/>
      의사·약사의 전문 진단을 대체하지 않습니다
    </div>
  );
}

// ────────────────────────────────────────────────────────────
// Step indicator (subtle "3 / 12")
// ────────────────────────────────────────────────────────────
function StepIndicator({ step, total }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 8,
      padding: '6px 12px', background: T.surface,
      borderRadius: 999, fontSize: 12, fontWeight: 600,
      color: T.muted, boxShadow: T.cardShadow,
      letterSpacing: '0.02em',
    }}>
      <span style={{ color: T.primary, fontWeight: 700 }}>{step}</span>
      <span style={{ color: T.ghost }}>/</span>
      <span>{total}</span>
    </div>
  );
}

Object.assign(window, {
  AlyakMark, Screen, TopBar, Card,
  StatusPill, StatusDot, AvatarBadge, CoverageBar,
  PrimaryButton, SecondaryButton, TextButton,
  BotBubble, UserBubble, SectionHeader, Chip,
  ProductPhoto, EntryRow, DisclaimerFooter, StepIndicator,
});
