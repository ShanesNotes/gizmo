import React from 'react';

/**
 * Joystick — the fixed bottom-left thumbstick, re-skinned into the page-apparatus
 * language (ink ring + gold-leaf rule + stipple; gold knob with a cyan Gizmo-core).
 * Mirrors the shipping build's geometry (112/52 → 94/44). See TOUCH-AND-RESPONSIVE-SPEC.md.
 */
const { useState, useRef, useCallback } = React;

export function Joystick({
  size = 112,
  knobSize = null,            // defaults to ~46% of ring
  variant = 'fixed',         // 'fixed' | 'floating'
  dx = 0,                    // static knob offset -1..1 (used when not dragging)
  dy = 0,
  interactive = true,
  onMove = null,             // (dx, dy) => void, each -1..1
  style = {},
  ...rest
}) {
  const knob = knobSize || Math.round(size * 0.46);
  const travel = (size - knob) / 2;
  const ref = useRef(null);
  const [drag, setDrag] = useState(null);     // {dx,dy} while active
  const [active, setActive] = useState(false);

  const vec = drag || { dx, dy };
  const visibleRing = variant === 'fixed' || active;

  const handle = useCallback((e) => {
    const el = ref.current; if (!el) return;
    const r = el.getBoundingClientRect();
    const cx = r.left + r.width / 2, cy = r.top + r.height / 2;
    let nx = (e.clientX - cx) / travel, ny = (e.clientY - cy) / travel;
    const m = Math.hypot(nx, ny); if (m > 1) { nx /= m; ny /= m; }
    setDrag({ dx: nx, dy: ny });
    onMove && onMove(nx, ny);
  }, [travel, onMove]);

  const start = (e) => {
    if (!interactive) return;
    e.currentTarget.setPointerCapture?.(e.pointerId);
    setActive(true); handle(e);
  };
  const move = (e) => { if (active) handle(e); };
  const end = () => { setActive(false); setDrag(null); onMove && onMove(0, 0); };

  return (
    <div
      ref={ref}
      onPointerDown={start}
      onPointerMove={move}
      onPointerUp={end}
      onPointerCancel={end}
      style={{
        position: 'relative', width: size, height: size, borderRadius: '50%',
        touchAction: 'none', cursor: interactive ? 'grab' : 'default',
        userSelect: 'none',
        // ring base — ink fill, gold-leaf rule, stipple, dashed inner rule
        background: visibleRing ? 'rgba(20,15,34,0.7)' : 'transparent',
        border: visibleRing ? '2px solid var(--gold-tarnished)' : '2px dashed rgba(232,188,136,0.25)',
        boxShadow: visibleRing ? 'inset 0 0 0 1px rgba(232,188,136,0.3), 0 10px 24px rgba(0,0,0,0.45)' : 'none',
        backgroundImage: visibleRing
          ? 'radial-gradient(rgba(232,188,136,0.14) 1px, transparent 1px)' : 'none',
        backgroundSize: '11px 11px',
        transition: 'background var(--dur-fast) ease, border-color var(--dur-fast) ease',
        ...style,
      }}
      {...rest}
    >
      {visibleRing && (
        <span aria-hidden style={{ position: 'absolute', inset: 5, borderRadius: '50%', border: '1px dashed rgba(232,188,136,0.3)', pointerEvents: 'none' }} />
      )}
      {/* knob — gold-leaf gradient with a cyan Gizmo-core */}
      <span
        style={{
          position: 'absolute', left: '50%', top: '50%', width: knob, height: knob, borderRadius: '50%',
          transform: `translate(calc(-50% + ${vec.dx * travel}px), calc(-50% + ${vec.dy * travel}px))`,
          background: 'radial-gradient(circle at 50% 35%, #FFF6E2, #E8BC88 55%, #A87A2E 100%)',
          border: '2px solid var(--ink)',
          boxShadow: '0 4px 12px rgba(0,0,0,0.5), inset 0 -3px 6px rgba(122,80,32,0.5)',
          display: 'grid', placeItems: 'center',
          transition: active ? 'none' : 'transform var(--dur-mid) var(--ease-settle)',
        }}
      >
        <span style={{ width: knob * 0.26, height: knob * 0.26, borderRadius: '50%', background: 'var(--clutch)', boxShadow: '0 0 8px var(--clutch)' }} />
      </span>
    </div>
  );
}
