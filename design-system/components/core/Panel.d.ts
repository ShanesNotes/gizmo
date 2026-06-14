import React from 'react';

export type PanelTone = 'gold' | 'danger' | 'plain';

/**
 * The dark-glass "page apparatus" container — gold rule border, inner luminous edge, dashed inner rule.
 */
export interface PanelProps {
  children: React.ReactNode;
  /** manuscript UPPERCASE eyebrow rendered at top */
  eyebrow?: React.ReactNode;
  /** gold (default) · danger (coral) · plain */
  tone?: PanelTone;
  /** show the dashed inner rule (default true) */
  dashed?: boolean;
  style?: React.CSSProperties;
}

export function Panel(props: PanelProps): JSX.Element;
