/* The Lumen Codex — interactive screen flow. Title → HUD → Level-Up → Results. */
const { useState, useEffect, useCallback } = React;
const STAGE_W = 1280, STAGE_H = 720;

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "showEntities": true,
  "showCallout": true,
  "showStipple": true,
  "showFrame": true,
  "showBuild": true,
  "showProgress": true,
  "covenantLabels": true,
  "clusterSize": 104,
  "panelOpacity": 0.82
}/*EDITMODE-END*/;

function useStageScale() {
  const [scale, setScale] = useState(1);
  useEffect(() => {
    const fit = () => setScale(Math.min(window.innerWidth / STAGE_W, window.innerHeight / STAGE_H));
    fit();
    window.addEventListener('resize', fit);
    return () => window.removeEventListener('resize', fit);
  }, []);
  return scale;
}

const SCREENS = [
  { id: 'title', label: 'Title' },
  { id: 'hud', label: 'HUD' },
  { id: 'levelup', label: 'Level-Up' },
  { id: 'results', label: 'Results' },
];

// one-tap layout presets — batch-set the declutter tweaks (frame stays; it's identity)
const PRESETS = {
  full:    { showEntities: true,  showCallout: true,  showStipple: true,  showBuild: true,  showProgress: true,  covenantLabels: true,  panelOpacity: 0.82, clusterSize: 104 },
  calm:    { showEntities: false, showCallout: false, showStipple: true,  showBuild: true,  showProgress: true,  covenantLabels: false, panelOpacity: 0.70, clusterSize: 96 },
  minimal: { showEntities: false, showCallout: false, showStipple: false, showBuild: false, showProgress: false, covenantLabels: false, panelOpacity: 0.58, clusterSize: 88 },
};

function App() {
  const [screen, setScreen] = useState(() => localStorage.getItem('lumen-kit-screen') || 'title');
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const scale = useStageScale();
  const go = useCallback((s) => { setScreen(s); localStorage.setItem('lumen-kit-screen', s); }, []);

  // "press any key" on title
  useEffect(() => {
    if (screen !== 'title') return;
    const onKey = () => go('hud');
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [screen, go]);

  return (
    <div style={{ position: 'fixed', inset: 0, background: '#000', display: 'grid', placeItems: 'center', overflow: 'hidden' }}>
      <div style={{ width: STAGE_W, height: STAGE_H, transform: `scale(${scale})`, transformOrigin: 'center center', position: 'relative', boxShadow: '0 30px 120px rgba(0,0,0,.6)' }}>
        {screen === 'title' && <TitleScreen onStart={() => go('hud')} t={t} />}
        {screen === 'hud' && <HudScreen onLevelUp={() => go('levelup')} onResults={() => go('results')} t={t} />}
        {screen === 'levelup' && <LevelUpScreen onPick={() => go('hud')} t={t} />}
        {screen === 'results' && <ResultsScreen onRunBack={() => go('hud')} onTitle={() => go('title')} t={t} />}
      </div>

      {/* screen switcher (kit chrome, not part of the game) */}
      <div style={{ position: 'fixed', bottom: 14, left: '50%', transform: 'translateX(-50%)', display: 'flex', gap: 6, padding: 6, borderRadius: 99, background: 'rgba(20,15,34,.85)', border: '1px solid rgba(232,188,136,.3)', backdropFilter: 'blur(8px)', zIndex: 100 }}>
        {SCREENS.map((s) => (
          <button key={s.id} onClick={() => go(s.id)} style={{
            padding: '6px 14px', borderRadius: 99, border: 'none', cursor: 'pointer',
            fontFamily: 'var(--font-manuscript)', fontWeight: 700, fontSize: 12, letterSpacing: 1.5, textTransform: 'uppercase',
            background: screen === s.id ? 'var(--gold-leaf)' : 'transparent',
            color: screen === s.id ? 'var(--ink)' : 'var(--lumen-dim)',
            transition: 'all .15s ease',
          }}>{s.label}</button>
        ))}
      </div>

      <TweaksPanel title="Tweaks">
        <TweakSection label="Quick layout" />
        <div style={{ display: 'flex', gap: 8, width: '100%' }}>
          <TweakButton label="Full" secondary onClick={() => setTweak(PRESETS.full)} />
          <TweakButton label="Calm" onClick={() => setTweak(PRESETS.calm)} />
          <TweakButton label="Minimal" secondary onClick={() => setTweak(PRESETS.minimal)} />
        </div>

        <TweakSection label="Field" />
        <TweakToggle label="Field entities" value={t.showEntities} onChange={(v) => setTweak('showEntities', v)} />
        <TweakToggle label="Illumination callout" value={t.showCallout} onChange={(v) => setTweak('showCallout', v)} />
        <TweakToggle label="Stipple radiance" value={t.showStipple} onChange={(v) => setTweak('showStipple', v)} />
        <TweakToggle label="Page frame & seals" value={t.showFrame} onChange={(v) => setTweak('showFrame', v)} />

        <TweakSection label="HUD panels" />
        <TweakToggle label="Covenant build list" value={t.showBuild} onChange={(v) => setTweak('showBuild', v)} />
        <TweakToggle label="Run progress bar" value={t.showProgress} onChange={(v) => setTweak('showProgress', v)} />
        <TweakSlider label="Panel opacity" value={t.panelOpacity} min={0.4} max={0.95} step={0.01} onChange={(v) => setTweak('panelOpacity', v)} />

        <TweakSection label="Covenant cluster" />
        <TweakSlider label="Roundel size" value={t.clusterSize} min={68} max={120} step={2} unit="px" onChange={(v) => setTweak('clusterSize', v)} />
        <TweakToggle label="Cluster labels" value={t.covenantLabels} onChange={(v) => setTweak('covenantLabels', v)} />
      </TweaksPanel>
    </div>
  );
}

const __lumenRootEl = document.getElementById('root');
window.__lumenRoot = window.__lumenRoot || ReactDOM.createRoot(__lumenRootEl);
window.__lumenRoot.render(<App />);
