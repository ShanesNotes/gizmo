The Snap Boost mechanic as a button (never a gesture). Six timing states, each read by color **and** label: gold ready/window, oxblood queued cost, mint scooping, dark-glass sweep cooling.

```jsx
<BoostButton state="default" />
<BoostButton state="snap-window" />          {/* pulsing gold ring — hit now */}
<BoostButton state="scooping" />             {/* mint — pulling sparks */}
<BoostButton state="cooling" cooldown={0.4} />
<BoostButton state="disabled" />
```

Use `size={72}` on small screens. Pulses honor `prefers-reduced-motion`. Drive `cooldown` 0→1 over the cooldown to fill the radial sweep.
