The fixed bottom-left thumbstick, re-skinned into the page-apparatus language (ink ring + gold-leaf rule + stipple, gold knob with a cyan Gizmo-core). Geometry mirrors the shipping build.

```jsx
{/* live, draggable */}
<Joystick size={112} interactive onMove={(x, y) => move(x, y)} />
{/* static, showing a held direction */}
<Joystick size={94} dx={0.6} dy={-0.4} interactive={false} />
{/* A/B a floating stick without a rebuild */}
<Joystick variant="floating" />
```

Use `size={94}` (knob auto ≥44) on `≤560px` / short viewports. `onMove` reports a clamped unit vector; release resets to 0,0.
