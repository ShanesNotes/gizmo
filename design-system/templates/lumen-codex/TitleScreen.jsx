/* Title — "wake the page". The wordmark, emblem, hero, marginal covenants. */
function TitleScreen({ onStart, best = '128,540', t = {} }) {
  const { ASSET, VOID_BG, Stipple, PageFrame } = window.KitCommon;
  const { Eyebrow } = window.KitCommon.DS;
  const cfg = { showStipple: true, showFrame: true, showEntities: true, ...t };

  return (
    <div
      onClick={onStart}
      style={{
        position: 'absolute', inset: 0, cursor: 'pointer', overflow: 'hidden',
        color: 'var(--lumen)', fontFamily: 'var(--font-body)',
        background: `radial-gradient(120% 80% at 50% 36%, #241A44 0%, #150F2C 44%, #0B0914 82%), radial-gradient(50% 40% at 50% 40%, rgba(232,188,136,.10), transparent 70%)`,
      }}
    >
      {cfg.showStipple && <Stipple opacity={0.5} size={13} mask="radial-gradient(80% 70% at 50% 42%, #000 30%, transparent 78%)" />}
      {cfg.showFrame && <PageFrame inset={26} sealSize={30} ornate />}

      {/* marginal covenant emblems — objects that forecast mechanics */}
      {cfg.showEntities && (
        <React.Fragment>
          <img src={`${ASSET}/sprites/covenant-emblems.svg`} alt="" style={{ position: 'absolute', left: 60, top: 230, width: 130, height: 130, objectFit: 'none', objectPosition: '-18px -16px', filter: 'drop-shadow(0 4px 12px rgba(0,0,0,.5))' }} />
          <img src={`${ASSET}/sprites/covenant-emblems.svg`} alt="" style={{ position: 'absolute', right: 60, top: 230, width: 130, height: 130, objectFit: 'none', objectPosition: '-498px -16px', filter: 'drop-shadow(0 4px 12px rgba(0,0,0,.5))' }} />
        </React.Fragment>
      )}

      <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center' }}>
        <img src={`${ASSET}/brand/emblem-illuminated.svg`} alt="Gizmo emblem" style={{ marginTop: 52, width: 104, height: 104, filter: 'drop-shadow(0 6px 26px rgba(232,188,136,.4))' }} />
        <div style={{
          marginTop: 8, fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 124, lineHeight: 0.92, letterSpacing: -2,
          background: 'linear-gradient(180deg,#FFF6E2 6%,#F0CE92 40%,#E8BC88 62%,#A87A2E 100%)',
          WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent',
          WebkitTextStroke: '3px #211B17',
          filter: 'drop-shadow(0 3px 0 rgba(33,27,23,.5)) drop-shadow(0 0 30px rgba(232,188,136,.35))',
        }}>GIZMO</div>
        <div style={{ marginTop: 2, fontFamily: 'var(--font-manuscript)', fontStyle: 'italic', fontWeight: 600, fontSize: 25, letterSpacing: 1.5, color: 'rgba(255,247,232,.82)' }}>
          A spark re-illuminates the dark
        </div>
      </div>

      <img src={`${ASSET}/sprites/gizmo-illuminated.svg`} alt="Gizmo" style={{ position: 'absolute', left: '50%', bottom: 60, transform: 'translateX(-50%)', width: 280, height: 305, filter: 'drop-shadow(0 16px 34px rgba(0,0,0,.55))' }} />

      {/* best illumination chip */}
      <div style={{ position: 'absolute', top: 48, left: 64, display: 'flex', alignItems: 'center', gap: 10, padding: '10px 14px', borderRadius: 8, background: 'rgba(20,15,34,.8)', border: '1.5px solid var(--gold-tarnished)', boxShadow: 'inset 0 0 0 1px rgba(232,188,136,.3)' }}>
        <div>
          <Eyebrow color="var(--lumen-dim)" size={12}>Best Illumination</Eyebrow>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 22, color: 'var(--gold-leaf)' }}>{best}</div>
        </div>
      </div>

      {/* sealed verdict plate -> press any key */}
      <div style={{ position: 'absolute', left: '50%', bottom: 40, transform: 'translateX(-50%)', display: 'flex', alignItems: 'center', gap: 14, padding: '12px 28px', borderRadius: 8, background: 'rgba(20,15,34,.82)', border: '2px solid var(--gold-tarnished)', boxShadow: 'inset 0 0 0 1px rgba(232,188,136,.4), 0 12px 30px rgba(0,0,0,.5)', fontFamily: 'var(--font-manuscript)', fontWeight: 700, fontSize: 20, letterSpacing: 4, color: 'var(--gold-leaf)', textTransform: 'uppercase' }}>
        <span style={{ width: 9, height: 9, background: 'var(--clutch)', borderRadius: '50%', boxShadow: '0 0 10px var(--clutch)', animation: 'kit-pulse 1.4s var(--ease-in-out) infinite' }} />
        Press any key to wake the page
      </div>
    </div>
  );
}
window.TitleScreen = TitleScreen;
