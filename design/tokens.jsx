// 알약 (alyak) design tokens
// Mobile-first, Korean-optimized. Spec colors honored; layout/components original.

const T = {
  // Brand
  primary: '#3182F6',
  primarySoft: '#EAF2FE',
  primaryInk: '#1B64DA',

  // Surfaces
  bg: '#F7F8FA',
  surface: '#FFFFFF',
  surfaceMuted: '#F2F4F7',
  divider: '#EEF0F3',
  hairline: '#E5E8EC',

  // Text
  ink: '#1F2937',
  ink2: '#4B5563',
  muted: '#6B7280',
  faint: '#9CA3AF',
  ghost: '#C7CCD3',

  // Status — green (sufficient)
  okBorder: '#10B981',
  okBg: '#E8F5E9',
  okInk: '#0E8C68',

  // Status — yellow (1-2 deficits)
  warnBorder: '#F59E0B',
  warnBg: '#FFF8E1',
  warnInk: '#B07000',

  // Status — orange/red (3+ deficits)
  alertBorder: '#EF4444',
  alertBg: '#FFF3E0',
  alertInk: '#C03030',

  // Misc accents
  pillBg: '#F2F4F7',
  pillInk: '#374151',

  // Shadows
  cardShadow: '0 2px 8px rgba(16,24,40,0.04), 0 1px 2px rgba(16,24,40,0.03)',
  raise: '0 8px 24px rgba(16,24,40,0.08), 0 2px 6px rgba(16,24,40,0.04)',
  popover: '0 12px 32px rgba(16,24,40,0.14), 0 2px 6px rgba(16,24,40,0.06)',

  // Radii
  r4: 4, r8: 8, r12: 12, r16: 16, r20: 20, r24: 24, rPill: 999,

  // Type
  font: '"Pretendard","Pretendard Variable",-apple-system,BlinkMacSystemFont,"Apple SD Gothic Neo","Noto Sans KR",system-ui,sans-serif',
  mono: '"SF Mono","JetBrains Mono",ui-monospace,Menlo,monospace',
};

// Inject Pretendard CDN once
if (typeof document !== 'undefined' && !document.getElementById('alyak-fonts')) {
  const l = document.createElement('link');
  l.id = 'alyak-fonts';
  l.rel = 'stylesheet';
  l.href = 'https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/variable/pretendardvariable-dynamic-subset.min.css';
  document.head.appendChild(l);

  const s = document.createElement('style');
  s.textContent = `
    .alyak{font-family:${T.font};color:${T.ink};-webkit-font-smoothing:antialiased;text-rendering:optimizeLegibility;}
    .alyak *{box-sizing:border-box}
    .alyak button{font-family:inherit;color:inherit}
    .alyak ::-webkit-scrollbar{width:0;height:0}
    @keyframes alyak-fadein{from{opacity:0;transform:translateY(4px)}to{opacity:1;transform:none}}
    @keyframes alyak-bubblein{from{opacity:0;transform:translateY(6px) scale(0.98)}to{opacity:1;transform:none}}
    @keyframes alyak-pulse{0%,100%{opacity:1}50%{opacity:.5}}
    @keyframes alyak-shimmer{0%{background-position:-200px 0}100%{background-position:200px 0}}
  `;
  document.head.appendChild(s);
}

window.T = T;
