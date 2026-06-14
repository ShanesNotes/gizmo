One of the four illuminated covenant emblems, sliced from `covenant-emblems.svg`, with its state meter and manuscript label. The meter *is* the covenant's state.

```jsx
<CovenantRoundel index={0} fill={0.54} src="../../assets/sprites/covenant-emblems.svg" />
<CovenantRoundel index={3} fill={1} />   {/* Surge·Seal full → glows */}
```

`index`: 0 Flow·Thread · 1 Clutch·Breath · 2 Echo·Vigil · 3 Surge·Seal. Pass `src` as the correct relative path to the sprite sheet from your page. A full meter (`fill: 1`) adds the hue glow.
