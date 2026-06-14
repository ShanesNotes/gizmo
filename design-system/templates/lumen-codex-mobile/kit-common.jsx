/* Shared chrome for the Lumen Codex UI kit — the page apparatus. */
const ASSET = '../../assets';
const DS = window.GizmoTheLumenCodexDesignSystem_512f7f;

const VOID_BG = 'radial-gradient(120% 90% at 50% 20%, #1C1540 0%, #130E2A 48%, #0A0814 86%)';

function Stipple({ opacity = 0.45, size = 15, mask = null }) {
  return (
    <div style={{
      position: 'absolute', inset: 0, opacity,
      backgroundImage: 'radial-gradient(rgba(232,188,136,.14) 1px, transparent 1px)',
      backgroundSize: `${size}px ${size}px`,
      WebkitMask: mask, mask, pointerEvents: 'none',
    }} />
  );
}

/* The illuminated page frame + four corner wax-seals. */
function PageFrame({ inset = 14, sealSize = 22, ornate = false }) {
  const seals = [
    { left: inset - sealSize / 2, top: inset - sealSize / 2 },
    { right: inset - sealSize / 2, top: inset - sealSize / 2 },
    { left: inset - sealSize / 2, bottom: inset - sealSize / 2 },
    { right: inset - sealSize / 2, bottom: inset - sealSize / 2 },
  ];
  return (
    <React.Fragment>
      <div style={{
        position: 'absolute', inset,
        border: '2px solid var(--gold-tarnished)', borderRadius: 8,
        boxShadow: ornate
          ? 'inset 0 0 0 2px rgba(232,188,136,.5), inset 0 0 0 9px rgba(33,27,23,.6), inset 0 0 0 11px rgba(232,188,136,.25)'
          : 'inset 0 0 0 1px rgba(232,188,136,.4)',
        pointerEvents: 'none',
      }}>
        <div style={{ position: 'absolute', inset: ornate ? 7 : 4, border: '1px dashed rgba(232,188,136,.4)', borderRadius: 6 }} />
      </div>
      {seals.map((p, i) => (
        <div key={i} style={{
          position: 'absolute', width: sealSize, height: sealSize, transform: 'rotate(45deg)',
          background: 'var(--oxblood)', border: '2px solid var(--gold-leaf)',
          boxShadow: ornate ? '0 0 12px rgba(126,37,49,.6)' : 'none', ...p,
        }} />
      ))}
    </React.Fragment>
  );
}

/* A gold-ground aureole behind a payoff (secular geometry, never a halo). */
function Aureole({ size = 200, color = 'rgba(232,188,136,.34)' }) {
  return (
    <div style={{
      position: 'absolute', left: '50%', top: '50%', transform: 'translate(-50%,-50%)',
      width: size, height: size, borderRadius: '50%',
      background: `radial-gradient(circle, ${color}, transparent 66%)`, pointerEvents: 'none',
    }} />
  );
}

window.KitCommon = { ASSET, DS, VOID_BG, Stipple, PageFrame, Aureole };
