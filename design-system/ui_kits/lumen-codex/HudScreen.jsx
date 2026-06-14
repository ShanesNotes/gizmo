/* HUD — the page apparatus in play. Panels, covenant cluster, illumination. */
function HudScreen({ onLevelUp, onResults, t = {} }) {
  const { ASSET, VOID_BG, Stipple, PageFrame } = window.KitCommon;
  const { Panel, StatCell, BreathRow, VerdictBar, Pill, CovenantRoundel, Button, Eyebrow } = window.KitCommon.DS;
  const [covenants, setCov] = React.useState([0.54, 0.88, 0.4, 1]);

  // tweak config with safe defaults (kit runs standalone too)
  const cfg = {
    showEntities: true, showCallout: true, showStipple: true, showFrame: true,
    showBuild: true, showProgress: true, covenantLabels: true, clusterSize: 104, panelOpacity: 0.82,
    ...t,
  };

  return (
    <div style={{ position: 'absolute', inset: 0, overflow: 'hidden', color: 'var(--lumen)', fontFamily: 'var(--font-body)', background: VOID_BG, '--panel': `rgba(20,15,34,${cfg.panelOpacity})` }}>
      {cfg.showStipple && <Stipple opacity={0.45} size={15} />}
      {cfg.showFrame && <PageFrame inset={14} sealSize={22} />}

      {/* entities */}
      {cfg.showEntities && (
        <React.Fragment>
          <img src={`${ASSET}/sprites/enemy-counterfeit.svg`} alt="" style={{ position: 'absolute', right: 330, top: 150, width: 104 }} />
          <img src={`${ASSET}/sprites/enemy-drifter.svg`} alt="" style={{ position: 'absolute', left: 380, top: 185, width: 74 }} />
          <img src={`${ASSET}/sprites/cache-reliquary.svg`} alt="" style={{ position: 'absolute', right: 380, bottom: 250, width: 84, cursor: 'pointer' }} onClick={onResults} title="Open reliquary → Results" />
          <img src={`${ASSET}/sprites/pickup-spark.svg`} alt="" style={{ position: 'absolute', left: 600, top: 250, width: 42 }} />
          <img src={`${ASSET}/sprites/pickup-spark.svg`} alt="" style={{ position: 'absolute', left: 720, top: 370, width: 38 }} />
          <img src={`${ASSET}/sprites/pickup-spark.svg`} alt="" style={{ position: 'absolute', left: 560, bottom: 300, width: 36 }} />
        </React.Fragment>
      )}
      <img src={`${ASSET}/sprites/gizmo-illuminated.svg`} alt="Gizmo" style={{ position: 'absolute', left: '50%', top: '52%', transform: 'translate(-50%,-50%)', width: 188 }} />

      {/* illumination callout */}
      {cfg.showCallout && (
        <div style={{ position: 'absolute', left: 556, top: 300, textAlign: 'center' }}>
          <div style={{ position: 'absolute', left: '50%', top: 54, transform: 'translate(-50%,-50%)', width: 200, height: 200, borderRadius: '50%', background: 'radial-gradient(circle, rgba(232,188,136,.34), transparent 66%)' }} />
          <div style={{ position: 'relative', fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 46, letterSpacing: 1, background: 'linear-gradient(180deg,#FFF6E2,#E8BC88)', WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent', WebkitTextStroke: '2.5px #211B17', filter: 'drop-shadow(0 0 18px rgba(232,188,136,.6))' }}>ILLUMINED!</div>
          <div style={{ position: 'relative', fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 30, color: 'var(--surge)', marginTop: -4, textShadow: '0 2px 0 rgba(33,27,23,.6)' }}>+250</div>
        </div>
      )}

      {/* run panel — illumination + breath */}
      <div style={{ position: 'absolute', left: 34, top: 34 }}>
        <Panel style={{ display: 'flex', gap: 16, alignItems: 'center', padding: '12px 17px' }}>
          <div>
            <Eyebrow>Illumination</Eyebrow>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 31, color: 'var(--gold-leaf)', lineHeight: 1, textShadow: '0 0 16px rgba(232,188,136,.4)' }}>42,180</div>
          </div>
          <BreathRow total={5} kept={4} />
        </Panel>
      </div>

      {/* stats */}
      <div style={{ position: 'absolute', right: 34, top: 34 }}>
        <Panel style={{ padding: 10 }}>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 8 }}>
            <StatCell label="Rank" value="VII" hue="var(--flow)" />
            <StatCell label="Power" value="×3" hue="var(--echo)" />
            <StatCell label="Reliquary" value="4" hue="var(--surge)" />
            <StatCell label="Vigil" value="6:12" />
          </div>
        </Panel>
      </div>

      {/* verdict — the claiming (click to level up) */}
      <div style={{ position: 'absolute', left: '50%', top: 34, transform: 'translateX(-50%)', cursor: 'pointer' }} onClick={onLevelUp} title="Level up">
        <VerdictBar title="The Claiming" desc="Chase the gold — seal the bounty" count={3} total={5}
          icon={<img src={`${ASSET}/sprites/covenant-emblems.svg`} alt="" style={{ width: 34, height: 34, objectFit: 'none', objectPosition: '-512px -22px' }} />} />
      </div>

      {/* build */}
      {cfg.showBuild && (
        <div style={{ position: 'absolute', left: 34, top: 122, width: 224 }}>
          <Panel eyebrow="Covenant">
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-start', gap: 7, whiteSpace: 'nowrap' }}>
              <Pill dot="var(--clutch)" count={3}>Pulse Driver</Pill>
              <Pill dot="var(--flow)" count={2}>Spark Magnet</Pill>
              <Pill sealed count="✦">Echo Coil</Pill>
              <Pill dot="var(--echo)" count={1}>Nova Bloom</Pill>
            </div>
          </Panel>
        </div>
      )}

      {/* progress */}
      {cfg.showProgress && (
        <div style={{ position: 'absolute', left: 34, bottom: 34, width: 372 }}>
          <Panel>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ fontFamily: 'var(--font-manuscript)', fontWeight: 700, fontSize: 16, color: 'var(--gold-leaf)' }}>Rank VII · Illuminating</div>
              <Eyebrow>340 to wake</Eyebrow>
            </div>
            <div style={{ height: 7, borderRadius: 99, background: 'rgba(232,188,136,.16)', overflow: 'hidden', marginTop: 9 }}>
              <div style={{ height: '100%', width: '72%', borderRadius: 99, background: 'linear-gradient(90deg, var(--flow), var(--clutch), var(--surge))' }} />
            </div>
          </Panel>
        </div>
      )}

      {/* covenant cluster */}
      <div style={{ position: 'absolute', left: '50%', bottom: 24, transform: 'translateX(-50%)', display: 'flex', gap: 26, alignItems: 'flex-end' }}>
        {covenants.map((f, i) => (
          <div key={i} style={{ cursor: 'pointer' }} onClick={() => setCov((c) => c.map((v, j) => (j === i ? Math.min(1, v + 0.15) : v)))}>
            <CovenantRoundel index={i} fill={f} size={cfg.clusterSize} showLabel={cfg.covenantLabels} src={`${ASSET}/sprites/covenant-emblems.svg`} />
          </div>
        ))}
      </div>

      {/* boost */}
      <div style={{ position: 'absolute', right: 34, bottom: 34 }}>
        <Button variant="surge" style={{ width: 120, height: 92, flexDirection: 'column', gap: 2 }}>
          <span style={{ fontSize: 20 }}>BOOST</span>
          <span style={{ fontFamily: 'var(--font-manuscript)', fontWeight: 700, fontSize: 12, letterSpacing: 2, textTransform: 'uppercase', opacity: 0.8 }}>Snap Seal</span>
        </Button>
      </div>
    </div>
  );
}
window.HudScreen = HudScreen;
