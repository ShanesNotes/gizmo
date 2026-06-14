import React from 'react';

/**
 * Keycap — the round hotkey token on upgrade cards (1 / 2 / 3 / ↻).
 */
export function Keycap({ children, size = 30, style = {}, ...rest }) {
  return (
    <span
      style={{
        display: 'grid',
        placeItems: 'center',
        width: size,
        height: size,
        borderRadius: '50%',
        background: 'rgba(12,10,22,0.7)',
        border: '1.5px solid rgba(255,247,232,0.2)',
        fontFamily: 'var(--font-body)',
        fontWeight: 900,
        fontSize: size * 0.5,
        color: 'var(--lumen)',
        ...style,
      }}
      {...rest}
    >
      {children}
    </span>
  );
}
