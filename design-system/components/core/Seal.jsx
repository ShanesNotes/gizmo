import React from 'react';

/**
 * Seal — the oxblood wax-seal diamond. Page-frame corner mark, or an inline
 * "sealed/maxed" token. Carries a verdict, never decoration.
 */
export function Seal({ size = 22, glow = false, children = null, style = {}, ...rest }) {
  return (
    <span
      style={{
        display: 'inline-grid',
        placeItems: 'center',
        width: size,
        height: size,
        transform: 'rotate(45deg)',
        background: 'var(--oxblood)',
        border: '2px solid var(--gold-leaf)',
        boxShadow: glow ? '0 0 12px var(--glow-coral)' : 'none',
        ...style,
      }}
      {...rest}
    >
      {children && (
        <span style={{ transform: 'rotate(-45deg)', fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: size * 0.5, color: 'var(--surge)' }}>
          {children}
        </span>
      )}
    </span>
  );
}
