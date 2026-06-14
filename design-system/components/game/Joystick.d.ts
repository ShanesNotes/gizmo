import React from 'react';

/**
 * The fixed bottom-left thumbstick, re-skinned to the page-apparatus language.
 * Mirrors the shipping build (112/52 → 94/44). See TOUCH-AND-RESPONSIVE-SPEC.md.
 */
export interface JoystickProps {
  /** ring diameter; use 112 (default) or 94 on small screens */
  size?: number;
  /** knob diameter; defaults to ~46% of size (never let it fall below 44) */
  knobSize?: number;
  /** fixed = ring always drawn (ships); floating = ring appears on touch */
  variant?: 'fixed' | 'floating';
  /** static knob offset −1..1 when not being dragged */
  dx?: number;
  dy?: number;
  /** enable live pointer drag */
  interactive?: boolean;
  /** (dx, dy) each −1..1, called on drag and reset to 0,0 on release */
  onMove?: (dx: number, dy: number) => void;
  style?: React.CSSProperties;
}

export function Joystick(props: JoystickProps): JSX.Element;
