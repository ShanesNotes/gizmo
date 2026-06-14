/* Results — the verdict. STORM CLEARED, the score sealed into the record. */
function ResultsScreen({ onRunBack, onTitle }) {
  const { ASSET, VOID_BG } = window.KitCommon;
  const { Button, StatCell, Eyebrow } = window.KitCommon.DS;

  const records = [
    { label: 'Best Rank', value: '14', hue: 'var(--flow)' },
    { label: 'Top Flow', value: '×24', hue: 'var(--clutch)' },
    { label: 'Reliquaries', value: '11', hue: 'var(--surge)' },
    { label: 'Deepest', value: '8:40', hue: 'var(--echo)' },
  ];
  const awards = [
    { label: 'Bounty Hunter', value: '×7', c: 'var(--coral)', bg: 'rgba(255,107,126,.16)' },
    { label: 'Flow Master', value: '×24', c: 'var(--flow)', bg: 'rgba(91,230,164,.16)' },
    { label: 'Clutch King', value: '×12', c: 'var(--clutch)', bg: 'rgba(84,216,255,.16)' },
    { label: 'Cache Cracker', value: '×11', c: 'var(--surge)', bg: 'rgba(255,210,74,.16)' },
  ];
  const rows = [
    ['Sparks collected', '1,842'],
    ['Shapes cleared', '3,560'],
    ['Best Surge burst', '+4,800'],
  ];

  return (
    <div style={{ position: 'absolute', inset: 0, overflow: 'hidden', color: 'var(--lumen)', fontFamily: 'var(--font-body)', background: 'radial-gradient(120% 90% at 50% 14%, #1B1440, #120E28 50%, #0A0814)' }}>
      <div style={{ position: 'absolute', inset: 0, backgroundImage: 'radial-gradient(rgba(255,247,232,.05) 1.2px, transparent 1.2px)', backgroundSize: '40px 40px', opacity: 0.6 }} />
      <img src={`${ASSET}/sprites/gizmo.svg`} alt="" style={{ position: 'absolute', left: 'calc(50% + 250px)', top: 'calc(50% + 110px)', width: 120, transform: 'rotate(8deg)', filter: 'drop-shadow(0 14px 30px rgba(0,0,0,.5))' }} />

      <div style={{ position: 'absolute', left: '50%', top: '50%', transform: 'translate(-50%,-50%)', width: 560, padding: '30px 34px 26px', borderRadius: 26, background: 'linear-gradient(180deg, rgba(32,26,60,.96), rgba(16,12,32,.98))', border: '2px solid rgba(255,247,232,.16)', boxShadow: '0 40px 90px rgba(0,0,0,.6)', textAlign: 'center' }}>
        <img src={`${ASSET}/brand/emblem-illuminated.svg`} alt="" style={{ width: 60, height: 60, margin: '-58px auto 6px', display: 'block', filter: 'drop-shadow(0 0 24px rgba(255,210,74,.55))' }} />
        <div style={{ fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 40, letterSpacing: 1, lineHeight: 1, background: 'linear-gradient(180deg,#fff,var(--flow))', WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent' }}>STORM CLEARED</div>
        <div style={{ marginTop: 14 }}><Eyebrow color="var(--lumen-dim)" size={12}>Final Illumination</Eyebrow></div>
        <div style={{ fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 78, lineHeight: 1, marginTop: 8, color: 'var(--gold-leaf)', textShadow: '0 0 34px rgba(255,210,74,.45)' }}>128,540</div>
        <div style={{ display: 'inline-block', marginTop: 10, padding: '5px 14px', borderRadius: 99, background: 'rgba(91,230,164,.16)', color: 'var(--flow)', fontWeight: 900, fontSize: 13, letterSpacing: .5, border: '1.5px solid rgba(91,230,164,.5)' }}>★ NEW BEST — +12,400</div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 8, margin: '20px 0 14px' }}>
          {records.map((r) => <StatCell key={r.label} label={r.label} value={r.value} hue={r.hue} style={{ background: 'rgba(255,247,232,.05)', textAlign: 'center' }} />)}
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2,1fr)', gap: 8, marginBottom: 14 }}>
          {awards.map((a) => (
            <div key={a.label} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '9px 13px', borderRadius: 11, fontWeight: 900, fontSize: 13, letterSpacing: .4, background: a.bg, color: a.c }}>
              <span>{a.label}</span><b style={{ fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 15 }}>{a.value}</b>
            </div>
          ))}
        </div>

        <div style={{ marginBottom: 18, textAlign: 'left' }}>
          {rows.map(([k, v]) => (
            <div key={k} style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 2px', borderBottom: '1px solid rgba(255,247,232,.09)', fontWeight: 800, fontSize: 14, color: 'var(--lumen-dim)' }}>
              <span>{k}</span><b style={{ color: 'var(--lumen)', fontWeight: 900 }}>{v}</b>
            </div>
          ))}
        </div>

        <div style={{ display: 'flex', gap: 10 }}>
          <Button variant="primary" full onClick={onRunBack}>RUN IT BACK</Button>
          <Button variant="alt" style={{ flex: '0 0 150px' }} onClick={onTitle}>Title</Button>
        </div>
      </div>
    </div>
  );
}
window.ResultsScreen = ResultsScreen;
