import React from 'react';

/**
 * One of the four illuminated covenant emblems (sliced sprite) with state meter + label.
 */
export interface CovenantRoundelProps {
  /** 0 Flow·Thread · 1 Clutch·Breath · 2 Echo·Vigil · 3 Surge·Seal */
  index?: 0 | 1 | 2 | 3;
  /** meter state 0..1 (the meter IS the covenant's state) */
  fill?: number;
  /** roundel diameter in px */
  size?: number;
  showLabel?: boolean;
  showMeter?: boolean;
  /** relative path to covenant-emblems.svg from the consuming page */
  src?: string;
  style?: React.CSSProperties;
}

export function CovenantRoundel(props: CovenantRoundelProps): JSX.Element;
