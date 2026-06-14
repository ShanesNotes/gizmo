import React from 'react';

/** Thin pill progress bar — a covenant/run state meter. */
export interface MeterProps {
  /** 0..1 */
  fill?: number;
  /** bar color when not xp (e.g. var(--clutch)) */
  hue?: string;
  /** use the mint→cyan→surge XP gradient */
  xp?: boolean;
  height?: number;
  /** track (unfilled) color */
  track?: string;
  style?: React.CSSProperties;
}

export function Meter(props: MeterProps): JSX.Element;
