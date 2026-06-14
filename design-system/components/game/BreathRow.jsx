import React from 'react';

/**
 * BreathRow — the hearts-as-Breath meter. Lit flame-motes are kept breath;
 * spent ones go dim. (Hearts → Breath: kept vs. spent.)
 */
export function BreathRow({ total = 5, kept = 4, size = 20, style = {}, ...rest }) {
  const pips = [];
  for (let i = 0; i < total; i++) {
    const on = i < kept;
    pips.push(
      <span
        key={i}
        style={{
          width: size * 0.75,
          height: size,
          background: on ? 'var(--coral)' : 'rgba(255,247,232,0.16)',
          boxShadow: on ? '0 0 9px var(--glow-coral)' : 'none',
          clipPath: 'polygon(50% 0, 72% 38%, 68% 74%, 50% 100%, 32% 74%, 28% 38%)',
        }}
      />
    );
  }
  return <div style={{ display: 'flex', gap: 5, ...style }} {...rest}>{pips}</div>;
}
