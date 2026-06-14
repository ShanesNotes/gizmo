import React from 'react';

/** Build/covenant chip — hue dot + label + oxblood count badge; `sealed` = evolved/locked. */
export interface PillProps {
  children: React.ReactNode;
  /** hue dot color, e.g. var(--clutch) */
  dot?: string;
  /** count badge value; render ✦ when sealed */
  count?: React.ReactNode;
  /** evolved/locked treatment — gold rule, no oxblood badge */
  sealed?: boolean;
  style?: React.CSSProperties;
}

export function Pill(props: PillProps): JSX.Element;
