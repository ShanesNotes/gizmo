import React from 'react';

export type ButtonVariant = 'primary' | 'surge' | 'alt' | 'seal' | 'ghost';
export type ButtonSize = 'sm' | 'md' | 'lg';

/**
 * Gizmo's primary action control — Fredoka face, squash-on-press, reward glow rings.
 */
export interface ButtonProps {
  children: React.ReactNode;
  /** primary = mint go · surge = gold reward (the hinge) · alt = dark outline · seal = gold rule · ghost */
  variant?: ButtonVariant;
  size?: ButtonSize;
  /** optional leading icon node (e.g. an <img> sprite) */
  iconLeft?: React.ReactNode;
  disabled?: boolean;
  /** stretch to container width */
  full?: boolean;
  style?: React.CSSProperties;
  onClick?: (e: React.MouseEvent<HTMLButtonElement>) => void;
}

export function Button(props: ButtonProps): JSX.Element;
