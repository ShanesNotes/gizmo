import React from 'react';

/**
 * Eyebrow — the manuscript label (Cormorant Garamond, UPPERCASE, wide track).
 * Frames a value; never stars. Use above scores, stats, sections.
 */
export function Eyebrow({ children, color = 'var(--gold-leaf)', size = 13, style = {}, ...rest }) {
  return (
    <span
      style={{
        fontFamily: 'var(--font-manuscript)',
        fontWeight: 700,
        fontSize: size,
        letterSpacing: '2px',
        textTransform: 'uppercase',
        color,
        ...style,
      }}
      {...rest}
    >
      {children}
    </span>
  );
}
