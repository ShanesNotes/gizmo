import React from 'react';

/**
 * TouchControls — the safe-area bottom band: fixed thumbstick (left) + Boost (right).
 * Gate its render on `(hover:none) and (pointer:coarse)` in the consuming layout.
 * `small` switches to the ≤560px / short-viewport geometry. See TOUCH-AND-RESPONSIVE-SPEC.md.
 */
export function TouchControls({
  variant = 'fixed',
  small = false,
  boostState = 'default',
  cooldown = 0,
  onMove = null,
  onBoost = null,
  gutter = 22,
  absolute = true,           // position fixed to the viewport's safe area
  Joystick,                  // pass the components in (kit injects them)
  BoostButton,
  style = {},
  ...rest
}) {
  const ring = small ? 94 : 112;
  const boost = small ? 72 : 84;
  const gap = small ? 16 : gutter;

  const frame = absolute
    ? {
        position: 'fixed', left: 0, right: 0, bottom: 0,
        paddingLeft: `calc(env(safe-area-inset-left) + ${gap}px)`,
        paddingRight: `calc(env(safe-area-inset-right) + ${gap}px)`,
        paddingBottom: `calc(env(safe-area-inset-bottom) + ${gap}px)`,
        pointerEvents: 'none', zIndex: 50,
      }
    : { position: 'relative' };

  return (
    <div
      style={{
        ...frame,
        display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between',
        ...style,
      }}
      {...rest}
    >
      <div style={{ pointerEvents: 'auto' }}>
        {Joystick && <Joystick size={ring} variant={variant} interactive onMove={onMove} />}
      </div>
      <div style={{ pointerEvents: 'auto' }}>
        {BoostButton && <BoostButton state={boostState} cooldown={cooldown} size={boost} onClick={onBoost} />}
      </div>
    </div>
  );
}
