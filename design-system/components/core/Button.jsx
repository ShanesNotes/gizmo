import React from 'react';

/**
 * Button — Gizmo's dopamine action control.
 * Fredoka display face; squash on press; reward variants carry a glow ring.
 */
export function Button({
  children,
  variant = 'primary',
  size = 'md',
  iconLeft = null,
  disabled = false,
  full = false,
  style = {},
  ...rest
}) {
  const sizes = {
    sm: { padding: '9px 16px', fontSize: 14, radius: 'var(--r-md)' },
    md: { padding: '13px 24px', fontSize: 17, radius: 'var(--r-lg)' },
    lg: { padding: '15px 30px', fontSize: 19, radius: 'var(--r-lg)' },
  };
  const s = sizes[size] || sizes.md;

  const variants = {
    // mint "go" — the primary forward action (Run it back)
    primary: {
      background: 'var(--flow)',
      color: '#0C2018',
      border: '2px solid transparent',
      boxShadow: 'var(--ring-flow), var(--shadow-press)',
    },
    // gold surge — the reward / boost action (the hinge)
    surge: {
      background: 'var(--surge)',
      color: 'var(--text-on-gold)',
      border: '2px solid var(--gold-leaf)',
      boxShadow: 'var(--ring-surge), var(--shadow-float)',
    },
    // dark-glass outline — secondary
    alt: {
      background: 'rgba(14,11,28,0.85)',
      color: 'var(--lumen)',
      border: '2px solid rgba(255,247,232,0.2)',
      boxShadow: 'none',
    },
    // ink + gold rule — manuscript secondary
    seal: {
      background: 'var(--panel)',
      color: 'var(--gold-leaf)',
      border: '2px solid var(--gold-tarnished)',
      boxShadow: 'var(--edge-luminous)',
    },
    // bare
    ghost: {
      background: 'transparent',
      color: 'var(--lumen-dim)',
      border: '2px solid transparent',
      boxShadow: 'none',
    },
  };
  const v = variants[variant] || variants.primary;

  return (
    <button
      type="button"
      disabled={disabled}
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 10,
        fontFamily: 'var(--font-display)',
        fontWeight: 700,
        lineHeight: 1,
        cursor: disabled ? 'not-allowed' : 'pointer',
        opacity: disabled ? 0.45 : 1,
        padding: s.padding,
        fontSize: s.fontSize,
        borderRadius: s.radius,
        width: full ? '100%' : 'auto',
        transition: 'transform var(--dur-fast) var(--ease-settle), filter var(--dur-fast) ease, box-shadow var(--dur-fast) ease',
        ...v,
        ...style,
      }}
      onMouseDown={(e) => { if (!disabled) e.currentTarget.style.transform = 'scale(0.96)'; }}
      onMouseUp={(e) => { e.currentTarget.style.transform = 'scale(1)'; }}
      onMouseLeave={(e) => { e.currentTarget.style.transform = 'scale(1)'; }}
      onMouseEnter={(e) => { if (!disabled) e.currentTarget.style.filter = 'brightness(1.08)'; }}
      {...rest}
    >
      {iconLeft}
      {children}
    </button>
  );
}
