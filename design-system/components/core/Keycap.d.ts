import React from 'react';

/** Round hotkey token (1 / 2 / 3 / ↻) used on upgrade cards. */
export interface KeycapProps {
  children: React.ReactNode;
  size?: number;
  style?: React.CSSProperties;
}

export function Keycap(props: KeycapProps): JSX.Element;
