import React from 'react';

/**
 * The bounty/objective panel — coral-ruled dark glass with manuscript title, count, coral→gold progress.
 */
export interface VerdictBarProps {
  title?: string;
  desc?: string;
  count?: number;
  total?: number;
  /** progress 0..1; defaults to count/total */
  fill?: number;
  /** optional leading emblem/sprite node (34px slot) */
  icon?: React.ReactNode;
  /** slim single-line pill for the portrait HUD */
  compact?: boolean;
  width?: number;
  style?: React.CSSProperties;
}

export function VerdictBar(props: VerdictBarProps): JSX.Element;
