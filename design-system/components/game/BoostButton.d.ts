import React from 'react';

export type BoostState = 'default' | 'snap-window' | 'queued' | 'scooping' | 'cooling' | 'disabled';

/**
 * The Snap Boost mechanic as a button — six timing states, color + label (never color alone).
 */
export interface BoostButtonProps {
  /** default · snap-window (hit now) · queued · scooping (mint) · cooling · disabled */
  state?: BoostState;
  /** 0..1 cooldown progress — drives the radial sweep while state="cooling" */
  cooldown?: number;
  size?: number;
  onClick?: (e: React.MouseEvent<HTMLButtonElement>) => void;
  style?: React.CSSProperties;
}

export function BoostButton(props: BoostButtonProps): JSX.Element;
