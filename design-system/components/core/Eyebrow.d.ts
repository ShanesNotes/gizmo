import React from 'react';

/** Manuscript UPPERCASE label (Cormorant) that frames a value — never stars. */
export interface EyebrowProps {
  children: React.ReactNode;
  /** default gold-leaf; pass a charge hue to tag a system */
  color?: string;
  size?: number;
  style?: React.CSSProperties;
}

export function Eyebrow(props: EyebrowProps): JSX.Element;
