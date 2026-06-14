Gizmo's dopamine action control — Fredoka face, squash-on-press; use `primary` for the forward action, `surge` for the gold reward/boost (the hinge), `alt`/`seal` for secondary.

```jsx
<Button variant="primary" size="lg">RUN IT BACK</Button>
<Button variant="surge">BOOST</Button>
<Button variant="alt">Title</Button>
<Button variant="seal" iconLeft={<span>↻</span>}>Reroll Spark</Button>
```

Variants: `primary` (mint go) · `surge` (gold, glow ring) · `alt` (dark-glass outline) · `seal` (gold rule, manuscript) · `ghost`. Sizes: `sm` `md` `lg`. Press squashes to 0.96; hover brightens. Pass `full` to stretch.
