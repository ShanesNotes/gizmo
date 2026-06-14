import React from 'react';

export type Rarity = 'common' | 'uncommon' | 'rare' | 'epic' | 'evolve';

/**
 * Level-up choice card — rarity reads by gold-leaf & seal density first, glow second.
 */
export interface UpgradeCardProps {
  /** common · uncommon · rare · epic · evolve */
  rarity?: Rarity;
  name?: string;
  desc?: string;
  /** override the rarity pill text (defaults to the rarity name; evolve → "⚡ Evolve") */
  pill?: string;
  statLabel?: string;
  statValue?: string;
  /** keycap value shown top-right (e.g. 1, 2, 3) */
  hotkey?: React.ReactNode;
  /** icon cell index into the upgrade-chip atlas (~100px cells) */
  iconIndex?: number;
  /** relative path to icons.svg from the consuming page */
  iconSrc?: string;
  /** override the epic lift; defaults true only for epic */
  lifted?: boolean;
  width?: number;
  style?: React.CSSProperties;
}

export function UpgradeCard(props: UpgradeCardProps): JSX.Element;
