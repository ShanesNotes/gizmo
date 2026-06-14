import React from 'react';

/**
 * StatCell — a small gold-dust stat cell: manuscript eyebrow + Fredoka value.
 * The HUD stat-grid unit (Rank, Power, Reliquary, Vigil).
 */
export function StatCell({ label, value, hue = 'var(--lumen)', style = {}, ...rest }) {
  return (
    <div
      style={{
        minWidth: 74,
        padding: '7px 11px',
        borderRadius: 'var(--r-sm)',
        background: 'var(--surface-inset)',
        ...style,
      }}
      {...rest}
    >
      <span style={{ fontFamily: 'var(--font-manuscript)', fontWeight: 700, fontSize: 13, letterSpacing: '2px', textTransform: 'uppercase', color: 'var(--gold-leaf)' }}>{label}</span>
      <b style={{ display: 'block', fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 19, marginTop: 1, color: hue }}>{value}</b>
    </div>
  );
}
