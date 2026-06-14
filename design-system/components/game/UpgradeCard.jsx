import React from 'react';

/**
 * UpgradeCard — the level-up choice card. Rarity reads by gold-leaf & seal
 * density first, glow second. Epic lifts; Evolve is the gold verdict.
 * Icon is sliced from the upgrade-chip atlas (icons.svg, ~100px cells).
 */
const RARITY = {
  common:   { color: '#9892B4', glow: 'none',                pillBg: 'rgba(152,146,180,0.9)', pillFg: '#16131f' },
  uncommon: { color: 'var(--flow)',  glow: '0 0 28px rgba(91,230,164,0.18)',  pillBg: 'var(--flow)',  pillFg: '#0c2018' },
  rare:     { color: 'var(--clutch)',glow: 'var(--glow-rare)',  pillBg: 'var(--clutch)',pillFg: '#072430' },
  epic:     { color: 'var(--pink)',  glow: 'var(--glow-epic)',  pillBg: 'var(--pink)',  pillFg: '#3a0a2a' },
  evolve:   { color: 'var(--surge)', glow: 'var(--glow-evolve)',pillBg: 'var(--surge)', pillFg: '#3a2806' },
};

export function UpgradeCard({
  rarity = 'rare',
  name = 'Pulse Driver',
  desc = '',
  label = '',
  pill = null,            // override pill text; defaults to rarity name
  statLabel = '',
  statValue = '',
  hotkey = null,
  iconIndex = 2,
  iconSrc = 'assets/sprites/icons.svg',
  lifted = null,          // override the epic lift; default true only for epic
  width = 300,
  style = {},
  ...rest
}) {
  const r = RARITY[rarity] || RARITY.rare;
  const doLift = lifted == null ? rarity === 'epic' : lifted;
  const pillText = pill || (rarity === 'evolve' ? '⚡ Evolve' : rarity.charAt(0).toUpperCase() + rarity.slice(1));

  return (
    <div
      style={{
        position: 'relative',
        width,
        minHeight: 362,
        borderRadius: 'var(--r-xl)',
        padding: 'var(--inset-card)',
        overflow: 'hidden',
        display: 'flex',
        flexDirection: 'column',
        background: 'linear-gradient(180deg, rgba(34,28,64,0.92), rgba(18,14,36,0.96))',
        border: `3px solid ${r.color}`,
        boxShadow: `var(--shadow-card), ${r.glow}`,
        color: 'var(--lumen)',
        transform: doLift ? 'translateY(-14px) scale(1.02)' : 'none',
        transition: 'transform var(--dur-mid) var(--ease-settle), box-shadow var(--dur-mid) ease',
        ...style,
      }}
      {...rest}
    >
      <span style={{
        alignSelf: 'flex-start', fontSize: 11, fontWeight: 900, letterSpacing: '1.4px',
        textTransform: 'uppercase', padding: '5px 11px', borderRadius: 'var(--r-pill)',
        background: r.pillBg, color: r.pillFg,
      }}>{pillText}</span>

      {hotkey != null && (
        <span style={{
          position: 'absolute', top: 16, right: 16, width: 30, height: 30, borderRadius: '50%',
          display: 'grid', placeItems: 'center', background: 'rgba(12,10,22,0.7)',
          fontWeight: 900, fontSize: 15, border: '1.5px solid rgba(255,247,232,0.2)',
        }}>{hotkey}</span>
      )}

      <div style={{ width: 92, height: 92, margin: '18px auto 10px', display: 'grid', placeItems: 'center' }}>
        <span style={{
          width: 96, height: 96,
          backgroundImage: `url(${iconSrc})`,
          backgroundRepeat: 'no-repeat',
          backgroundPosition: `${-iconIndex * 100}px 0`,
        }} />
      </div>

      <div style={{ fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 25, textAlign: 'center', lineHeight: 1.05, color: rarity === 'evolve' ? 'var(--surge)' : 'var(--lumen)' }}>{name}</div>
      {desc && <div style={{ color: 'var(--lumen-dim)', fontWeight: 800, fontSize: 14, textAlign: 'center', marginTop: 8, lineHeight: 1.4 }}>{desc}</div>}

      {(statLabel || statValue) && (
        <div style={{
          marginTop: 'auto', display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          paddingTop: 12, borderTop: '1px solid rgba(255,247,232,0.12)',
          fontSize: 12, fontWeight: 900, letterSpacing: '1px', textTransform: 'uppercase', color: 'var(--lumen-dim)',
        }}>
          <span>{statLabel}</span>
          <span style={{
            fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 16, padding: '3px 12px',
            borderRadius: 'var(--r-pill)', letterSpacing: 0,
            background: `color-mix(in srgb, ${r.color} 18%, transparent)`, color: r.color,
          }}>{statValue}</span>
        </div>
      )}

      <span aria-hidden style={{ position: 'absolute', right: -40, bottom: -50, width: 150, height: 150, borderRadius: '50%', border: '14px solid rgba(255,247,232,0.06)', pointerEvents: 'none' }} />
    </div>
  );
}
