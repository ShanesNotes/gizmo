import React from 'react';

/** Hearts-as-Breath meter — lit flame-motes are kept breath, spent ones dim. */
export interface BreathRowProps {
  total?: number;
  /** number of lit (kept) breath motes */
  kept?: number;
  size?: number;
  style?: React.CSSProperties;
}

export function BreathRow(props: BreathRowProps): JSX.Element;
