The level-up choice card. Rarity reads by gold-leaf & seal density first, glow second — Common (flat) → Uncommon → Rare → Epic (lifts) → Evolve (gold verdict). Icon is sliced from the upgrade-chip atlas.

```jsx
<UpgradeCard rarity="rare"  name="Pulse Driver" hotkey="1" iconIndex={2}
  desc="Your pulse fires a second beat on every shot." statLabel="Fire Rate" statValue="+18%"
  iconSrc="../../assets/sprites/icons.svg" />
<UpgradeCard rarity="epic"   name="Nova Bloom" hotkey="2" iconIndex={5} statLabel="Blast Area" statValue="+30%" />
<UpgradeCard rarity="evolve" name="Echo Coil"  hotkey="3" iconIndex={3} statLabel="Evolved" statValue="MAX" />
```

Lay three side-by-side for the level-up screen. Epic auto-lifts; pass `lifted` to override. Pass `iconSrc` as the correct relative path.
