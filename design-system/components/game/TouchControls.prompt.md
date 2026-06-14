The safe-area bottom touch band — fixed thumbstick (left) + Boost (right). Re-skins the shipping touch scheme; render it only on touch devices (`(hover:none) and (pointer:coarse)`).

```jsx
const NS = window.GizmoTheLumenCodexDesignSystem_512f7f;
<TouchControls
  Joystick={NS.Joystick} BoostButton={NS.BoostButton}
  small={isPhone} variant="fixed"
  boostState="snap-window" cooldown={0}
  onMove={(x,y)=>drive(x,y)} onBoost={fireBoost} />
```

Inject `Joystick` and `BoostButton` (the bundle namespace) so the cluster stays a pure composition. `small` selects the ≤560px geometry. `absolute={false}` to embed inline (e.g. in a card). Honors `env(safe-area-inset-*)`.
