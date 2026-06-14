import React from 'react';

/**
 * The safe-area bottom touch band — fixed thumbstick (left) + Boost (right).
 * Render it only under `(hover:none) and (pointer:coarse)`. See TOUCH-AND-RESPONSIVE-SPEC.md.
 */
export interface TouchControlsProps {
  /** passes to the joystick — fixed (ships) or floating (A/B) */
  variant?: 'fixed' | 'floating';
  /** ≤560px / short-viewport geometry (94/72 instead of 112/84) */
  small?: boolean;
  boostState?: 'default' | 'snap-window' | 'queued' | 'scooping' | 'cooling' | 'disabled';
  cooldown?: number;
  onMove?: (dx: number, dy: number) => void;
  onBoost?: () => void;
  /** gap from the safe-area edge (default 22) */
  gutter?: number;
  /** position:fixed to the viewport safe area (default true); false = inline */
  absolute?: boolean;
  /** the Joystick component (inject from the DS namespace) */
  Joystick?: React.ComponentType<any>;
  /** the BoostButton component (inject from the DS namespace) */
  BoostButton?: React.ComponentType<any>;
  style?: React.CSSProperties;
}

export function TouchControls(props: TouchControlsProps): JSX.Element;
