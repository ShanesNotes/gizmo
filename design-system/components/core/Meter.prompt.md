Thin pill progress bar — the covenant's / run's state *is* the meter. `fill` is 0..1.

```jsx
<Meter fill={0.72} xp />                         {/* XP gradient */}
<Meter fill={0.88} hue="var(--clutch)" />        {/* a covenant meter */}
<Meter fill={0.6} hue="linear-gradient(90deg,var(--coral),var(--surge))" />  {/* bounty */}
```
