/* Portrait HUD — fluid, safe-area-aware. Reference 390×844. The mobile page apparatus. */
function HudPortrait({ small = true, t = {} }) {
  const { ASSET, VOID_BG, Stipple } = window.KitCommon;
  const DS = window.KitCommon.DS;
  const { Panel, BreathRow, VerdictBar, CovenantRoundel, Joystick, BoostButton, TouchControls, Eyebrow } = DS;
  const { useState, useRef, useCallback, useEffect } = React;

  const cfg = {
    showEntities: true, showStipple: true, showFrame: true, covenantLabels: false,
    clusterSize: 62, panelOpacity: 0.82, joystickVariant: 'fixed',
    ...t,
  };

  const [pos, setPos] = useState({ x: 0, y: 0 });
  const [boost, setBoost] = useState('snap-window');
  const [cd, setCd] = useState(0);
  const vel = useRef({ x: 0, y: 0 });
  const raf = useRef(0);

  // joystick drives Gizmo around the play area
  useEffect(() => {
    const tick = () => {
      setPos((p) => ({
        x: Math.max(-130, Math.min(130, p.x + vel.current.x * 4)),
        y: Math.max(-150, Math.min(150, p.y + vel.current.y * 4)),
      }));
      raf.current = requestAnimationFrame(tick);
    };
    raf.current = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf.current);
  }, []);
  const onMove = useCallback((dx, dy) => { vel.current = { x: dx, y: dy }; }, []);

  // boost timing loop demo: snap → scooping → cooling → default → snap
  const fireBoost = useCallback(() => {
    if (boost === 'cooling' || boost === 'queued') return;
    setBoost('scooping');
    setTimeout(() => {
      setBoost('cooling'); setCd(0);
      const t0 = Date.now();
      const sweep = setInterval(() => {
        const k = Math.min(1, (Date.now() - t0) / 2200);
        setCd(k);
        if (k >= 1) { clearInterval(sweep); setBoost('default'); setTimeout(() => setBoost('snap-window'), 1400); }
      }, 60);
    }, 1100);
  }, [boost]);

  return (
    <div style={{ position: 'absolute', inset: 0, overflow: 'hidden', color: 'var(--lumen)', fontFamily: 'var(--font-body)', background: VOID_BG, '--panel': `rgba(20,15,34,${cfg.panelOpacity})` }}>
      {cfg.showStipple && <Stipple opacity={0.4} size={13} />}
      {/* slim page frame */}
      {cfg.showFrame && <div style={{ position: 'absolute', inset: 8, border: '2px solid var(--gold-tarnished)', borderRadius: 14, boxShadow: 'inset 0 0 0 1px rgba(232,188,136,.35)', pointerEvents: 'none' }} />}

      {/* top bar: illumination + breath */}
      <div style={{ position: 'absolute', top: 18, left: 18, right: 18, display: 'flex', gap: 10, alignItems: 'stretch' }}>
        <Panel style={{ flex: 1, padding: '8px 12px' }}>
          <Eyebrow size={11}>Illumination</Eyebrow>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 26, color: 'var(--gold-leaf)', lineHeight: 1, textShadow: '0 0 14px rgba(232,188,136,.4)' }}>42,180</div>
        </Panel>
        <Panel style={{ display: 'grid', placeItems: 'center', padding: '8px 12px' }}>
          <BreathRow total={5} kept={4} size={18} />
        </Panel>
      </div>

      {/* bounty verdict chip */}
      <div style={{ position: 'absolute', top: 92, left: 18, right: 18 }}>
        <VerdictBar compact width="100%" count={3} total={5}
          icon={<img src={`${ASSET}/sprites/covenant-emblems.svg`} alt="" style={{ width: 26, height: 26, objectFit: 'none', objectPosition: '-518px -28px' }} />} />
      </div>

      {/* play area */}
      {cfg.showEntities && (
        <React.Fragment>
          <img src={`${ASSET}/sprites/pickup-spark.svg`} alt="" style={{ position: 'absolute', left: '28%', top: '40%', width: 30 }} />
          <img src={`${ASSET}/sprites/pickup-spark.svg`} alt="" style={{ position: 'absolute', right: '24%', top: '52%', width: 26 }} />
          <img src={`${ASSET}/sprites/enemy-drifter.svg`} alt="" style={{ position: 'absolute', right: '20%', top: '30%', width: 56 }} />
        </React.Fragment>
      )}
      <img src={`${ASSET}/sprites/gizmo-illuminated.svg`} alt="Gizmo" style={{ position: 'absolute', left: '50%', top: '46%', width: 96, transform: `translate(calc(-50% + ${pos.x}px), calc(-50% + ${pos.y}px))`, transition: 'transform 60ms linear', filter: boost === 'scooping' ? 'drop-shadow(0 0 18px var(--flow))' : 'none' }} />

      {/* covenant cluster (condensed) */}
      <div style={{ position: 'absolute', left: 0, right: 0, bottom: 168, display: 'flex', justifyContent: 'center', gap: 12 }}>
        {[0, 1, 2, 3].map((i) => (
          <CovenantRoundel key={i} index={i} fill={[0.54, 0.88, 0.4, 1][i]} size={cfg.clusterSize} showLabel={cfg.covenantLabels} src={`${ASSET}/sprites/covenant-emblems.svg`} />
        ))}
      </div>

      {/* touch controls (inline within the phone frame for preview) */}
      <TouchControls
        Joystick={Joystick} BoostButton={BoostButton}
        small={small} variant={cfg.joystickVariant} boostState={boost} cooldown={cd}
        onMove={onMove} onBoost={fireBoost}
        absolute={false}
        style={{ position: 'absolute', left: 18, right: 18, bottom: 24 }}
      />
    </div>
  );
}
window.HudPortrait = HudPortrait;
