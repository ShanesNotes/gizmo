import React from 'react';

/**
 * Meter — a thin pill progress bar. The covenant's / run's state *is* the meter.
 * `fill` 0..1. `hue` sets the bar color; `xp` uses the mint→cyan→surge gradient.
 */
export function Meter({ fill = 0.5, hue = 'var(--gold-leaf)', xp = false, height = 7, track = 'rgba(232,188,136,0.16)', style = {}, ...rest }) {
  const pct = Math.max(0, Math.min(1, fill)) * 100;
  return (
    <div
      style={{
        height,
        borderRadius: 'var(--r-pill)',
        background: track,
        overflow: 'hidden',
        ...style,
      }}
      {...rest}
    >
      <div
        style={{
          height: '100%',
          width: `${pct}%`,
          borderRadius: 'var(--r-pill)',
          background: xp
            ? 'linear-gradient(90deg, var(--flow), var(--clutch), var(--surge))'
            : hue,
          transition: 'width var(--dur-mid) var(--ease-out)',
        }}
      />
    </div>
  );
}
