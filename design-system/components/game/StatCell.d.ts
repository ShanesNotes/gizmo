import React from 'react';

/** Small gold-dust stat cell — manuscript eyebrow + Fredoka value (Rank, Power, Reliquary…). */
export interface StatCellProps {
  label: React.ReactNode;
  value: React.ReactNode;
  /** value color — pass a charge hue to tag a system */
  hue?: string;
  style?: React.CSSProperties;
}

export function StatCell(props: StatCellProps): JSX.Element;
