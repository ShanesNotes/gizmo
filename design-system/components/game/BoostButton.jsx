import React from 'react';

/**
 * BoostButton — the Snap Boost mechanic as a button (never a gesture).
 * Six timing states re-skinned to the codex: gold = ready/window, mint = scooping,
 * oxblood = queued cost, dark-glass sweep = cooling. See TOUCH-AND-RESPONSIVE-SPEC.md.
 */
const STATES = {
  default:       { fill: 'var(--surge)',  fg: '#3A2806', border: 'var(--gold-leaf)', label: 'BOOST', sub: 'Snap Seal',  glow: 'var(--ring-surge), var(--shadow-float)', anim: null,           op: 1 },
  'snap-window': { fill: 'var(--surge)',  fg: '#3A2806', border: 'var(--gold-leaf)', label: 'SNAP',  sub: 'now',        glow: null, anim: 'lumen-snap 0.7s ease-in-out infinite', animClass: 'lumen-anim-snap', op: 1 },
  queued:        { fill: 'var(--oxblood)',fg: 'var(--gold-leaf)', border: 'var(--gold-tarnished)', label: 'SET', sub: 'queued', glow: 'inset 0 0 0 1px rgba(232,188,136,0.4)', anim: null, op: 0.92 },
  scooping:      { fill: 'var(--flow)',   fg: '#0C2018', border: 'var(--flow)', label: 'SCOOP', sub: 'pulling',  glow: null, anim: 'lumen-scoop 0.6s ease-in-out infinite', animClass: 'lumen-anim-scoop', op: 1 },
  cooling:       { fill: 'rgba(20,15,34,0.85)', fg: 'var(--lumen-dim)', border: 'var(--gold-tarnished)', label: 'COOL', sub: '', glow: 'inset 0 0 0 1px rgba(232,188,136,0.25)', anim: null, op: 0.9 },
  disabled:      { fill: 'rgba(20,15,34,0.7)', fg: 'rgba(255,247,232,0.4)', border: 'rgba(232,188,136,0.3)', label: 'BOOST', sub: '', glow: null, anim: null, op: 0.45 },
};

export function BoostButton({ state = 'default', cooldown = 0, size = 84, onClick = null, style = {}, ...rest }) {
  const s = STATES[state] || STATES.default;
  const cd = Math.max(0, Math.min(1, cooldown));
  const isDisabled = state === 'disabled';

  return (
    <button
      type="button"
      disabled={isDisabled}
      onClick={isDisabled ? undefined : onClick}
      className={s.animClass || undefined}
      style={{
        position: 'relative', width: size, height: size, borderRadius: '50%',
        background: s.fill, border: `2px solid ${s.border}`,
        boxShadow: s.glow || 'none', animation: s.anim || 'none',
        opacity: s.op, cursor: isDisabled ? 'not-allowed' : 'pointer',
        display: 'grid', placeItems: 'center', textAlign: 'center', overflow: 'hidden',
        touchAction: 'manipulation', transition: 'background var(--dur-fast) ease, box-shadow var(--dur-fast) ease',
        ...style,
      }}
      onMouseDown={(e) => { if (!isDisabled) e.currentTarget.style.transform = 'scale(0.94)'; }}
      onMouseUp={(e) => { e.currentTarget.style.transform = 'scale(1)'; }}
      onMouseLeave={(e) => { e.currentTarget.style.transform = 'scale(1)'; }}
      {...rest}
    >
      {/* cooling sweep — depletes as cooldown → 1 */}
      {state === 'cooling' && (
        <span aria-hidden style={{
          position: 'absolute', inset: 0, borderRadius: '50%',
          background: `conic-gradient(from -90deg, transparent ${cd * 360}deg, rgba(8,6,18,0.6) 0)`,
          pointerEvents: 'none',
        }} />
      )}
      <span style={{ position: 'relative', display: 'flex', flexDirection: 'column', alignItems: 'center', lineHeight: 1 }}>
        <span style={{ fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: size * 0.21, color: s.fg }}>{s.label}</span>
        {s.sub && <span style={{ fontFamily: 'var(--font-manuscript)', fontWeight: 700, fontSize: size * 0.12, letterSpacing: 1.5, textTransform: 'uppercase', color: s.fg, opacity: 0.85, marginTop: 2 }}>{s.sub}</span>}
      </span>
    </button>
  );
}
