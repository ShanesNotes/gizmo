import React from 'react';

/** Oxblood wax-seal diamond — page-frame corner mark or inline "sealed/maxed" token. */
export interface SealProps {
  size?: number;
  /** coral glow for an active seal */
  glow?: boolean;
  /** optional centered glyph (counter-rotated upright), e.g. a bolt or ✦ */
  children?: React.ReactNode;
  style?: React.CSSProperties;
}

export function Seal(props: SealProps): JSX.Element;
