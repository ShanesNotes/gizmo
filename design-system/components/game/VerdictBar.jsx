import React from 'react';

/**
 * VerdictBar — the bounty/objective panel ("borders that behave"). A coral-ruled
 * dark-glass plate: emblem + manuscript title + count + coral→gold progress.
 */
export function VerdictBar({
  title = 'The Claiming',
  desc = 'Chase the gold — seal the bounty',
  count = 3,
  total = 5,
  fill = null,            // 0..1; defaults to count/total
  icon = null,            // optional leading node (sprite/emblem)
  compact = false,        // slim single-line chip for portrait HUD
  width = 368,
  style = {},
  ...rest
}) {
  const pct = (fill == null ? count / total : fill) * 100;

  if (compact) {
    return (
      <div
        style={{
          position: 'relative', width, display: 'flex', alignItems: 'center', gap: 10,
          padding: '8px 12px', background: 'var(--panel)',
          border: '2px solid rgba(255,107,126,0.55)', borderRadius: 'var(--r-pill)',
          boxShadow: 'var(--shadow-panel)', color: 'var(--lumen)', overflow: 'hidden',
          ...style,
        }}
        {...rest}
      >
        {icon}
        <div style={{ fontFamily: 'var(--font-manuscript)', fontWeight: 700, fontSize: 15, lineHeight: 1, color: 'var(--lumen)', whiteSpace: 'nowrap' }}>{title}</div>
        <div style={{ flex: 1, height: 5, borderRadius: 'var(--r-pill)', background: 'rgba(232,188,136,0.16)', overflow: 'hidden' }}>
          <div style={{ height: '100%', width: `${pct}%`, borderRadius: 'var(--r-pill)', background: 'linear-gradient(90deg, var(--coral), var(--surge))', transition: 'width var(--dur-mid) var(--ease-out)' }} />
        </div>
        <div style={{ fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 16, color: 'var(--coral)' }}>
          {count}<span style={{ color: 'var(--lumen-dim)', fontSize: 11 }}>/{total}</span>
        </div>
      </div>
    );
  }

  return (
    <div
      style={{
        position: 'relative',
        width,
        display: 'grid',
        gridTemplateColumns: `${icon ? '34px ' : ''}1fr auto`,
        gap: 10,
        alignItems: 'center',
        padding: '10px 14px 13px',
        background: 'var(--panel)',
        border: '2px solid rgba(255,107,126,0.55)',
        borderRadius: 'var(--r-md)',
        boxShadow: 'var(--shadow-panel)',
        color: 'var(--lumen)',
        ...style,
      }}
      {...rest}
    >
      {icon}
      <div>
        <div style={{ fontFamily: 'var(--font-manuscript)', fontWeight: 700, fontSize: 19, lineHeight: 1, color: 'var(--lumen)' }}>{title}</div>
        <div style={{ fontSize: 12, color: 'var(--lumen-dim)', fontWeight: 800, marginTop: 3 }}>{desc}</div>
      </div>
      <div style={{ fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 20, color: 'var(--coral)' }}>
        {count}<span style={{ color: 'var(--lumen-dim)', fontSize: 13 }}>/{total}</span>
      </div>
      <div style={{ gridColumn: '1 / -1', height: 7, borderRadius: 'var(--r-pill)', background: 'rgba(232,188,136,0.16)', overflow: 'hidden', marginTop: 3 }}>
        <div style={{ height: '100%', width: `${pct}%`, borderRadius: 'var(--r-pill)', background: 'linear-gradient(90deg, var(--coral), var(--surge))', transition: 'width var(--dur-mid) var(--ease-out)' }} />
      </div>
    </div>
  );
}
