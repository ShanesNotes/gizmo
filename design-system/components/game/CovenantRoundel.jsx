import React from 'react';

/**
 * CovenantRoundel — one of the four illuminated covenant emblems, sliced from
 * the covenant-emblems sprite sheet, with its state meter and manuscript label.
 * index: 0 Flow·Thread · 1 Clutch·Breath · 2 Echo·Vigil · 3 Surge·Seal
 */
const COVENANTS = [
  { name: 'Flow', vow: 'Thread', hue: 'var(--flow)' },
  { name: 'Clutch', vow: 'Breath', hue: 'var(--clutch)' },
  { name: 'Echo', vow: 'Vigil', hue: 'var(--echo)' },
  { name: 'Surge', vow: 'Seal', hue: 'var(--surge)' },
];

export function CovenantRoundel({
  index = 0,
  fill = 0.5,
  size = 120,
  showLabel = true,
  showMeter = true,
  src = 'assets/sprites/covenant-emblems.svg',
  style = {},
  ...rest
}) {
  const c = COVENANTS[index] || COVENANTS[0];
  // sheet: 600px wide, four 150px cells; circle region ~132px, center y≈74
  const k = size / 132;
  const pct = Math.max(0, Math.min(1, fill)) * 100;

  return (
    <div style={{ display: 'inline-flex', flexDirection: 'column', alignItems: 'center', gap: 8, ...style }} {...rest}>
      <div
        style={{
          width: size,
          height: size,
          backgroundImage: `url(${src})`,
          backgroundRepeat: 'no-repeat',
          backgroundSize: `${600 * k}px auto`,
          backgroundPosition: `${-(9 + index * 150) * k}px ${-8 * k}px`,
          filter: fill >= 1 ? `drop-shadow(0 0 16px ${c.hue})` : 'none',
        }}
      />
      {showMeter && (
        <div style={{ width: size * 0.6, height: 5, borderRadius: 'var(--r-pill)', background: 'rgba(232,188,136,0.2)', overflow: 'hidden', marginTop: -size * 0.12 }}>
          <div style={{ height: '100%', width: `${pct}%`, background: c.hue, borderRadius: 'var(--r-pill)', transition: 'width var(--dur-mid) var(--ease-out)' }} />
        </div>
      )}
      {showLabel && (
        <div style={{ fontFamily: 'var(--font-manuscript)', fontWeight: 700, fontSize: 12, letterSpacing: '1.5px', textTransform: 'uppercase', color: c.hue }}>
          {c.name} · {c.vow}
        </div>
      )}
    </div>
  );
}
