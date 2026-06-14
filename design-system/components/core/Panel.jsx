import React from 'react';

/**
 * Panel — the dark-glass "page apparatus" container.
 * Gold rule-line border, inner luminous edge, dashed inner rule.
 * The HUD workhorse: score readouts, build lists, progress.
 */
export function Panel({
  children,
  eyebrow = null,
  tone = 'gold',     // gold | danger | plain
  dashed = true,
  style = {},
  ...rest
}) {
  const tones = {
    gold: 'var(--gold-tarnished)',
    danger: 'rgba(255,107,126,0.55)',
    plain: 'rgba(255,247,232,0.16)',
  };
  const borderColor = tones[tone] || tones.gold;

  return (
    <div
      style={{
        position: 'relative',
        background: 'var(--panel)',
        border: `2px solid ${borderColor}`,
        borderRadius: 'var(--r-md)',
        boxShadow: 'var(--shadow-panel)',
        padding: '12px 16px',
        color: 'var(--lumen)',
        ...style,
      }}
      {...rest}
    >
      {dashed && (
        <span
          aria-hidden
          style={{
            content: '""',
            position: 'absolute',
            inset: 4,
            border: '1px dashed var(--rule-inner)',
            borderRadius: 8,
            pointerEvents: 'none',
          }}
        />
      )}
      {eyebrow && (
        <div
          style={{
            fontFamily: 'var(--font-manuscript)',
            fontWeight: 700,
            fontSize: 13,
            letterSpacing: '2px',
            textTransform: 'uppercase',
            color: 'var(--gold-leaf)',
            position: 'relative',
            marginBottom: 8,
          }}
        >
          {eyebrow}
        </div>
      )}
      <div style={{ position: 'relative' }}>{children}</div>
    </div>
  );
}
