import React from 'react';

/**
 * Pill — a build/covenant chip: hue dot + label + oxblood count badge.
 * The "seal" variant marks an evolved/locked upgrade with a gold rule.
 */
export function Pill({ children, dot = null, count = null, sealed = false, style = {}, ...rest }) {
  return (
    <span
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: 6,
        padding: '5px 9px',
        borderRadius: 'var(--r-sm)',
        fontFamily: 'var(--font-body)',
        fontSize: 12,
        fontWeight: 800,
        background: sealed ? 'rgba(232,188,136,0.16)' : 'rgba(232,188,136,0.08)',
        color: sealed ? 'var(--gold-leaf)' : 'var(--lumen)',
        boxShadow: sealed ? 'inset 0 0 0 1.5px var(--gold-tarnished)' : 'none',
        whiteSpace: 'nowrap',
        ...style,
      }}
      {...rest}
    >
      {dot && (
        <span style={{ width: 8, height: 8, borderRadius: '50%', background: dot, flex: '0 0 auto' }} />
      )}
      {children}
      {count != null && (
        <span
          style={{
            display: 'grid',
            placeItems: 'center',
            minWidth: 17,
            height: 17,
            padding: '0 4px',
            borderRadius: '50%',
            background: sealed ? 'transparent' : 'var(--oxblood)',
            color: sealed ? 'var(--surge)' : 'var(--lumen)',
            fontSize: 10,
            fontWeight: 900,
          }}
        >
          {count}
        </span>
      )}
    </span>
  );
}
