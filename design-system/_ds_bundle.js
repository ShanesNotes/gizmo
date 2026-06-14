/* @ds-bundle: {"format":3,"namespace":"GizmoTheLumenCodexDesignSystem_512f7f","components":[{"name":"Button","sourcePath":"components/core/Button.jsx"},{"name":"Eyebrow","sourcePath":"components/core/Eyebrow.jsx"},{"name":"Keycap","sourcePath":"components/core/Keycap.jsx"},{"name":"Meter","sourcePath":"components/core/Meter.jsx"},{"name":"Panel","sourcePath":"components/core/Panel.jsx"},{"name":"Pill","sourcePath":"components/core/Pill.jsx"},{"name":"Seal","sourcePath":"components/core/Seal.jsx"},{"name":"BoostButton","sourcePath":"components/game/BoostButton.jsx"},{"name":"BreathRow","sourcePath":"components/game/BreathRow.jsx"},{"name":"CovenantRoundel","sourcePath":"components/game/CovenantRoundel.jsx"},{"name":"Joystick","sourcePath":"components/game/Joystick.jsx"},{"name":"StatCell","sourcePath":"components/game/StatCell.jsx"},{"name":"TouchControls","sourcePath":"components/game/TouchControls.jsx"},{"name":"UpgradeCard","sourcePath":"components/game/UpgradeCard.jsx"},{"name":"VerdictBar","sourcePath":"components/game/VerdictBar.jsx"}],"sourceHashes":{"components/core/Button.jsx":"2940db226442","components/core/Eyebrow.jsx":"aa1052b90c0d","components/core/Keycap.jsx":"3c4f23807743","components/core/Meter.jsx":"d2a6986b93c7","components/core/Panel.jsx":"a1580af766c7","components/core/Pill.jsx":"9618e111c3ef","components/core/Seal.jsx":"88280efedb7c","components/game/BoostButton.jsx":"c0bc09ca1707","components/game/BreathRow.jsx":"0ad915c4e966","components/game/CovenantRoundel.jsx":"007ba82d8a35","components/game/Joystick.jsx":"f917eb468fb7","components/game/StatCell.jsx":"f911a7957345","components/game/TouchControls.jsx":"7753f92909c8","components/game/UpgradeCard.jsx":"851a01a7b942","components/game/VerdictBar.jsx":"be56e08220f1","ui_kits/lumen-codex/HudPortrait.jsx":"a4a7c8f4d183","ui_kits/lumen-codex/HudScreen.jsx":"56581331952a","ui_kits/lumen-codex/LevelUpScreen.jsx":"88fc9a509e8a","ui_kits/lumen-codex/ResultsScreen.jsx":"2c4440e4b33c","ui_kits/lumen-codex/TitleScreen.jsx":"108270a09c64","ui_kits/lumen-codex/app.jsx":"76103de0280f","ui_kits/lumen-codex/kit-common.jsx":"be638c5da719","ui_kits/lumen-codex/tweaks-panel.jsx":"6591467622ed"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.GizmoTheLumenCodexDesignSystem_512f7f = window.GizmoTheLumenCodexDesignSystem_512f7f || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/core/Button.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Button — Gizmo's dopamine action control.
 * Fredoka display face; squash on press; reward variants carry a glow ring.
 */
function Button({
  children,
  variant = 'primary',
  size = 'md',
  iconLeft = null,
  disabled = false,
  full = false,
  style = {},
  ...rest
}) {
  const sizes = {
    sm: {
      padding: '9px 16px',
      fontSize: 14,
      radius: 'var(--r-md)'
    },
    md: {
      padding: '13px 24px',
      fontSize: 17,
      radius: 'var(--r-lg)'
    },
    lg: {
      padding: '15px 30px',
      fontSize: 19,
      radius: 'var(--r-lg)'
    }
  };
  const s = sizes[size] || sizes.md;
  const variants = {
    // mint "go" — the primary forward action (Run it back)
    primary: {
      background: 'var(--flow)',
      color: '#0C2018',
      border: '2px solid transparent',
      boxShadow: 'var(--ring-flow), var(--shadow-press)'
    },
    // gold surge — the reward / boost action (the hinge)
    surge: {
      background: 'var(--surge)',
      color: 'var(--text-on-gold)',
      border: '2px solid var(--gold-leaf)',
      boxShadow: 'var(--ring-surge), var(--shadow-float)'
    },
    // dark-glass outline — secondary
    alt: {
      background: 'rgba(14,11,28,0.85)',
      color: 'var(--lumen)',
      border: '2px solid rgba(255,247,232,0.2)',
      boxShadow: 'none'
    },
    // ink + gold rule — manuscript secondary
    seal: {
      background: 'var(--panel)',
      color: 'var(--gold-leaf)',
      border: '2px solid var(--gold-tarnished)',
      boxShadow: 'var(--edge-luminous)'
    },
    // bare
    ghost: {
      background: 'transparent',
      color: 'var(--lumen-dim)',
      border: '2px solid transparent',
      boxShadow: 'none'
    }
  };
  const v = variants[variant] || variants.primary;
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    disabled: disabled,
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      gap: 10,
      fontFamily: 'var(--font-display)',
      fontWeight: 700,
      lineHeight: 1,
      cursor: disabled ? 'not-allowed' : 'pointer',
      opacity: disabled ? 0.45 : 1,
      padding: s.padding,
      fontSize: s.fontSize,
      borderRadius: s.radius,
      width: full ? '100%' : 'auto',
      transition: 'transform var(--dur-fast) var(--ease-settle), filter var(--dur-fast) ease, box-shadow var(--dur-fast) ease',
      ...v,
      ...style
    },
    onMouseDown: e => {
      if (!disabled) e.currentTarget.style.transform = 'scale(0.96)';
    },
    onMouseUp: e => {
      e.currentTarget.style.transform = 'scale(1)';
    },
    onMouseLeave: e => {
      e.currentTarget.style.transform = 'scale(1)';
    },
    onMouseEnter: e => {
      if (!disabled) e.currentTarget.style.filter = 'brightness(1.08)';
    }
  }, rest), iconLeft, children);
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Button.jsx", error: String((e && e.message) || e) }); }

// components/core/Eyebrow.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Eyebrow — the manuscript label (Cormorant Garamond, UPPERCASE, wide track).
 * Frames a value; never stars. Use above scores, stats, sections.
 */
function Eyebrow({
  children,
  color = 'var(--gold-leaf)',
  size = 13,
  style = {},
  ...rest
}) {
  return /*#__PURE__*/React.createElement("span", _extends({
    style: {
      fontFamily: 'var(--font-manuscript)',
      fontWeight: 700,
      fontSize: size,
      letterSpacing: '2px',
      textTransform: 'uppercase',
      color,
      ...style
    }
  }, rest), children);
}
Object.assign(__ds_scope, { Eyebrow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Eyebrow.jsx", error: String((e && e.message) || e) }); }

// components/core/Keycap.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Keycap — the round hotkey token on upgrade cards (1 / 2 / 3 / ↻).
 */
function Keycap({
  children,
  size = 30,
  style = {},
  ...rest
}) {
  return /*#__PURE__*/React.createElement("span", _extends({
    style: {
      display: 'grid',
      placeItems: 'center',
      width: size,
      height: size,
      borderRadius: '50%',
      background: 'rgba(12,10,22,0.7)',
      border: '1.5px solid rgba(255,247,232,0.2)',
      fontFamily: 'var(--font-body)',
      fontWeight: 900,
      fontSize: size * 0.5,
      color: 'var(--lumen)',
      ...style
    }
  }, rest), children);
}
Object.assign(__ds_scope, { Keycap });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Keycap.jsx", error: String((e && e.message) || e) }); }

// components/core/Meter.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Meter — a thin pill progress bar. The covenant's / run's state *is* the meter.
 * `fill` 0..1. `hue` sets the bar color; `xp` uses the mint→cyan→surge gradient.
 */
function Meter({
  fill = 0.5,
  hue = 'var(--gold-leaf)',
  xp = false,
  height = 7,
  track = 'rgba(232,188,136,0.16)',
  style = {},
  ...rest
}) {
  const pct = Math.max(0, Math.min(1, fill)) * 100;
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      height,
      borderRadius: 'var(--r-pill)',
      background: track,
      overflow: 'hidden',
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("div", {
    style: {
      height: '100%',
      width: `${pct}%`,
      borderRadius: 'var(--r-pill)',
      background: xp ? 'linear-gradient(90deg, var(--flow), var(--clutch), var(--surge))' : hue,
      transition: 'width var(--dur-mid) var(--ease-out)'
    }
  }));
}
Object.assign(__ds_scope, { Meter });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Meter.jsx", error: String((e && e.message) || e) }); }

// components/core/Panel.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Panel — the dark-glass "page apparatus" container.
 * Gold rule-line border, inner luminous edge, dashed inner rule.
 * The HUD workhorse: score readouts, build lists, progress.
 */
function Panel({
  children,
  eyebrow = null,
  tone = 'gold',
  // gold | danger | plain
  dashed = true,
  style = {},
  ...rest
}) {
  const tones = {
    gold: 'var(--gold-tarnished)',
    danger: 'rgba(255,107,126,0.55)',
    plain: 'rgba(255,247,232,0.16)'
  };
  const borderColor = tones[tone] || tones.gold;
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      position: 'relative',
      background: 'var(--panel)',
      border: `2px solid ${borderColor}`,
      borderRadius: 'var(--r-md)',
      boxShadow: 'var(--shadow-panel)',
      padding: '12px 16px',
      color: 'var(--lumen)',
      ...style
    }
  }, rest), dashed && /*#__PURE__*/React.createElement("span", {
    "aria-hidden": true,
    style: {
      content: '""',
      position: 'absolute',
      inset: 4,
      border: '1px dashed var(--rule-inner)',
      borderRadius: 8,
      pointerEvents: 'none'
    }
  }), eyebrow && /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-manuscript)',
      fontWeight: 700,
      fontSize: 13,
      letterSpacing: '2px',
      textTransform: 'uppercase',
      color: 'var(--gold-leaf)',
      position: 'relative',
      marginBottom: 8
    }
  }, eyebrow), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative'
    }
  }, children));
}
Object.assign(__ds_scope, { Panel });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Panel.jsx", error: String((e && e.message) || e) }); }

// components/core/Pill.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Pill — a build/covenant chip: hue dot + label + oxblood count badge.
 * The "seal" variant marks an evolved/locked upgrade with a gold rule.
 */
function Pill({
  children,
  dot = null,
  count = null,
  sealed = false,
  style = {},
  ...rest
}) {
  return /*#__PURE__*/React.createElement("span", _extends({
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 6,
      padding: '5px 9px',
      borderRadius: 'var(--r-sm)',
      fontFamily: 'var(--font-body)',
      fontSize: 12,
      fontWeight: 800,
      background: sealed ? 'rgba(232,188,136,0.16)' : 'rgba(232,188,136,0.08)',
      color: sealed ? 'var(--gold-leaf)' : 'var(--lumen)',
      boxShadow: sealed ? 'inset 0 0 0 1.5px var(--gold-tarnished)' : 'none',
      whiteSpace: 'nowrap',
      ...style
    }
  }, rest), dot && /*#__PURE__*/React.createElement("span", {
    style: {
      width: 8,
      height: 8,
      borderRadius: '50%',
      background: dot,
      flex: '0 0 auto'
    }
  }), children, count != null && /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'grid',
      placeItems: 'center',
      minWidth: 17,
      height: 17,
      padding: '0 4px',
      borderRadius: '50%',
      background: sealed ? 'transparent' : 'var(--oxblood)',
      color: sealed ? 'var(--surge)' : 'var(--lumen)',
      fontSize: 10,
      fontWeight: 900
    }
  }, count));
}
Object.assign(__ds_scope, { Pill });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Pill.jsx", error: String((e && e.message) || e) }); }

// components/core/Seal.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Seal — the oxblood wax-seal diamond. Page-frame corner mark, or an inline
 * "sealed/maxed" token. Carries a verdict, never decoration.
 */
function Seal({
  size = 22,
  glow = false,
  children = null,
  style = {},
  ...rest
}) {
  return /*#__PURE__*/React.createElement("span", _extends({
    style: {
      display: 'inline-grid',
      placeItems: 'center',
      width: size,
      height: size,
      transform: 'rotate(45deg)',
      background: 'var(--oxblood)',
      border: '2px solid var(--gold-leaf)',
      boxShadow: glow ? '0 0 12px var(--glow-coral)' : 'none',
      ...style
    }
  }, rest), children && /*#__PURE__*/React.createElement("span", {
    style: {
      transform: 'rotate(-45deg)',
      fontFamily: 'var(--font-display)',
      fontWeight: 700,
      fontSize: size * 0.5,
      color: 'var(--surge)'
    }
  }, children));
}
Object.assign(__ds_scope, { Seal });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Seal.jsx", error: String((e && e.message) || e) }); }

// components/game/BoostButton.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * BoostButton — the Snap Boost mechanic as a button (never a gesture).
 * Six timing states re-skinned to the codex: gold = ready/window, mint = scooping,
 * oxblood = queued cost, dark-glass sweep = cooling. See TOUCH-AND-RESPONSIVE-SPEC.md.
 */
const STATES = {
  default: {
    fill: 'var(--surge)',
    fg: '#3A2806',
    border: 'var(--gold-leaf)',
    label: 'BOOST',
    sub: 'Snap Seal',
    glow: 'var(--ring-surge), var(--shadow-float)',
    anim: null,
    op: 1
  },
  'snap-window': {
    fill: 'var(--surge)',
    fg: '#3A2806',
    border: 'var(--gold-leaf)',
    label: 'SNAP',
    sub: 'now',
    glow: null,
    anim: 'lumen-snap 0.7s ease-in-out infinite',
    animClass: 'lumen-anim-snap',
    op: 1
  },
  queued: {
    fill: 'var(--oxblood)',
    fg: 'var(--gold-leaf)',
    border: 'var(--gold-tarnished)',
    label: 'SET',
    sub: 'queued',
    glow: 'inset 0 0 0 1px rgba(232,188,136,0.4)',
    anim: null,
    op: 0.92
  },
  scooping: {
    fill: 'var(--flow)',
    fg: '#0C2018',
    border: 'var(--flow)',
    label: 'SCOOP',
    sub: 'pulling',
    glow: null,
    anim: 'lumen-scoop 0.6s ease-in-out infinite',
    animClass: 'lumen-anim-scoop',
    op: 1
  },
  cooling: {
    fill: 'rgba(20,15,34,0.85)',
    fg: 'var(--lumen-dim)',
    border: 'var(--gold-tarnished)',
    label: 'COOL',
    sub: '',
    glow: 'inset 0 0 0 1px rgba(232,188,136,0.25)',
    anim: null,
    op: 0.9
  },
  disabled: {
    fill: 'rgba(20,15,34,0.7)',
    fg: 'rgba(255,247,232,0.4)',
    border: 'rgba(232,188,136,0.3)',
    label: 'BOOST',
    sub: '',
    glow: null,
    anim: null,
    op: 0.45
  }
};
function BoostButton({
  state = 'default',
  cooldown = 0,
  size = 84,
  onClick = null,
  style = {},
  ...rest
}) {
  const s = STATES[state] || STATES.default;
  const cd = Math.max(0, Math.min(1, cooldown));
  const isDisabled = state === 'disabled';
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    disabled: isDisabled,
    onClick: isDisabled ? undefined : onClick,
    className: s.animClass || undefined,
    style: {
      position: 'relative',
      width: size,
      height: size,
      borderRadius: '50%',
      background: s.fill,
      border: `2px solid ${s.border}`,
      boxShadow: s.glow || 'none',
      animation: s.anim || 'none',
      opacity: s.op,
      cursor: isDisabled ? 'not-allowed' : 'pointer',
      display: 'grid',
      placeItems: 'center',
      textAlign: 'center',
      overflow: 'hidden',
      touchAction: 'manipulation',
      transition: 'background var(--dur-fast) ease, box-shadow var(--dur-fast) ease',
      ...style
    },
    onMouseDown: e => {
      if (!isDisabled) e.currentTarget.style.transform = 'scale(0.94)';
    },
    onMouseUp: e => {
      e.currentTarget.style.transform = 'scale(1)';
    },
    onMouseLeave: e => {
      e.currentTarget.style.transform = 'scale(1)';
    }
  }, rest), state === 'cooling' && /*#__PURE__*/React.createElement("span", {
    "aria-hidden": true,
    style: {
      position: 'absolute',
      inset: 0,
      borderRadius: '50%',
      background: `conic-gradient(from -90deg, transparent ${cd * 360}deg, rgba(8,6,18,0.6) 0)`,
      pointerEvents: 'none'
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'relative',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      lineHeight: 1
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-display)',
      fontWeight: 700,
      fontSize: size * 0.21,
      color: s.fg
    }
  }, s.label), s.sub && /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-manuscript)',
      fontWeight: 700,
      fontSize: size * 0.12,
      letterSpacing: 1.5,
      textTransform: 'uppercase',
      color: s.fg,
      opacity: 0.85,
      marginTop: 2
    }
  }, s.sub)));
}
Object.assign(__ds_scope, { BoostButton });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/game/BoostButton.jsx", error: String((e && e.message) || e) }); }

// components/game/BreathRow.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * BreathRow — the hearts-as-Breath meter. Lit flame-motes are kept breath;
 * spent ones go dim. (Hearts → Breath: kept vs. spent.)
 */
function BreathRow({
  total = 5,
  kept = 4,
  size = 20,
  style = {},
  ...rest
}) {
  const pips = [];
  for (let i = 0; i < total; i++) {
    const on = i < kept;
    pips.push(/*#__PURE__*/React.createElement("span", {
      key: i,
      style: {
        width: size * 0.75,
        height: size,
        background: on ? 'var(--coral)' : 'rgba(255,247,232,0.16)',
        boxShadow: on ? '0 0 9px var(--glow-coral)' : 'none',
        clipPath: 'polygon(50% 0, 72% 38%, 68% 74%, 50% 100%, 32% 74%, 28% 38%)'
      }
    }));
  }
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      display: 'flex',
      gap: 5,
      ...style
    }
  }, rest), pips);
}
Object.assign(__ds_scope, { BreathRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/game/BreathRow.jsx", error: String((e && e.message) || e) }); }

// components/game/CovenantRoundel.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * CovenantRoundel — one of the four illuminated covenant emblems, sliced from
 * the covenant-emblems sprite sheet, with its state meter and manuscript label.
 * index: 0 Flow·Thread · 1 Clutch·Breath · 2 Echo·Vigil · 3 Surge·Seal
 */
const COVENANTS = [{
  name: 'Flow',
  vow: 'Thread',
  hue: 'var(--flow)'
}, {
  name: 'Clutch',
  vow: 'Breath',
  hue: 'var(--clutch)'
}, {
  name: 'Echo',
  vow: 'Vigil',
  hue: 'var(--echo)'
}, {
  name: 'Surge',
  vow: 'Seal',
  hue: 'var(--surge)'
}];
function CovenantRoundel({
  index = 0,
  fill = 0.5,
  size = 120,
  showLabel = true,
  showMeter = true,
  src = 'assets/sprites/covenant-emblems.svg',
  style = {},
  ...rest
}) {
  const c = COVENANTS[index] || COVENANTS[0];
  // sheet: 600px wide, four 150px cells; circle region ~132px, center y≈74
  const k = size / 132;
  const pct = Math.max(0, Math.min(1, fill)) * 100;
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      display: 'inline-flex',
      flexDirection: 'column',
      alignItems: 'center',
      gap: 8,
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("div", {
    style: {
      width: size,
      height: size,
      backgroundImage: `url(${src})`,
      backgroundRepeat: 'no-repeat',
      backgroundSize: `${600 * k}px auto`,
      backgroundPosition: `${-(9 + index * 150) * k}px ${-8 * k}px`,
      filter: fill >= 1 ? `drop-shadow(0 0 16px ${c.hue})` : 'none'
    }
  }), showMeter && /*#__PURE__*/React.createElement("div", {
    style: {
      width: size * 0.6,
      height: 5,
      borderRadius: 'var(--r-pill)',
      background: 'rgba(232,188,136,0.2)',
      overflow: 'hidden',
      marginTop: -size * 0.12
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      height: '100%',
      width: `${pct}%`,
      background: c.hue,
      borderRadius: 'var(--r-pill)',
      transition: 'width var(--dur-mid) var(--ease-out)'
    }
  })), showLabel && /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-manuscript)',
      fontWeight: 700,
      fontSize: 12,
      letterSpacing: '1.5px',
      textTransform: 'uppercase',
      color: c.hue
    }
  }, c.name, " \xB7 ", c.vow));
}
Object.assign(__ds_scope, { CovenantRoundel });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/game/CovenantRoundel.jsx", error: String((e && e.message) || e) }); }

// components/game/Joystick.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Joystick — the fixed bottom-left thumbstick, re-skinned into the page-apparatus
 * language (ink ring + gold-leaf rule + stipple; gold knob with a cyan Gizmo-core).
 * Mirrors the shipping build's geometry (112/52 → 94/44). See TOUCH-AND-RESPONSIVE-SPEC.md.
 */
const {
  useState,
  useRef,
  useCallback
} = React;
function Joystick({
  size = 112,
  knobSize = null,
  // defaults to ~46% of ring
  variant = 'fixed',
  // 'fixed' | 'floating'
  dx = 0,
  // static knob offset -1..1 (used when not dragging)
  dy = 0,
  interactive = true,
  onMove = null,
  // (dx, dy) => void, each -1..1
  style = {},
  ...rest
}) {
  const knob = knobSize || Math.round(size * 0.46);
  const travel = (size - knob) / 2;
  const ref = useRef(null);
  const [drag, setDrag] = useState(null); // {dx,dy} while active
  const [active, setActive] = useState(false);
  const vec = drag || {
    dx,
    dy
  };
  const visibleRing = variant === 'fixed' || active;
  const handle = useCallback(e => {
    const el = ref.current;
    if (!el) return;
    const r = el.getBoundingClientRect();
    const cx = r.left + r.width / 2,
      cy = r.top + r.height / 2;
    let nx = (e.clientX - cx) / travel,
      ny = (e.clientY - cy) / travel;
    const m = Math.hypot(nx, ny);
    if (m > 1) {
      nx /= m;
      ny /= m;
    }
    setDrag({
      dx: nx,
      dy: ny
    });
    onMove && onMove(nx, ny);
  }, [travel, onMove]);
  const start = e => {
    if (!interactive) return;
    e.currentTarget.setPointerCapture?.(e.pointerId);
    setActive(true);
    handle(e);
  };
  const move = e => {
    if (active) handle(e);
  };
  const end = () => {
    setActive(false);
    setDrag(null);
    onMove && onMove(0, 0);
  };
  return /*#__PURE__*/React.createElement("div", _extends({
    ref: ref,
    onPointerDown: start,
    onPointerMove: move,
    onPointerUp: end,
    onPointerCancel: end,
    style: {
      position: 'relative',
      width: size,
      height: size,
      borderRadius: '50%',
      touchAction: 'none',
      cursor: interactive ? 'grab' : 'default',
      userSelect: 'none',
      // ring base — ink fill, gold-leaf rule, stipple, dashed inner rule
      background: visibleRing ? 'rgba(20,15,34,0.7)' : 'transparent',
      border: visibleRing ? '2px solid var(--gold-tarnished)' : '2px dashed rgba(232,188,136,0.25)',
      boxShadow: visibleRing ? 'inset 0 0 0 1px rgba(232,188,136,0.3), 0 10px 24px rgba(0,0,0,0.45)' : 'none',
      backgroundImage: visibleRing ? 'radial-gradient(rgba(232,188,136,0.14) 1px, transparent 1px)' : 'none',
      backgroundSize: '11px 11px',
      transition: 'background var(--dur-fast) ease, border-color var(--dur-fast) ease',
      ...style
    }
  }, rest), visibleRing && /*#__PURE__*/React.createElement("span", {
    "aria-hidden": true,
    style: {
      position: 'absolute',
      inset: 5,
      borderRadius: '50%',
      border: '1px dashed rgba(232,188,136,0.3)',
      pointerEvents: 'none'
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      left: '50%',
      top: '50%',
      width: knob,
      height: knob,
      borderRadius: '50%',
      transform: `translate(calc(-50% + ${vec.dx * travel}px), calc(-50% + ${vec.dy * travel}px))`,
      background: 'radial-gradient(circle at 50% 35%, #FFF6E2, #E8BC88 55%, #A87A2E 100%)',
      border: '2px solid var(--ink)',
      boxShadow: '0 4px 12px rgba(0,0,0,0.5), inset 0 -3px 6px rgba(122,80,32,0.5)',
      display: 'grid',
      placeItems: 'center',
      transition: active ? 'none' : 'transform var(--dur-mid) var(--ease-settle)'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: knob * 0.26,
      height: knob * 0.26,
      borderRadius: '50%',
      background: 'var(--clutch)',
      boxShadow: '0 0 8px var(--clutch)'
    }
  })));
}
Object.assign(__ds_scope, { Joystick });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/game/Joystick.jsx", error: String((e && e.message) || e) }); }

// components/game/StatCell.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * StatCell — a small gold-dust stat cell: manuscript eyebrow + Fredoka value.
 * The HUD stat-grid unit (Rank, Power, Reliquary, Vigil).
 */
function StatCell({
  label,
  value,
  hue = 'var(--lumen)',
  style = {},
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      minWidth: 74,
      padding: '7px 11px',
      borderRadius: 'var(--r-sm)',
      background: 'var(--surface-inset)',
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-manuscript)',
      fontWeight: 700,
      fontSize: 13,
      letterSpacing: '2px',
      textTransform: 'uppercase',
      color: 'var(--gold-leaf)'
    }
  }, label), /*#__PURE__*/React.createElement("b", {
    style: {
      display: 'block',
      fontFamily: 'var(--font-display)',
      fontWeight: 700,
      fontSize: 19,
      marginTop: 1,
      color: hue
    }
  }, value));
}
Object.assign(__ds_scope, { StatCell });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/game/StatCell.jsx", error: String((e && e.message) || e) }); }

// components/game/TouchControls.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * TouchControls — the safe-area bottom band: fixed thumbstick (left) + Boost (right).
 * Gate its render on `(hover:none) and (pointer:coarse)` in the consuming layout.
 * `small` switches to the ≤560px / short-viewport geometry. See TOUCH-AND-RESPONSIVE-SPEC.md.
 */
function TouchControls({
  variant = 'fixed',
  small = false,
  boostState = 'default',
  cooldown = 0,
  onMove = null,
  onBoost = null,
  gutter = 22,
  absolute = true,
  // position fixed to the viewport's safe area
  Joystick,
  // pass the components in (kit injects them)
  BoostButton,
  style = {},
  ...rest
}) {
  const ring = small ? 94 : 112;
  const boost = small ? 72 : 84;
  const gap = small ? 16 : gutter;
  const frame = absolute ? {
    position: 'fixed',
    left: 0,
    right: 0,
    bottom: 0,
    paddingLeft: `calc(env(safe-area-inset-left) + ${gap}px)`,
    paddingRight: `calc(env(safe-area-inset-right) + ${gap}px)`,
    paddingBottom: `calc(env(safe-area-inset-bottom) + ${gap}px)`,
    pointerEvents: 'none',
    zIndex: 50
  } : {
    position: 'relative'
  };
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      ...frame,
      display: 'flex',
      alignItems: 'flex-end',
      justifyContent: 'space-between',
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("div", {
    style: {
      pointerEvents: 'auto'
    }
  }, Joystick && /*#__PURE__*/React.createElement(Joystick, {
    size: ring,
    variant: variant,
    interactive: true,
    onMove: onMove
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      pointerEvents: 'auto'
    }
  }, BoostButton && /*#__PURE__*/React.createElement(BoostButton, {
    state: boostState,
    cooldown: cooldown,
    size: boost,
    onClick: onBoost
  })));
}
Object.assign(__ds_scope, { TouchControls });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/game/TouchControls.jsx", error: String((e && e.message) || e) }); }

// components/game/UpgradeCard.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * UpgradeCard — the level-up choice card. Rarity reads by gold-leaf & seal
 * density first, glow second. Epic lifts; Evolve is the gold verdict.
 * Icon is sliced from the upgrade-chip atlas (icons.svg, ~100px cells).
 */
const RARITY = {
  common: {
    color: '#9892B4',
    glow: 'none',
    pillBg: 'rgba(152,146,180,0.9)',
    pillFg: '#16131f'
  },
  uncommon: {
    color: 'var(--flow)',
    glow: '0 0 28px rgba(91,230,164,0.18)',
    pillBg: 'var(--flow)',
    pillFg: '#0c2018'
  },
  rare: {
    color: 'var(--clutch)',
    glow: 'var(--glow-rare)',
    pillBg: 'var(--clutch)',
    pillFg: '#072430'
  },
  epic: {
    color: 'var(--pink)',
    glow: 'var(--glow-epic)',
    pillBg: 'var(--pink)',
    pillFg: '#3a0a2a'
  },
  evolve: {
    color: 'var(--surge)',
    glow: 'var(--glow-evolve)',
    pillBg: 'var(--surge)',
    pillFg: '#3a2806'
  }
};
function UpgradeCard({
  rarity = 'rare',
  name = 'Pulse Driver',
  desc = '',
  label = '',
  pill = null,
  // override pill text; defaults to rarity name
  statLabel = '',
  statValue = '',
  hotkey = null,
  iconIndex = 2,
  iconSrc = 'assets/sprites/icons.svg',
  lifted = null,
  // override the epic lift; default true only for epic
  width = 300,
  style = {},
  ...rest
}) {
  const r = RARITY[rarity] || RARITY.rare;
  const doLift = lifted == null ? rarity === 'epic' : lifted;
  const pillText = pill || (rarity === 'evolve' ? '⚡ Evolve' : rarity.charAt(0).toUpperCase() + rarity.slice(1));
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      position: 'relative',
      width,
      minHeight: 362,
      borderRadius: 'var(--r-xl)',
      padding: 'var(--inset-card)',
      overflow: 'hidden',
      display: 'flex',
      flexDirection: 'column',
      background: 'linear-gradient(180deg, rgba(34,28,64,0.92), rgba(18,14,36,0.96))',
      border: `3px solid ${r.color}`,
      boxShadow: `var(--shadow-card), ${r.glow}`,
      color: 'var(--lumen)',
      transform: doLift ? 'translateY(-14px) scale(1.02)' : 'none',
      transition: 'transform var(--dur-mid) var(--ease-settle), box-shadow var(--dur-mid) ease',
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("span", {
    style: {
      alignSelf: 'flex-start',
      fontSize: 11,
      fontWeight: 900,
      letterSpacing: '1.4px',
      textTransform: 'uppercase',
      padding: '5px 11px',
      borderRadius: 'var(--r-pill)',
      background: r.pillBg,
      color: r.pillFg
    }
  }, pillText), hotkey != null && /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      top: 16,
      right: 16,
      width: 30,
      height: 30,
      borderRadius: '50%',
      display: 'grid',
      placeItems: 'center',
      background: 'rgba(12,10,22,0.7)',
      fontWeight: 900,
      fontSize: 15,
      border: '1.5px solid rgba(255,247,232,0.2)'
    }
  }, hotkey), /*#__PURE__*/React.createElement("div", {
    style: {
      width: 92,
      height: 92,
      margin: '18px auto 10px',
      display: 'grid',
      placeItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 96,
      height: 96,
      backgroundImage: `url(${iconSrc})`,
      backgroundRepeat: 'no-repeat',
      backgroundPosition: `${-iconIndex * 100}px 0`
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-display)',
      fontWeight: 700,
      fontSize: 25,
      textAlign: 'center',
      lineHeight: 1.05,
      color: rarity === 'evolve' ? 'var(--surge)' : 'var(--lumen)'
    }
  }, name), desc && /*#__PURE__*/React.createElement("div", {
    style: {
      color: 'var(--lumen-dim)',
      fontWeight: 800,
      fontSize: 14,
      textAlign: 'center',
      marginTop: 8,
      lineHeight: 1.4
    }
  }, desc), (statLabel || statValue) && /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 'auto',
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      paddingTop: 12,
      borderTop: '1px solid rgba(255,247,232,0.12)',
      fontSize: 12,
      fontWeight: 900,
      letterSpacing: '1px',
      textTransform: 'uppercase',
      color: 'var(--lumen-dim)'
    }
  }, /*#__PURE__*/React.createElement("span", null, statLabel), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-display)',
      fontWeight: 700,
      fontSize: 16,
      padding: '3px 12px',
      borderRadius: 'var(--r-pill)',
      letterSpacing: 0,
      background: `color-mix(in srgb, ${r.color} 18%, transparent)`,
      color: r.color
    }
  }, statValue)), /*#__PURE__*/React.createElement("span", {
    "aria-hidden": true,
    style: {
      position: 'absolute',
      right: -40,
      bottom: -50,
      width: 150,
      height: 150,
      borderRadius: '50%',
      border: '14px solid rgba(255,247,232,0.06)',
      pointerEvents: 'none'
    }
  }));
}
Object.assign(__ds_scope, { UpgradeCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/game/UpgradeCard.jsx", error: String((e && e.message) || e) }); }

// components/game/VerdictBar.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * VerdictBar — the bounty/objective panel ("borders that behave"). A coral-ruled
 * dark-glass plate: emblem + manuscript title + count + coral→gold progress.
 */
function VerdictBar({
  title = 'The Claiming',
  desc = 'Chase the gold — seal the bounty',
  count = 3,
  total = 5,
  fill = null,
  // 0..1; defaults to count/total
  icon = null,
  // optional leading node (sprite/emblem)
  compact = false,
  // slim single-line chip for portrait HUD
  width = 368,
  style = {},
  ...rest
}) {
  const pct = (fill == null ? count / total : fill) * 100;
  if (compact) {
    return /*#__PURE__*/React.createElement("div", _extends({
      style: {
        position: 'relative',
        width,
        display: 'flex',
        alignItems: 'center',
        gap: 10,
        padding: '8px 12px',
        background: 'var(--panel)',
        border: '2px solid rgba(255,107,126,0.55)',
        borderRadius: 'var(--r-pill)',
        boxShadow: 'var(--shadow-panel)',
        color: 'var(--lumen)',
        overflow: 'hidden',
        ...style
      }
    }, rest), icon, /*#__PURE__*/React.createElement("div", {
      style: {
        fontFamily: 'var(--font-manuscript)',
        fontWeight: 700,
        fontSize: 15,
        lineHeight: 1,
        color: 'var(--lumen)',
        whiteSpace: 'nowrap'
      }
    }, title), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        height: 5,
        borderRadius: 'var(--r-pill)',
        background: 'rgba(232,188,136,0.16)',
        overflow: 'hidden'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        height: '100%',
        width: `${pct}%`,
        borderRadius: 'var(--r-pill)',
        background: 'linear-gradient(90deg, var(--coral), var(--surge))',
        transition: 'width var(--dur-mid) var(--ease-out)'
      }
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        fontFamily: 'var(--font-display)',
        fontWeight: 700,
        fontSize: 16,
        color: 'var(--coral)'
      }
    }, count, /*#__PURE__*/React.createElement("span", {
      style: {
        color: 'var(--lumen-dim)',
        fontSize: 11
      }
    }, "/", total)));
  }
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      position: 'relative',
      width,
      display: 'grid',
      gridTemplateColumns: `${icon ? '34px ' : ''}1fr auto`,
      gap: 10,
      alignItems: 'center',
      padding: '10px 14px 13px',
      background: 'var(--panel)',
      border: '2px solid rgba(255,107,126,0.55)',
      borderRadius: 'var(--r-md)',
      boxShadow: 'var(--shadow-panel)',
      color: 'var(--lumen)',
      ...style
    }
  }, rest), icon, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-manuscript)',
      fontWeight: 700,
      fontSize: 19,
      lineHeight: 1,
      color: 'var(--lumen)'
    }
  }, title), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--lumen-dim)',
      fontWeight: 800,
      marginTop: 3
    }
  }, desc)), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-display)',
      fontWeight: 700,
      fontSize: 20,
      color: 'var(--coral)'
    }
  }, count, /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--lumen-dim)',
      fontSize: 13
    }
  }, "/", total)), /*#__PURE__*/React.createElement("div", {
    style: {
      gridColumn: '1 / -1',
      height: 7,
      borderRadius: 'var(--r-pill)',
      background: 'rgba(232,188,136,0.16)',
      overflow: 'hidden',
      marginTop: 3
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      height: '100%',
      width: `${pct}%`,
      borderRadius: 'var(--r-pill)',
      background: 'linear-gradient(90deg, var(--coral), var(--surge))',
      transition: 'width var(--dur-mid) var(--ease-out)'
    }
  })));
}
Object.assign(__ds_scope, { VerdictBar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/game/VerdictBar.jsx", error: String((e && e.message) || e) }); }

// ui_kits/lumen-codex/HudPortrait.jsx
try { (() => {
/* Portrait HUD — fluid, safe-area-aware. Reference 390×844. The mobile page apparatus. */
function HudPortrait({
  small = true,
  t = {}
}) {
  const {
    ASSET,
    VOID_BG,
    Stipple
  } = window.KitCommon;
  const DS = window.KitCommon.DS;
  const {
    Panel,
    BreathRow,
    VerdictBar,
    CovenantRoundel,
    Joystick,
    BoostButton,
    TouchControls,
    Eyebrow
  } = DS;
  const {
    useState,
    useRef,
    useCallback,
    useEffect
  } = React;
  const cfg = {
    showEntities: true,
    showStipple: true,
    showFrame: true,
    covenantLabels: false,
    clusterSize: 62,
    panelOpacity: 0.82,
    joystickVariant: 'fixed',
    ...t
  };
  const [pos, setPos] = useState({
    x: 0,
    y: 0
  });
  const [boost, setBoost] = useState('snap-window');
  const [cd, setCd] = useState(0);
  const vel = useRef({
    x: 0,
    y: 0
  });
  const raf = useRef(0);

  // joystick drives Gizmo around the play area
  useEffect(() => {
    const tick = () => {
      setPos(p => ({
        x: Math.max(-130, Math.min(130, p.x + vel.current.x * 4)),
        y: Math.max(-150, Math.min(150, p.y + vel.current.y * 4))
      }));
      raf.current = requestAnimationFrame(tick);
    };
    raf.current = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf.current);
  }, []);
  const onMove = useCallback((dx, dy) => {
    vel.current = {
      x: dx,
      y: dy
    };
  }, []);

  // boost timing loop demo: snap → scooping → cooling → default → snap
  const fireBoost = useCallback(() => {
    if (boost === 'cooling' || boost === 'queued') return;
    setBoost('scooping');
    setTimeout(() => {
      setBoost('cooling');
      setCd(0);
      const t0 = Date.now();
      const sweep = setInterval(() => {
        const k = Math.min(1, (Date.now() - t0) / 2200);
        setCd(k);
        if (k >= 1) {
          clearInterval(sweep);
          setBoost('default');
          setTimeout(() => setBoost('snap-window'), 1400);
        }
      }, 60);
    }, 1100);
  }, [boost]);
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      overflow: 'hidden',
      color: 'var(--lumen)',
      fontFamily: 'var(--font-body)',
      background: VOID_BG,
      '--panel': `rgba(20,15,34,${cfg.panelOpacity})`
    }
  }, cfg.showStipple && /*#__PURE__*/React.createElement(Stipple, {
    opacity: 0.4,
    size: 13
  }), cfg.showFrame && /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 8,
      border: '2px solid var(--gold-tarnished)',
      borderRadius: 14,
      boxShadow: 'inset 0 0 0 1px rgba(232,188,136,.35)',
      pointerEvents: 'none'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      top: 18,
      left: 18,
      right: 18,
      display: 'flex',
      gap: 10,
      alignItems: 'stretch'
    }
  }, /*#__PURE__*/React.createElement(Panel, {
    style: {
      flex: 1,
      padding: '8px 12px'
    }
  }, /*#__PURE__*/React.createElement(Eyebrow, {
    size: 11
  }, "Illumination"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-display)',
      fontWeight: 700,
      fontSize: 26,
      color: 'var(--gold-leaf)',
      lineHeight: 1,
      textShadow: '0 0 14px rgba(232,188,136,.4)'
    }
  }, "42,180")), /*#__PURE__*/React.createElement(Panel, {
    style: {
      display: 'grid',
      placeItems: 'center',
      padding: '8px 12px'
    }
  }, /*#__PURE__*/React.createElement(BreathRow, {
    total: 5,
    kept: 4,
    size: 18
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      top: 92,
      left: 18,
      right: 18
    }
  }, /*#__PURE__*/React.createElement(VerdictBar, {
    compact: true,
    width: "100%",
    count: 3,
    total: 5,
    icon: /*#__PURE__*/React.createElement("img", {
      src: `${ASSET}/sprites/covenant-emblems.svg`,
      alt: "",
      style: {
        width: 26,
        height: 26,
        objectFit: 'none',
        objectPosition: '-518px -28px'
      }
    })
  })), cfg.showEntities && /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("img", {
    src: `${ASSET}/sprites/pickup-spark.svg`,
    alt: "",
    style: {
      position: 'absolute',
      left: '28%',
      top: '40%',
      width: 30
    }
  }), /*#__PURE__*/React.createElement("img", {
    src: `${ASSET}/sprites/pickup-spark.svg`,
    alt: "",
    style: {
      position: 'absolute',
      right: '24%',
      top: '52%',
      width: 26
    }
  }), /*#__PURE__*/React.createElement("img", {
    src: `${ASSET}/sprites/enemy-drifter.svg`,
    alt: "",
    style: {
      position: 'absolute',
      right: '20%',
      top: '30%',
      width: 56
    }
  })), /*#__PURE__*/React.createElement("img", {
    src: `${ASSET}/sprites/gizmo-illuminated.svg`,
    alt: "Gizmo",
    style: {
      position: 'absolute',
      left: '50%',
      top: '46%',
      width: 96,
      transform: `translate(calc(-50% + ${pos.x}px), calc(-50% + ${pos.y}px))`,
      transition: 'transform 60ms linear',
      filter: boost === 'scooping' ? 'drop-shadow(0 0 18px var(--flow))' : 'none'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: 0,
      right: 0,
      bottom: 168,
      display: 'flex',
      justifyContent: 'center',
      gap: 12
    }
  }, [0, 1, 2, 3].map(i => /*#__PURE__*/React.createElement(CovenantRoundel, {
    key: i,
    index: i,
    fill: [0.54, 0.88, 0.4, 1][i],
    size: cfg.clusterSize,
    showLabel: cfg.covenantLabels,
    src: `${ASSET}/sprites/covenant-emblems.svg`
  }))), /*#__PURE__*/React.createElement(TouchControls, {
    Joystick: Joystick,
    BoostButton: BoostButton,
    small: small,
    variant: cfg.joystickVariant,
    boostState: boost,
    cooldown: cd,
    onMove: onMove,
    onBoost: fireBoost,
    absolute: false,
    style: {
      position: 'absolute',
      left: 18,
      right: 18,
      bottom: 24
    }
  }));
}
window.HudPortrait = HudPortrait;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/lumen-codex/HudPortrait.jsx", error: String((e && e.message) || e) }); }

// ui_kits/lumen-codex/HudScreen.jsx
try { (() => {
/* HUD — the page apparatus in play. Panels, covenant cluster, illumination. */
function HudScreen({
  onLevelUp,
  onResults,
  t = {}
}) {
  const {
    ASSET,
    VOID_BG,
    Stipple,
    PageFrame
  } = window.KitCommon;
  const {
    Panel,
    StatCell,
    BreathRow,
    VerdictBar,
    Pill,
    CovenantRoundel,
    Button,
    Eyebrow
  } = window.KitCommon.DS;
  const [covenants, setCov] = React.useState([0.54, 0.88, 0.4, 1]);

  // tweak config with safe defaults (kit runs standalone too)
  const cfg = {
    showEntities: true,
    showCallout: true,
    showStipple: true,
    showFrame: true,
    showBuild: true,
    showProgress: true,
    covenantLabels: true,
    clusterSize: 104,
    panelOpacity: 0.82,
    ...t
  };
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      overflow: 'hidden',
      color: 'var(--lumen)',
      fontFamily: 'var(--font-body)',
      background: VOID_BG,
      '--panel': `rgba(20,15,34,${cfg.panelOpacity})`
    }
  }, cfg.showStipple && /*#__PURE__*/React.createElement(Stipple, {
    opacity: 0.45,
    size: 15
  }), cfg.showFrame && /*#__PURE__*/React.createElement(PageFrame, {
    inset: 14,
    sealSize: 22
  }), cfg.showEntities && /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("img", {
    src: `${ASSET}/sprites/enemy-counterfeit.svg`,
    alt: "",
    style: {
      position: 'absolute',
      right: 330,
      top: 150,
      width: 104
    }
  }), /*#__PURE__*/React.createElement("img", {
    src: `${ASSET}/sprites/enemy-drifter.svg`,
    alt: "",
    style: {
      position: 'absolute',
      left: 380,
      top: 185,
      width: 74
    }
  }), /*#__PURE__*/React.createElement("img", {
    src: `${ASSET}/sprites/cache-reliquary.svg`,
    alt: "",
    style: {
      position: 'absolute',
      right: 380,
      bottom: 250,
      width: 84,
      cursor: 'pointer'
    },
    onClick: onResults,
    title: "Open reliquary \u2192 Results"
  }), /*#__PURE__*/React.createElement("img", {
    src: `${ASSET}/sprites/pickup-spark.svg`,
    alt: "",
    style: {
      position: 'absolute',
      left: 600,
      top: 250,
      width: 42
    }
  }), /*#__PURE__*/React.createElement("img", {
    src: `${ASSET}/sprites/pickup-spark.svg`,
    alt: "",
    style: {
      position: 'absolute',
      left: 720,
      top: 370,
      width: 38
    }
  }), /*#__PURE__*/React.createElement("img", {
    src: `${ASSET}/sprites/pickup-spark.svg`,
    alt: "",
    style: {
      position: 'absolute',
      left: 560,
      bottom: 300,
      width: 36
    }
  })), /*#__PURE__*/React.createElement("img", {
    src: `${ASSET}/sprites/gizmo-illuminated.svg`,
    alt: "Gizmo",
    style: {
      position: 'absolute',
      left: '50%',
      top: '52%',
      transform: 'translate(-50%,-50%)',
      width: 188
    }
  }), cfg.showCallout && /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: 556,
      top: 300,
      textAlign: 'center'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: '50%',
      top: 54,
      transform: 'translate(-50%,-50%)',
      width: 200,
      height: 200,
      borderRadius: '50%',
      background: 'radial-gradient(circle, rgba(232,188,136,.34), transparent 66%)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      fontFamily: 'var(--font-display)',
      fontWeight: 700,
      fontSize: 46,
      letterSpacing: 1,
      background: 'linear-gradient(180deg,#FFF6E2,#E8BC88)',
      WebkitBackgroundClip: 'text',
      backgroundClip: 'text',
      color: 'transparent',
      WebkitTextStroke: '2.5px #211B17',
      filter: 'drop-shadow(0 0 18px rgba(232,188,136,.6))'
    }
  }, "ILLUMINED!"), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      fontFamily: 'var(--font-display)',
      fontWeight: 700,
      fontSize: 30,
      color: 'var(--surge)',
      marginTop: -4,
      textShadow: '0 2px 0 rgba(33,27,23,.6)'
    }
  }, "+250")), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: 34,
      top: 34
    }
  }, /*#__PURE__*/React.createElement(Panel, {
    style: {
      display: 'flex',
      gap: 16,
      alignItems: 'center',
      padding: '12px 17px'
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(Eyebrow, null, "Illumination"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-display)',
      fontWeight: 700,
      fontSize: 31,
      color: 'var(--gold-leaf)',
      lineHeight: 1,
      textShadow: '0 0 16px rgba(232,188,136,.4)'
    }
  }, "42,180")), /*#__PURE__*/React.createElement(BreathRow, {
    total: 5,
    kept: 4
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      right: 34,
      top: 34
    }
  }, /*#__PURE__*/React.createElement(Panel, {
    style: {
      padding: 10
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: 'repeat(4,1fr)',
      gap: 8
    }
  }, /*#__PURE__*/React.createElement(StatCell, {
    label: "Rank",
    value: "VII",
    hue: "var(--flow)"
  }), /*#__PURE__*/React.createElement(StatCell, {
    label: "Power",
    value: "\xD73",
    hue: "var(--echo)"
  }), /*#__PURE__*/React.createElement(StatCell, {
    label: "Reliquary",
    value: "4",
    hue: "var(--surge)"
  }), /*#__PURE__*/React.createElement(StatCell, {
    label: "Vigil",
    value: "6:12"
  })))), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: '50%',
      top: 34,
      transform: 'translateX(-50%)',
      cursor: 'pointer'
    },
    onClick: onLevelUp,
    title: "Level up"
  }, /*#__PURE__*/React.createElement(VerdictBar, {
    title: "The Claiming",
    desc: "Chase the gold \u2014 seal the bounty",
    count: 3,
    total: 5,
    icon: /*#__PURE__*/React.createElement("img", {
      src: `${ASSET}/sprites/covenant-emblems.svg`,
      alt: "",
      style: {
        width: 34,
        height: 34,
        objectFit: 'none',
        objectPosition: '-512px -22px'
      }
    })
  })), cfg.showBuild && /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: 34,
      top: 122,
      width: 224
    }
  }, /*#__PURE__*/React.createElement(Panel, {
    eyebrow: "Covenant"
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'flex-start',
      gap: 7,
      whiteSpace: 'nowrap'
    }
  }, /*#__PURE__*/React.createElement(Pill, {
    dot: "var(--clutch)",
    count: 3
  }, "Pulse Driver"), /*#__PURE__*/React.createElement(Pill, {
    dot: "var(--flow)",
    count: 2
  }, "Spark Magnet"), /*#__PURE__*/React.createElement(Pill, {
    sealed: true,
    count: "\u2726"
  }, "Echo Coil"), /*#__PURE__*/React.createElement(Pill, {
    dot: "var(--echo)",
    count: 1
  }, "Nova Bloom")))), cfg.showProgress && /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: 34,
      bottom: 34,
      width: 372
    }
  }, /*#__PURE__*/React.createElement(Panel, null, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-manuscript)',
      fontWeight: 700,
      fontSize: 16,
      color: 'var(--gold-leaf)'
    }
  }, "Rank VII \xB7 Illuminating"), /*#__PURE__*/React.createElement(Eyebrow, null, "340 to wake")), /*#__PURE__*/React.createElement("div", {
    style: {
      height: 7,
      borderRadius: 99,
      background: 'rgba(232,188,136,.16)',
      overflow: 'hidden',
      marginTop: 9
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      height: '100%',
      width: '72%',
      borderRadius: 99,
      background: 'linear-gradient(90deg, var(--flow), var(--clutch), var(--surge))'
    }
  })))), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: '50%',
      bottom: 24,
      transform: 'translateX(-50%)',
      display: 'flex',
      gap: 26,
      alignItems: 'flex-end'
    }
  }, covenants.map((f, i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    style: {
      cursor: 'pointer'
    },
    onClick: () => setCov(c => c.map((v, j) => j === i ? Math.min(1, v + 0.15) : v))
  }, /*#__PURE__*/React.createElement(CovenantRoundel, {
    index: i,
    fill: f,
    size: cfg.clusterSize,
    showLabel: cfg.covenantLabels,
    src: `${ASSET}/sprites/covenant-emblems.svg`
  })))), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      right: 34,
      bottom: 34
    }
  }, /*#__PURE__*/React.createElement(Button, {
    variant: "surge",
    style: {
      width: 120,
      height: 92,
      flexDirection: 'column',
      gap: 2
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 20
    }
  }, "BOOST"), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-manuscript)',
      fontWeight: 700,
      fontSize: 12,
      letterSpacing: 2,
      textTransform: 'uppercase',
      opacity: 0.8
    }
  }, "Snap Seal"))));
}
window.HudScreen = HudScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/lumen-codex/HudScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/lumen-codex/LevelUpScreen.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/* Level-Up — the Illumination. Field dims; pick a covenant blessing. */
function LevelUpScreen({
  onPick,
  level = 8
}) {
  const {
    ASSET,
    VOID_BG,
    Stipple
  } = window.KitCommon;
  const {
    UpgradeCard,
    Button
  } = window.KitCommon.DS;
  const cards = [{
    rarity: 'rare',
    name: 'Pulse Driver',
    hotkey: '1',
    iconIndex: 2,
    desc: 'Your pulse fires a second beat on every shot.',
    statLabel: 'Fire Rate',
    statValue: '+18%'
  }, {
    rarity: 'epic',
    name: 'Nova Bloom',
    hotkey: '2',
    iconIndex: 5,
    desc: 'Level-up Novas leave a burning bloom that melts shapes.',
    statLabel: 'Blast Area',
    statValue: '+30%'
  }, {
    rarity: 'evolve',
    name: 'Echo Coil',
    hotkey: '3',
    iconIndex: 3,
    desc: 'Echo windows now chain into a Surge burst. Evolved.',
    statLabel: 'Evolved',
    statValue: 'MAX'
  }];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      overflow: 'hidden',
      color: 'var(--lumen)',
      fontFamily: 'var(--font-body)',
      background: VOID_BG
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      filter: 'blur(7px) brightness(.6)'
    }
  }, /*#__PURE__*/React.createElement("img", {
    src: `${ASSET}/sprites/enemy-drifter.svg`,
    alt: "",
    style: {
      position: 'absolute',
      left: 200,
      top: 160,
      width: 120
    }
  }), /*#__PURE__*/React.createElement("img", {
    src: `${ASSET}/sprites/enemy-bumper.svg`,
    alt: "",
    style: {
      position: 'absolute',
      right: 220,
      top: 200,
      width: 110
    }
  }), /*#__PURE__*/React.createElement("img", {
    src: `${ASSET}/sprites/pickup-spark.svg`,
    alt: "",
    style: {
      position: 'absolute',
      left: 380,
      bottom: 180,
      width: 70
    }
  }), /*#__PURE__*/React.createElement("img", {
    src: `${ASSET}/sprites/gizmo-illuminated.svg`,
    alt: "",
    style: {
      position: 'absolute',
      left: '50%',
      top: '54%',
      transform: 'translate(-50%,-50%)',
      width: 150
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      background: 'rgba(8,6,18,.66)',
      backdropFilter: 'blur(3px)'
    }
  }), /*#__PURE__*/React.createElement(Stipple, {
    opacity: 0.3,
    size: 15
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, /*#__PURE__*/React.createElement("img", {
    src: `${ASSET}/brand/emblem-illuminated.svg`,
    alt: "",
    style: {
      width: 74,
      height: 74,
      marginBottom: 6,
      filter: 'drop-shadow(0 0 26px rgba(255,210,74,.6))'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-display)',
      fontWeight: 700,
      fontSize: 52,
      letterSpacing: 1,
      lineHeight: 1,
      background: 'linear-gradient(180deg,#fff,var(--surge))',
      WebkitBackgroundClip: 'text',
      backgroundClip: 'text',
      color: 'transparent',
      filter: 'drop-shadow(0 0 30px rgba(255,210,74,.4))'
    }
  }, "ILLUMINATE"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-manuscript)',
      fontWeight: 700,
      fontSize: 17,
      letterSpacing: 2,
      textTransform: 'uppercase',
      color: 'var(--lumen-dim)',
      marginTop: 8
    }
  }, "Choose your blessing\xA0\xB7\xA0Rank ", level), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 18,
      marginTop: 26
    }
  }, cards.map(c => /*#__PURE__*/React.createElement("div", {
    key: c.name,
    onClick: () => onPick(c.name),
    style: {
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement(UpgradeCard, _extends({}, c, {
    iconSrc: `${ASSET}/sprites/icons.svg`
  }))))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 24
    }
  }, /*#__PURE__*/React.createElement(Button, {
    variant: "seal",
    iconLeft: /*#__PURE__*/React.createElement("span", null, "\u21BB")
  }, "Reroll Spark\xA0\xA0", /*#__PURE__*/React.createElement("b", {
    style: {
      color: 'var(--surge)'
    }
  }, "\xD72")))));
}
window.LevelUpScreen = LevelUpScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/lumen-codex/LevelUpScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/lumen-codex/ResultsScreen.jsx
try { (() => {
/* Results — the verdict. STORM CLEARED, the score sealed into the record. */
function ResultsScreen({
  onRunBack,
  onTitle
}) {
  const {
    ASSET,
    VOID_BG
  } = window.KitCommon;
  const {
    Button,
    StatCell,
    Eyebrow
  } = window.KitCommon.DS;
  const records = [{
    label: 'Best Rank',
    value: '14',
    hue: 'var(--flow)'
  }, {
    label: 'Top Flow',
    value: '×24',
    hue: 'var(--clutch)'
  }, {
    label: 'Reliquaries',
    value: '11',
    hue: 'var(--surge)'
  }, {
    label: 'Deepest',
    value: '8:40',
    hue: 'var(--echo)'
  }];
  const awards = [{
    label: 'Bounty Hunter',
    value: '×7',
    c: 'var(--coral)',
    bg: 'rgba(255,107,126,.16)'
  }, {
    label: 'Flow Master',
    value: '×24',
    c: 'var(--flow)',
    bg: 'rgba(91,230,164,.16)'
  }, {
    label: 'Clutch King',
    value: '×12',
    c: 'var(--clutch)',
    bg: 'rgba(84,216,255,.16)'
  }, {
    label: 'Cache Cracker',
    value: '×11',
    c: 'var(--surge)',
    bg: 'rgba(255,210,74,.16)'
  }];
  const rows = [['Sparks collected', '1,842'], ['Shapes cleared', '3,560'], ['Best Surge burst', '+4,800']];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      overflow: 'hidden',
      color: 'var(--lumen)',
      fontFamily: 'var(--font-body)',
      background: 'radial-gradient(120% 90% at 50% 14%, #1B1440, #120E28 50%, #0A0814)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      backgroundImage: 'radial-gradient(rgba(255,247,232,.05) 1.2px, transparent 1.2px)',
      backgroundSize: '40px 40px',
      opacity: 0.6
    }
  }), /*#__PURE__*/React.createElement("img", {
    src: `${ASSET}/sprites/gizmo.svg`,
    alt: "",
    style: {
      position: 'absolute',
      left: 'calc(50% + 250px)',
      top: 'calc(50% + 110px)',
      width: 120,
      transform: 'rotate(8deg)',
      filter: 'drop-shadow(0 14px 30px rgba(0,0,0,.5))'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: '50%',
      top: '50%',
      transform: 'translate(-50%,-50%)',
      width: 560,
      padding: '30px 34px 26px',
      borderRadius: 26,
      background: 'linear-gradient(180deg, rgba(32,26,60,.96), rgba(16,12,32,.98))',
      border: '2px solid rgba(255,247,232,.16)',
      boxShadow: '0 40px 90px rgba(0,0,0,.6)',
      textAlign: 'center'
    }
  }, /*#__PURE__*/React.createElement("img", {
    src: `${ASSET}/brand/emblem-illuminated.svg`,
    alt: "",
    style: {
      width: 60,
      height: 60,
      margin: '-58px auto 6px',
      display: 'block',
      filter: 'drop-shadow(0 0 24px rgba(255,210,74,.55))'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-display)',
      fontWeight: 700,
      fontSize: 40,
      letterSpacing: 1,
      lineHeight: 1,
      background: 'linear-gradient(180deg,#fff,var(--flow))',
      WebkitBackgroundClip: 'text',
      backgroundClip: 'text',
      color: 'transparent'
    }
  }, "STORM CLEARED"), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 14
    }
  }, /*#__PURE__*/React.createElement(Eyebrow, {
    color: "var(--lumen-dim)",
    size: 12
  }, "Final Illumination")), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-display)',
      fontWeight: 700,
      fontSize: 78,
      lineHeight: 1,
      marginTop: 8,
      color: 'var(--gold-leaf)',
      textShadow: '0 0 34px rgba(255,210,74,.45)'
    }
  }, "128,540"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'inline-block',
      marginTop: 10,
      padding: '5px 14px',
      borderRadius: 99,
      background: 'rgba(91,230,164,.16)',
      color: 'var(--flow)',
      fontWeight: 900,
      fontSize: 13,
      letterSpacing: .5,
      border: '1.5px solid rgba(91,230,164,.5)'
    }
  }, "\u2605 NEW BEST \u2014 +12,400"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: 'repeat(4,1fr)',
      gap: 8,
      margin: '20px 0 14px'
    }
  }, records.map(r => /*#__PURE__*/React.createElement(StatCell, {
    key: r.label,
    label: r.label,
    value: r.value,
    hue: r.hue,
    style: {
      background: 'rgba(255,247,232,.05)',
      textAlign: 'center'
    }
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: 'repeat(2,1fr)',
      gap: 8,
      marginBottom: 14
    }
  }, awards.map(a => /*#__PURE__*/React.createElement("div", {
    key: a.label,
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: '9px 13px',
      borderRadius: 11,
      fontWeight: 900,
      fontSize: 13,
      letterSpacing: .4,
      background: a.bg,
      color: a.c
    }
  }, /*#__PURE__*/React.createElement("span", null, a.label), /*#__PURE__*/React.createElement("b", {
    style: {
      fontFamily: 'var(--font-display)',
      fontWeight: 700,
      fontSize: 15
    }
  }, a.value)))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginBottom: 18,
      textAlign: 'left'
    }
  }, rows.map(([k, v]) => /*#__PURE__*/React.createElement("div", {
    key: k,
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      padding: '8px 2px',
      borderBottom: '1px solid rgba(255,247,232,.09)',
      fontWeight: 800,
      fontSize: 14,
      color: 'var(--lumen-dim)'
    }
  }, /*#__PURE__*/React.createElement("span", null, k), /*#__PURE__*/React.createElement("b", {
    style: {
      color: 'var(--lumen)',
      fontWeight: 900
    }
  }, v)))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 10
    }
  }, /*#__PURE__*/React.createElement(Button, {
    variant: "primary",
    full: true,
    onClick: onRunBack
  }, "RUN IT BACK"), /*#__PURE__*/React.createElement(Button, {
    variant: "alt",
    style: {
      flex: '0 0 150px'
    },
    onClick: onTitle
  }, "Title"))));
}
window.ResultsScreen = ResultsScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/lumen-codex/ResultsScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/lumen-codex/TitleScreen.jsx
try { (() => {
/* Title — "wake the page". The wordmark, emblem, hero, marginal covenants. */
function TitleScreen({
  onStart,
  best = '128,540',
  t = {}
}) {
  const {
    ASSET,
    VOID_BG,
    Stipple,
    PageFrame
  } = window.KitCommon;
  const {
    Eyebrow
  } = window.KitCommon.DS;
  const cfg = {
    showStipple: true,
    showFrame: true,
    showEntities: true,
    ...t
  };
  return /*#__PURE__*/React.createElement("div", {
    onClick: onStart,
    style: {
      position: 'absolute',
      inset: 0,
      cursor: 'pointer',
      overflow: 'hidden',
      color: 'var(--lumen)',
      fontFamily: 'var(--font-body)',
      background: `radial-gradient(120% 80% at 50% 36%, #241A44 0%, #150F2C 44%, #0B0914 82%), radial-gradient(50% 40% at 50% 40%, rgba(232,188,136,.10), transparent 70%)`
    }
  }, cfg.showStipple && /*#__PURE__*/React.createElement(Stipple, {
    opacity: 0.5,
    size: 13,
    mask: "radial-gradient(80% 70% at 50% 42%, #000 30%, transparent 78%)"
  }), cfg.showFrame && /*#__PURE__*/React.createElement(PageFrame, {
    inset: 26,
    sealSize: 30,
    ornate: true
  }), cfg.showEntities && /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("img", {
    src: `${ASSET}/sprites/covenant-emblems.svg`,
    alt: "",
    style: {
      position: 'absolute',
      left: 60,
      top: 230,
      width: 130,
      height: 130,
      objectFit: 'none',
      objectPosition: '-18px -16px',
      filter: 'drop-shadow(0 4px 12px rgba(0,0,0,.5))'
    }
  }), /*#__PURE__*/React.createElement("img", {
    src: `${ASSET}/sprites/covenant-emblems.svg`,
    alt: "",
    style: {
      position: 'absolute',
      right: 60,
      top: 230,
      width: 130,
      height: 130,
      objectFit: 'none',
      objectPosition: '-498px -16px',
      filter: 'drop-shadow(0 4px 12px rgba(0,0,0,.5))'
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      textAlign: 'center'
    }
  }, /*#__PURE__*/React.createElement("img", {
    src: `${ASSET}/brand/emblem-illuminated.svg`,
    alt: "Gizmo emblem",
    style: {
      marginTop: 52,
      width: 104,
      height: 104,
      filter: 'drop-shadow(0 6px 26px rgba(232,188,136,.4))'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 8,
      fontFamily: 'var(--font-display)',
      fontWeight: 700,
      fontSize: 124,
      lineHeight: 0.92,
      letterSpacing: -2,
      background: 'linear-gradient(180deg,#FFF6E2 6%,#F0CE92 40%,#E8BC88 62%,#A87A2E 100%)',
      WebkitBackgroundClip: 'text',
      backgroundClip: 'text',
      color: 'transparent',
      WebkitTextStroke: '3px #211B17',
      filter: 'drop-shadow(0 3px 0 rgba(33,27,23,.5)) drop-shadow(0 0 30px rgba(232,188,136,.35))'
    }
  }, "GIZMO"), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 2,
      fontFamily: 'var(--font-manuscript)',
      fontStyle: 'italic',
      fontWeight: 600,
      fontSize: 25,
      letterSpacing: 1.5,
      color: 'rgba(255,247,232,.82)'
    }
  }, "A spark re-illuminates the dark")), /*#__PURE__*/React.createElement("img", {
    src: `${ASSET}/sprites/gizmo-illuminated.svg`,
    alt: "Gizmo",
    style: {
      position: 'absolute',
      left: '50%',
      bottom: 60,
      transform: 'translateX(-50%)',
      width: 280,
      height: 305,
      filter: 'drop-shadow(0 16px 34px rgba(0,0,0,.55))'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      top: 48,
      left: 64,
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      padding: '10px 14px',
      borderRadius: 8,
      background: 'rgba(20,15,34,.8)',
      border: '1.5px solid var(--gold-tarnished)',
      boxShadow: 'inset 0 0 0 1px rgba(232,188,136,.3)'
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(Eyebrow, {
    color: "var(--lumen-dim)",
    size: 12
  }, "Best Illumination"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-display)',
      fontWeight: 700,
      fontSize: 22,
      color: 'var(--gold-leaf)'
    }
  }, best))), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: '50%',
      bottom: 40,
      transform: 'translateX(-50%)',
      display: 'flex',
      alignItems: 'center',
      gap: 14,
      padding: '12px 28px',
      borderRadius: 8,
      background: 'rgba(20,15,34,.82)',
      border: '2px solid var(--gold-tarnished)',
      boxShadow: 'inset 0 0 0 1px rgba(232,188,136,.4), 0 12px 30px rgba(0,0,0,.5)',
      fontFamily: 'var(--font-manuscript)',
      fontWeight: 700,
      fontSize: 20,
      letterSpacing: 4,
      color: 'var(--gold-leaf)',
      textTransform: 'uppercase'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 9,
      height: 9,
      background: 'var(--clutch)',
      borderRadius: '50%',
      boxShadow: '0 0 10px var(--clutch)',
      animation: 'kit-pulse 1.4s var(--ease-in-out) infinite'
    }
  }), "Press any key to wake the page"));
}
window.TitleScreen = TitleScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/lumen-codex/TitleScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/lumen-codex/app.jsx
try { (() => {
/* The Lumen Codex — interactive screen flow. Title → HUD → Level-Up → Results. */
const {
  useState,
  useEffect,
  useCallback
} = React;
const STAGE_W = 1280,
  STAGE_H = 720;
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
} /*EDITMODE-END*/;
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
const SCREENS = [{
  id: 'title',
  label: 'Title'
}, {
  id: 'hud',
  label: 'HUD'
}, {
  id: 'levelup',
  label: 'Level-Up'
}, {
  id: 'results',
  label: 'Results'
}];

// one-tap layout presets — batch-set the declutter tweaks (frame stays; it's identity)
const PRESETS = {
  full: {
    showEntities: true,
    showCallout: true,
    showStipple: true,
    showBuild: true,
    showProgress: true,
    covenantLabels: true,
    panelOpacity: 0.82,
    clusterSize: 104
  },
  calm: {
    showEntities: false,
    showCallout: false,
    showStipple: true,
    showBuild: true,
    showProgress: true,
    covenantLabels: false,
    panelOpacity: 0.70,
    clusterSize: 96
  },
  minimal: {
    showEntities: false,
    showCallout: false,
    showStipple: false,
    showBuild: false,
    showProgress: false,
    covenantLabels: false,
    panelOpacity: 0.58,
    clusterSize: 88
  }
};
function App() {
  const [screen, setScreen] = useState(() => localStorage.getItem('lumen-kit-screen') || 'title');
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const scale = useStageScale();
  const go = useCallback(s => {
    setScreen(s);
    localStorage.setItem('lumen-kit-screen', s);
  }, []);

  // "press any key" on title
  useEffect(() => {
    if (screen !== 'title') return;
    const onKey = () => go('hud');
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [screen, go]);
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'fixed',
      inset: 0,
      background: '#000',
      display: 'grid',
      placeItems: 'center',
      overflow: 'hidden'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: STAGE_W,
      height: STAGE_H,
      transform: `scale(${scale})`,
      transformOrigin: 'center center',
      position: 'relative',
      boxShadow: '0 30px 120px rgba(0,0,0,.6)'
    }
  }, screen === 'title' && /*#__PURE__*/React.createElement(TitleScreen, {
    onStart: () => go('hud'),
    t: t
  }), screen === 'hud' && /*#__PURE__*/React.createElement(HudScreen, {
    onLevelUp: () => go('levelup'),
    onResults: () => go('results'),
    t: t
  }), screen === 'levelup' && /*#__PURE__*/React.createElement(LevelUpScreen, {
    onPick: () => go('hud'),
    t: t
  }), screen === 'results' && /*#__PURE__*/React.createElement(ResultsScreen, {
    onRunBack: () => go('hud'),
    onTitle: () => go('title'),
    t: t
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'fixed',
      bottom: 14,
      left: '50%',
      transform: 'translateX(-50%)',
      display: 'flex',
      gap: 6,
      padding: 6,
      borderRadius: 99,
      background: 'rgba(20,15,34,.85)',
      border: '1px solid rgba(232,188,136,.3)',
      backdropFilter: 'blur(8px)',
      zIndex: 100
    }
  }, SCREENS.map(s => /*#__PURE__*/React.createElement("button", {
    key: s.id,
    onClick: () => go(s.id),
    style: {
      padding: '6px 14px',
      borderRadius: 99,
      border: 'none',
      cursor: 'pointer',
      fontFamily: 'var(--font-manuscript)',
      fontWeight: 700,
      fontSize: 12,
      letterSpacing: 1.5,
      textTransform: 'uppercase',
      background: screen === s.id ? 'var(--gold-leaf)' : 'transparent',
      color: screen === s.id ? 'var(--ink)' : 'var(--lumen-dim)',
      transition: 'all .15s ease'
    }
  }, s.label))), /*#__PURE__*/React.createElement(TweaksPanel, {
    title: "Tweaks"
  }, /*#__PURE__*/React.createElement(TweakSection, {
    label: "Quick layout"
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 8,
      width: '100%'
    }
  }, /*#__PURE__*/React.createElement(TweakButton, {
    label: "Full",
    secondary: true,
    onClick: () => setTweak(PRESETS.full)
  }), /*#__PURE__*/React.createElement(TweakButton, {
    label: "Calm",
    onClick: () => setTweak(PRESETS.calm)
  }), /*#__PURE__*/React.createElement(TweakButton, {
    label: "Minimal",
    secondary: true,
    onClick: () => setTweak(PRESETS.minimal)
  })), /*#__PURE__*/React.createElement(TweakSection, {
    label: "Field"
  }), /*#__PURE__*/React.createElement(TweakToggle, {
    label: "Field entities",
    value: t.showEntities,
    onChange: v => setTweak('showEntities', v)
  }), /*#__PURE__*/React.createElement(TweakToggle, {
    label: "Illumination callout",
    value: t.showCallout,
    onChange: v => setTweak('showCallout', v)
  }), /*#__PURE__*/React.createElement(TweakToggle, {
    label: "Stipple radiance",
    value: t.showStipple,
    onChange: v => setTweak('showStipple', v)
  }), /*#__PURE__*/React.createElement(TweakToggle, {
    label: "Page frame & seals",
    value: t.showFrame,
    onChange: v => setTweak('showFrame', v)
  }), /*#__PURE__*/React.createElement(TweakSection, {
    label: "HUD panels"
  }), /*#__PURE__*/React.createElement(TweakToggle, {
    label: "Covenant build list",
    value: t.showBuild,
    onChange: v => setTweak('showBuild', v)
  }), /*#__PURE__*/React.createElement(TweakToggle, {
    label: "Run progress bar",
    value: t.showProgress,
    onChange: v => setTweak('showProgress', v)
  }), /*#__PURE__*/React.createElement(TweakSlider, {
    label: "Panel opacity",
    value: t.panelOpacity,
    min: 0.4,
    max: 0.95,
    step: 0.01,
    onChange: v => setTweak('panelOpacity', v)
  }), /*#__PURE__*/React.createElement(TweakSection, {
    label: "Covenant cluster"
  }), /*#__PURE__*/React.createElement(TweakSlider, {
    label: "Roundel size",
    value: t.clusterSize,
    min: 68,
    max: 120,
    step: 2,
    unit: "px",
    onChange: v => setTweak('clusterSize', v)
  }), /*#__PURE__*/React.createElement(TweakToggle, {
    label: "Cluster labels",
    value: t.covenantLabels,
    onChange: v => setTweak('covenantLabels', v)
  })));
}
const __lumenRootEl = document.getElementById('root');
window.__lumenRoot = window.__lumenRoot || ReactDOM.createRoot(__lumenRootEl);
window.__lumenRoot.render(/*#__PURE__*/React.createElement(App, null));
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/lumen-codex/app.jsx", error: String((e && e.message) || e) }); }

// ui_kits/lumen-codex/kit-common.jsx
try { (() => {
/* Shared chrome for the Lumen Codex UI kit — the page apparatus. */
const ASSET = '../../assets';
const DS = window.GizmoTheLumenCodexDesignSystem_512f7f;
const VOID_BG = 'radial-gradient(120% 90% at 50% 20%, #1C1540 0%, #130E2A 48%, #0A0814 86%)';
function Stipple({
  opacity = 0.45,
  size = 15,
  mask = null
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      opacity,
      backgroundImage: 'radial-gradient(rgba(232,188,136,.14) 1px, transparent 1px)',
      backgroundSize: `${size}px ${size}px`,
      WebkitMask: mask,
      mask,
      pointerEvents: 'none'
    }
  });
}

/* The illuminated page frame + four corner wax-seals. */
function PageFrame({
  inset = 14,
  sealSize = 22,
  ornate = false
}) {
  const seals = [{
    left: inset - sealSize / 2,
    top: inset - sealSize / 2
  }, {
    right: inset - sealSize / 2,
    top: inset - sealSize / 2
  }, {
    left: inset - sealSize / 2,
    bottom: inset - sealSize / 2
  }, {
    right: inset - sealSize / 2,
    bottom: inset - sealSize / 2
  }];
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset,
      border: '2px solid var(--gold-tarnished)',
      borderRadius: 8,
      boxShadow: ornate ? 'inset 0 0 0 2px rgba(232,188,136,.5), inset 0 0 0 9px rgba(33,27,23,.6), inset 0 0 0 11px rgba(232,188,136,.25)' : 'inset 0 0 0 1px rgba(232,188,136,.4)',
      pointerEvents: 'none'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: ornate ? 7 : 4,
      border: '1px dashed rgba(232,188,136,.4)',
      borderRadius: 6
    }
  })), seals.map((p, i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    style: {
      position: 'absolute',
      width: sealSize,
      height: sealSize,
      transform: 'rotate(45deg)',
      background: 'var(--oxblood)',
      border: '2px solid var(--gold-leaf)',
      boxShadow: ornate ? '0 0 12px rgba(126,37,49,.6)' : 'none',
      ...p
    }
  })));
}

/* A gold-ground aureole behind a payoff (secular geometry, never a halo). */
function Aureole({
  size = 200,
  color = 'rgba(232,188,136,.34)'
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: '50%',
      top: '50%',
      transform: 'translate(-50%,-50%)',
      width: size,
      height: size,
      borderRadius: '50%',
      background: `radial-gradient(circle, ${color}, transparent 66%)`,
      pointerEvents: 'none'
    }
  });
}
window.KitCommon = {
  ASSET,
  DS,
  VOID_BG,
  Stipple,
  PageFrame,
  Aureole
};
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/lumen-codex/kit-common.jsx", error: String((e && e.message) || e) }); }

// ui_kits/lumen-codex/tweaks-panel.jsx
try { (() => {
// @ds-adherence-ignore -- omelette starter scaffold (raw elements/hex/px by design)

/* BEGIN USAGE */
// tweaks-panel.jsx
// Reusable Tweaks shell + form-control helpers.
// Exports (to window): useTweaks, TweaksPanel, TweakSection, TweakRow, TweakSlider,
//   TweakToggle, TweakRadio, TweakSelect, TweakText, TweakNumber, TweakColor, TweakButton.
//
// Owns the host protocol (listens for __activate_edit_mode / __deactivate_edit_mode,
// posts __edit_mode_available / __edit_mode_set_keys / __edit_mode_dismissed) so
// individual prototypes don't re-roll it. Ships a consistent set of controls so you
// don't hand-draw <input type="range">, segmented radios, steppers, etc.
//
// Usage (in an HTML file that loads React + Babel):
//
//   const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
//     "primaryColor": "#D97757",
//     "palette": ["#D97757", "#29261b", "#f6f4ef"],
//     "fontSize": 16,
//     "density": "regular",
//     "dark": false
//   }/*EDITMODE-END*/;
//
//   function App() {
//     const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
//     return (
//       <div style={{ fontSize: t.fontSize, color: t.primaryColor }}>
//         Hello
//         <TweaksPanel>
//           <TweakSection label="Typography" />
//           <TweakSlider label="Font size" value={t.fontSize} min={10} max={32} unit="px"
//                        onChange={(v) => setTweak('fontSize', v)} />
//           <TweakRadio  label="Density" value={t.density}
//                        options={['compact', 'regular', 'comfy']}
//                        onChange={(v) => setTweak('density', v)} />
//           <TweakSection label="Theme" />
//           <TweakColor  label="Primary" value={t.primaryColor}
//                        options={['#D97757', '#2A6FDB', '#1F8A5B', '#7A5AE0']}
//                        onChange={(v) => setTweak('primaryColor', v)} />
//           <TweakColor  label="Palette" value={t.palette}
//                        options={[['#D97757', '#29261b', '#f6f4ef'],
//                                  ['#475569', '#0f172a', '#f1f5f9']]}
//                        onChange={(v) => setTweak('palette', v)} />
//           <TweakToggle label="Dark mode" value={t.dark}
//                        onChange={(v) => setTweak('dark', v)} />
//         </TweaksPanel>
//       </div>
//     );
//   }
//
// TweakRadio is the segmented control for 2–3 short options (auto-falls-back to
// TweakSelect past ~16/~10 chars per label); reach for TweakSelect directly when
// options are many or long. For color tweaks always curate 3-4 options rather than
// a free picker; an option can also be a whole 2–5 color palette (the stored value
// is the array). The Tweak* controls are a floor, not a ceiling — build custom
// controls inside the panel if a tweak calls for UI they don't cover.
/* END USAGE */
// ─────────────────────────────────────────────────────────────────────────────

const __TWEAKS_STYLE = `
  .twk-panel{position:fixed;right:16px;bottom:16px;z-index:2147483646;width:280px;
    max-height:calc(100vh - 32px);display:flex;flex-direction:column;
    transform:scale(var(--dc-inv-zoom,1));transform-origin:bottom right;
    background:rgba(250,249,247,.78);color:#29261b;
    -webkit-backdrop-filter:blur(24px) saturate(160%);backdrop-filter:blur(24px) saturate(160%);
    border:.5px solid rgba(255,255,255,.6);border-radius:14px;
    box-shadow:0 1px 0 rgba(255,255,255,.5) inset,0 12px 40px rgba(0,0,0,.18);
    font:11.5px/1.4 ui-sans-serif,system-ui,-apple-system,sans-serif;overflow:hidden}
  .twk-hd{display:flex;align-items:center;justify-content:space-between;
    padding:10px 8px 10px 14px;cursor:move;user-select:none}
  .twk-hd b{font-size:12px;font-weight:600;letter-spacing:.01em}
  .twk-x{appearance:none;border:0;background:transparent;color:rgba(41,38,27,.55);
    width:22px;height:22px;border-radius:6px;cursor:default;font-size:13px;line-height:1}
  .twk-x:hover{background:rgba(0,0,0,.06);color:#29261b}
  .twk-body{padding:2px 14px 14px;display:flex;flex-direction:column;gap:10px;
    overflow-y:auto;overflow-x:hidden;min-height:0;
    scrollbar-width:thin;scrollbar-color:rgba(0,0,0,.15) transparent}
  .twk-body::-webkit-scrollbar{width:8px}
  .twk-body::-webkit-scrollbar-track{background:transparent;margin:2px}
  .twk-body::-webkit-scrollbar-thumb{background:rgba(0,0,0,.15);border-radius:4px;
    border:2px solid transparent;background-clip:content-box}
  .twk-body::-webkit-scrollbar-thumb:hover{background:rgba(0,0,0,.25);
    border:2px solid transparent;background-clip:content-box}
  .twk-row{display:flex;flex-direction:column;gap:5px}
  .twk-row-h{flex-direction:row;align-items:center;justify-content:space-between;gap:10px}
  .twk-lbl{display:flex;justify-content:space-between;align-items:baseline;
    color:rgba(41,38,27,.72)}
  .twk-lbl>span:first-child{font-weight:500}
  .twk-val{color:rgba(41,38,27,.5);font-variant-numeric:tabular-nums}

  .twk-sect{font-size:10px;font-weight:600;letter-spacing:.06em;text-transform:uppercase;
    color:rgba(41,38,27,.45);padding:10px 0 0}
  .twk-sect:first-child{padding-top:0}

  .twk-field{appearance:none;box-sizing:border-box;width:100%;min-width:0;height:26px;padding:0 8px;
    border:.5px solid rgba(0,0,0,.1);border-radius:7px;
    background:rgba(255,255,255,.6);color:inherit;font:inherit;outline:none}
  .twk-field:focus{border-color:rgba(0,0,0,.25);background:rgba(255,255,255,.85)}
  select.twk-field{padding-right:22px;
    background-image:url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='10' height='6' viewBox='0 0 10 6'><path fill='rgba(0,0,0,.5)' d='M0 0h10L5 6z'/></svg>");
    background-repeat:no-repeat;background-position:right 8px center}

  .twk-slider{appearance:none;-webkit-appearance:none;width:100%;height:4px;margin:6px 0;
    border-radius:999px;background:rgba(0,0,0,.12);outline:none}
  .twk-slider::-webkit-slider-thumb{-webkit-appearance:none;appearance:none;
    width:14px;height:14px;border-radius:50%;background:#fff;
    border:.5px solid rgba(0,0,0,.12);box-shadow:0 1px 3px rgba(0,0,0,.2);cursor:default}
  .twk-slider::-moz-range-thumb{width:14px;height:14px;border-radius:50%;
    background:#fff;border:.5px solid rgba(0,0,0,.12);box-shadow:0 1px 3px rgba(0,0,0,.2);cursor:default}

  .twk-seg{position:relative;display:flex;padding:2px;border-radius:8px;
    background:rgba(0,0,0,.06);user-select:none}
  .twk-seg-thumb{position:absolute;top:2px;bottom:2px;border-radius:6px;
    background:rgba(255,255,255,.9);box-shadow:0 1px 2px rgba(0,0,0,.12);
    transition:left .15s cubic-bezier(.3,.7,.4,1),width .15s}
  .twk-seg.dragging .twk-seg-thumb{transition:none}
  .twk-seg button{appearance:none;position:relative;z-index:1;flex:1;border:0;
    background:transparent;color:inherit;font:inherit;font-weight:500;min-height:22px;
    border-radius:6px;cursor:default;padding:4px 6px;line-height:1.2;
    overflow-wrap:anywhere}

  .twk-toggle{position:relative;width:32px;height:18px;border:0;border-radius:999px;
    background:rgba(0,0,0,.15);transition:background .15s;cursor:default;padding:0}
  .twk-toggle[data-on="1"]{background:#34c759}
  .twk-toggle i{position:absolute;top:2px;left:2px;width:14px;height:14px;border-radius:50%;
    background:#fff;box-shadow:0 1px 2px rgba(0,0,0,.25);transition:transform .15s}
  .twk-toggle[data-on="1"] i{transform:translateX(14px)}

  .twk-num{display:flex;align-items:center;box-sizing:border-box;min-width:0;height:26px;padding:0 0 0 8px;
    border:.5px solid rgba(0,0,0,.1);border-radius:7px;background:rgba(255,255,255,.6)}
  .twk-num-lbl{font-weight:500;color:rgba(41,38,27,.6);cursor:ew-resize;
    user-select:none;padding-right:8px}
  .twk-num input{flex:1;min-width:0;height:100%;border:0;background:transparent;
    font:inherit;font-variant-numeric:tabular-nums;text-align:right;padding:0 8px 0 0;
    outline:none;color:inherit;-moz-appearance:textfield}
  .twk-num input::-webkit-inner-spin-button,.twk-num input::-webkit-outer-spin-button{
    -webkit-appearance:none;margin:0}
  .twk-num-unit{padding-right:8px;color:rgba(41,38,27,.45)}

  .twk-btn{appearance:none;height:26px;padding:0 12px;border:0;border-radius:7px;
    background:rgba(0,0,0,.78);color:#fff;font:inherit;font-weight:500;cursor:default}
  .twk-btn:hover{background:rgba(0,0,0,.88)}
  .twk-btn.secondary{background:rgba(0,0,0,.06);color:inherit}
  .twk-btn.secondary:hover{background:rgba(0,0,0,.1)}

  .twk-swatch{appearance:none;-webkit-appearance:none;width:56px;height:22px;
    border:.5px solid rgba(0,0,0,.1);border-radius:6px;padding:0;cursor:default;
    background:transparent;flex-shrink:0}
  .twk-swatch::-webkit-color-swatch-wrapper{padding:0}
  .twk-swatch::-webkit-color-swatch{border:0;border-radius:5.5px}
  .twk-swatch::-moz-color-swatch{border:0;border-radius:5.5px}

  .twk-chips{display:flex;gap:6px}
  .twk-chip{position:relative;appearance:none;flex:1;min-width:0;height:46px;
    padding:0;border:0;border-radius:6px;overflow:hidden;cursor:default;
    box-shadow:0 0 0 .5px rgba(0,0,0,.12),0 1px 2px rgba(0,0,0,.06);
    transition:transform .12s cubic-bezier(.3,.7,.4,1),box-shadow .12s}
  .twk-chip:hover{transform:translateY(-1px);
    box-shadow:0 0 0 .5px rgba(0,0,0,.18),0 4px 10px rgba(0,0,0,.12)}
  .twk-chip[data-on="1"]{box-shadow:0 0 0 1.5px rgba(0,0,0,.85),
    0 2px 6px rgba(0,0,0,.15)}
  .twk-chip>span{position:absolute;top:0;bottom:0;right:0;width:34%;
    display:flex;flex-direction:column;box-shadow:-1px 0 0 rgba(0,0,0,.1)}
  .twk-chip>span>i{flex:1;box-shadow:0 -1px 0 rgba(0,0,0,.1)}
  .twk-chip>span>i:first-child{box-shadow:none}
  .twk-chip svg{position:absolute;top:6px;left:6px;width:13px;height:13px;
    filter:drop-shadow(0 1px 1px rgba(0,0,0,.3))}
`;

// ── useTweaks ───────────────────────────────────────────────────────────────
// Single source of truth for tweak values. setTweak persists via the host
// (__edit_mode_set_keys → host rewrites the EDITMODE block on disk).
function useTweaks(defaults) {
  const [values, setValues] = React.useState(defaults);
  // Accepts either setTweak('key', value) or setTweak({ key: value, ... }) so a
  // useState-style call doesn't write a "[object Object]" key into the persisted
  // JSON block.
  const setTweak = React.useCallback((keyOrEdits, val) => {
    const edits = typeof keyOrEdits === 'object' && keyOrEdits !== null ? keyOrEdits : {
      [keyOrEdits]: val
    };
    setValues(prev => ({
      ...prev,
      ...edits
    }));
    window.parent.postMessage({
      type: '__edit_mode_set_keys',
      edits
    }, '*');
    // Same-window signal so in-page listeners (deck-stage rail thumbnails)
    // can react — the parent message only reaches the host, not peers.
    window.dispatchEvent(new CustomEvent('tweakchange', {
      detail: edits
    }));
  }, []);
  return [values, setTweak];
}

// ── TweaksPanel ─────────────────────────────────────────────────────────────
// Floating shell. Registers the protocol listener BEFORE announcing
// availability — if the announce ran first, the host's activate could land
// before our handler exists and the toolbar toggle would silently no-op.
// The close button posts __edit_mode_dismissed so the host's toolbar toggle
// flips off in lockstep; the host echoes __deactivate_edit_mode back which
// is what actually hides the panel.
function TweaksPanel({
  title = 'Tweaks',
  children
}) {
  const [open, setOpen] = React.useState(false);
  const dragRef = React.useRef(null);
  const offsetRef = React.useRef({
    x: 16,
    y: 16
  });
  const PAD = 16;
  const clampToViewport = React.useCallback(() => {
    const panel = dragRef.current;
    if (!panel) return;
    const w = panel.offsetWidth,
      h = panel.offsetHeight;
    const maxRight = Math.max(PAD, window.innerWidth - w - PAD);
    const maxBottom = Math.max(PAD, window.innerHeight - h - PAD);
    offsetRef.current = {
      x: Math.min(maxRight, Math.max(PAD, offsetRef.current.x)),
      y: Math.min(maxBottom, Math.max(PAD, offsetRef.current.y))
    };
    panel.style.right = offsetRef.current.x + 'px';
    panel.style.bottom = offsetRef.current.y + 'px';
  }, []);
  React.useEffect(() => {
    if (!open) return;
    clampToViewport();
    if (typeof ResizeObserver === 'undefined') {
      window.addEventListener('resize', clampToViewport);
      return () => window.removeEventListener('resize', clampToViewport);
    }
    const ro = new ResizeObserver(clampToViewport);
    ro.observe(document.documentElement);
    return () => ro.disconnect();
  }, [open, clampToViewport]);
  React.useEffect(() => {
    const onMsg = e => {
      const t = e?.data?.type;
      if (t === '__activate_edit_mode') setOpen(true);else if (t === '__deactivate_edit_mode') setOpen(false);
    };
    window.addEventListener('message', onMsg);
    window.parent.postMessage({
      type: '__edit_mode_available'
    }, '*');
    return () => window.removeEventListener('message', onMsg);
  }, []);
  const dismiss = () => {
    setOpen(false);
    window.parent.postMessage({
      type: '__edit_mode_dismissed'
    }, '*');
  };
  const onDragStart = e => {
    const panel = dragRef.current;
    if (!panel) return;
    const r = panel.getBoundingClientRect();
    const sx = e.clientX,
      sy = e.clientY;
    const startRight = window.innerWidth - r.right;
    const startBottom = window.innerHeight - r.bottom;
    const move = ev => {
      offsetRef.current = {
        x: startRight - (ev.clientX - sx),
        y: startBottom - (ev.clientY - sy)
      };
      clampToViewport();
    };
    const up = () => {
      window.removeEventListener('mousemove', move);
      window.removeEventListener('mouseup', up);
    };
    window.addEventListener('mousemove', move);
    window.addEventListener('mouseup', up);
  };
  if (!open) return null;
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("style", null, __TWEAKS_STYLE), /*#__PURE__*/React.createElement("div", {
    ref: dragRef,
    className: "twk-panel",
    "data-omelette-chrome": "",
    style: {
      right: offsetRef.current.x,
      bottom: offsetRef.current.y
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "twk-hd",
    onMouseDown: onDragStart
  }, /*#__PURE__*/React.createElement("b", null, title), /*#__PURE__*/React.createElement("button", {
    className: "twk-x",
    "aria-label": "Close tweaks",
    onMouseDown: e => e.stopPropagation(),
    onClick: dismiss
  }, "\u2715")), /*#__PURE__*/React.createElement("div", {
    className: "twk-body"
  }, children)));
}

// ── Layout helpers ──────────────────────────────────────────────────────────

function TweakSection({
  label,
  children
}) {
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("div", {
    className: "twk-sect"
  }, label), children);
}
function TweakRow({
  label,
  value,
  children,
  inline = false
}) {
  return /*#__PURE__*/React.createElement("div", {
    className: inline ? 'twk-row twk-row-h' : 'twk-row'
  }, /*#__PURE__*/React.createElement("div", {
    className: "twk-lbl"
  }, /*#__PURE__*/React.createElement("span", null, label), value != null && /*#__PURE__*/React.createElement("span", {
    className: "twk-val"
  }, value)), children);
}

// ── Controls ────────────────────────────────────────────────────────────────

function TweakSlider({
  label,
  value,
  min = 0,
  max = 100,
  step = 1,
  unit = '',
  onChange
}) {
  return /*#__PURE__*/React.createElement(TweakRow, {
    label: label,
    value: `${value}${unit}`
  }, /*#__PURE__*/React.createElement("input", {
    type: "range",
    className: "twk-slider",
    min: min,
    max: max,
    step: step,
    value: value,
    onChange: e => onChange(Number(e.target.value))
  }));
}
function TweakToggle({
  label,
  value,
  onChange
}) {
  return /*#__PURE__*/React.createElement("div", {
    className: "twk-row twk-row-h"
  }, /*#__PURE__*/React.createElement("div", {
    className: "twk-lbl"
  }, /*#__PURE__*/React.createElement("span", null, label)), /*#__PURE__*/React.createElement("button", {
    type: "button",
    className: "twk-toggle",
    "data-on": value ? '1' : '0',
    role: "switch",
    "aria-checked": !!value,
    onClick: () => onChange(!value)
  }, /*#__PURE__*/React.createElement("i", null)));
}
function TweakRadio({
  label,
  value,
  options,
  onChange
}) {
  const trackRef = React.useRef(null);
  const [dragging, setDragging] = React.useState(false);
  // The active value is read by pointer-move handlers attached for the lifetime
  // of a drag — ref it so a stale closure doesn't fire onChange for every move.
  const valueRef = React.useRef(value);
  valueRef.current = value;

  // Segments wrap mid-word once per-segment width runs out. The track is
  // ~248px (280 panel − 28 body pad − 4 seg pad), each button loses 12px
  // to its own padding, and 11.5px system-ui averages ~6.3px/char — so 2
  // options fit ~16 chars each, 3 fit ~10. Past that (or >3 options), fall
  // back to a dropdown rather than wrap.
  const labelLen = o => String(typeof o === 'object' ? o.label : o).length;
  const maxLen = options.reduce((m, o) => Math.max(m, labelLen(o)), 0);
  const fitsAsSegments = maxLen <= ({
    2: 16,
    3: 10
  }[options.length] ?? 0);
  if (!fitsAsSegments) {
    // <select> emits strings — map back to the original option value so the
    // fallback stays type-preserving (numbers, booleans) like the segment path.
    const resolve = s => {
      const m = options.find(o => String(typeof o === 'object' ? o.value : o) === s);
      return m === undefined ? s : typeof m === 'object' ? m.value : m;
    };
    return /*#__PURE__*/React.createElement(TweakSelect, {
      label: label,
      value: value,
      options: options,
      onChange: s => onChange(resolve(s))
    });
  }
  const opts = options.map(o => typeof o === 'object' ? o : {
    value: o,
    label: o
  });
  const idx = Math.max(0, opts.findIndex(o => o.value === value));
  const n = opts.length;
  const segAt = clientX => {
    const r = trackRef.current.getBoundingClientRect();
    const inner = r.width - 4;
    const i = Math.floor((clientX - r.left - 2) / inner * n);
    return opts[Math.max(0, Math.min(n - 1, i))].value;
  };
  const onPointerDown = e => {
    setDragging(true);
    const v0 = segAt(e.clientX);
    if (v0 !== valueRef.current) onChange(v0);
    const move = ev => {
      if (!trackRef.current) return;
      const v = segAt(ev.clientX);
      if (v !== valueRef.current) onChange(v);
    };
    const up = () => {
      setDragging(false);
      window.removeEventListener('pointermove', move);
      window.removeEventListener('pointerup', up);
    };
    window.addEventListener('pointermove', move);
    window.addEventListener('pointerup', up);
  };
  return /*#__PURE__*/React.createElement(TweakRow, {
    label: label
  }, /*#__PURE__*/React.createElement("div", {
    ref: trackRef,
    role: "radiogroup",
    onPointerDown: onPointerDown,
    className: dragging ? 'twk-seg dragging' : 'twk-seg'
  }, /*#__PURE__*/React.createElement("div", {
    className: "twk-seg-thumb",
    style: {
      left: `calc(2px + ${idx} * (100% - 4px) / ${n})`,
      width: `calc((100% - 4px) / ${n})`
    }
  }), opts.map(o => /*#__PURE__*/React.createElement("button", {
    key: o.value,
    type: "button",
    role: "radio",
    "aria-checked": o.value === value
  }, o.label))));
}
function TweakSelect({
  label,
  value,
  options,
  onChange
}) {
  return /*#__PURE__*/React.createElement(TweakRow, {
    label: label
  }, /*#__PURE__*/React.createElement("select", {
    className: "twk-field",
    value: value,
    onChange: e => onChange(e.target.value)
  }, options.map(o => {
    const v = typeof o === 'object' ? o.value : o;
    const l = typeof o === 'object' ? o.label : o;
    return /*#__PURE__*/React.createElement("option", {
      key: v,
      value: v
    }, l);
  })));
}
function TweakText({
  label,
  value,
  placeholder,
  onChange
}) {
  return /*#__PURE__*/React.createElement(TweakRow, {
    label: label
  }, /*#__PURE__*/React.createElement("input", {
    className: "twk-field",
    type: "text",
    value: value,
    placeholder: placeholder,
    onChange: e => onChange(e.target.value)
  }));
}
function TweakNumber({
  label,
  value,
  min,
  max,
  step = 1,
  unit = '',
  onChange
}) {
  const clamp = n => {
    if (min != null && n < min) return min;
    if (max != null && n > max) return max;
    return n;
  };
  const startRef = React.useRef({
    x: 0,
    val: 0
  });
  const onScrubStart = e => {
    e.preventDefault();
    startRef.current = {
      x: e.clientX,
      val: value
    };
    const decimals = (String(step).split('.')[1] || '').length;
    const move = ev => {
      const dx = ev.clientX - startRef.current.x;
      const raw = startRef.current.val + dx * step;
      const snapped = Math.round(raw / step) * step;
      onChange(clamp(Number(snapped.toFixed(decimals))));
    };
    const up = () => {
      window.removeEventListener('pointermove', move);
      window.removeEventListener('pointerup', up);
    };
    window.addEventListener('pointermove', move);
    window.addEventListener('pointerup', up);
  };
  return /*#__PURE__*/React.createElement("div", {
    className: "twk-num"
  }, /*#__PURE__*/React.createElement("span", {
    className: "twk-num-lbl",
    onPointerDown: onScrubStart
  }, label), /*#__PURE__*/React.createElement("input", {
    type: "number",
    value: value,
    min: min,
    max: max,
    step: step,
    onChange: e => onChange(clamp(Number(e.target.value)))
  }), unit && /*#__PURE__*/React.createElement("span", {
    className: "twk-num-unit"
  }, unit));
}

// Relative-luminance contrast pick — checkmarks drawn over a swatch need to
// read on both #111 and #fafafa without per-option configuration. Hex input
// only (#rgb / #rrggbb); named or rgb()/hsl() colors fall through to "light".
function __twkIsLight(hex) {
  const h = String(hex).replace('#', '');
  const x = h.length === 3 ? h.replace(/./g, c => c + c) : h.padEnd(6, '0');
  const n = parseInt(x.slice(0, 6), 16);
  if (Number.isNaN(n)) return true;
  const r = n >> 16 & 255,
    g = n >> 8 & 255,
    b = n & 255;
  return r * 299 + g * 587 + b * 114 > 148000;
}
const __TwkCheck = ({
  light
}) => /*#__PURE__*/React.createElement("svg", {
  viewBox: "0 0 14 14",
  "aria-hidden": "true"
}, /*#__PURE__*/React.createElement("path", {
  d: "M3 7.2 5.8 10 11 4.2",
  fill: "none",
  strokeWidth: "2.2",
  strokeLinecap: "round",
  strokeLinejoin: "round",
  stroke: light ? 'rgba(0,0,0,.78)' : '#fff'
}));

// TweakColor — curated color/palette picker. Each option is either a single
// hex string or an array of 1-5 hex strings; the card adapts — a lone color
// renders solid, a palette renders colors[0] as the hero (left ~2/3) with the
// rest stacked in a sharp column on the right. onChange emits the
// option in the shape it was passed (string stays string, array stays array).
// Without options it falls back to the native color input for back-compat.
function TweakColor({
  label,
  value,
  options,
  onChange
}) {
  if (!options || !options.length) {
    return /*#__PURE__*/React.createElement("div", {
      className: "twk-row twk-row-h"
    }, /*#__PURE__*/React.createElement("div", {
      className: "twk-lbl"
    }, /*#__PURE__*/React.createElement("span", null, label)), /*#__PURE__*/React.createElement("input", {
      type: "color",
      className: "twk-swatch",
      value: value,
      onChange: e => onChange(e.target.value)
    }));
  }
  // Native <input type=color> emits lowercase hex per the HTML spec, so
  // compare case-insensitively. String() guards JSON.stringify(undefined),
  // which returns the primitive undefined (no .toLowerCase).
  const key = o => String(JSON.stringify(o)).toLowerCase();
  const cur = key(value);
  return /*#__PURE__*/React.createElement(TweakRow, {
    label: label
  }, /*#__PURE__*/React.createElement("div", {
    className: "twk-chips",
    role: "radiogroup"
  }, options.map((o, i) => {
    const colors = Array.isArray(o) ? o : [o];
    const [hero, ...rest] = colors;
    const sup = rest.slice(0, 4);
    const on = key(o) === cur;
    return /*#__PURE__*/React.createElement("button", {
      key: i,
      type: "button",
      className: "twk-chip",
      role: "radio",
      "aria-checked": on,
      "data-on": on ? '1' : '0',
      "aria-label": colors.join(', '),
      title: colors.join(' · '),
      style: {
        background: hero
      },
      onClick: () => onChange(o)
    }, sup.length > 0 && /*#__PURE__*/React.createElement("span", null, sup.map((c, j) => /*#__PURE__*/React.createElement("i", {
      key: j,
      style: {
        background: c
      }
    }))), on && /*#__PURE__*/React.createElement(__TwkCheck, {
      light: __twkIsLight(hero)
    }));
  })));
}
function TweakButton({
  label,
  onClick,
  secondary = false
}) {
  return /*#__PURE__*/React.createElement("button", {
    type: "button",
    className: secondary ? 'twk-btn secondary' : 'twk-btn',
    onClick: onClick
  }, label);
}
Object.assign(window, {
  useTweaks,
  TweaksPanel,
  TweakSection,
  TweakRow,
  TweakSlider,
  TweakToggle,
  TweakRadio,
  TweakSelect,
  TweakText,
  TweakNumber,
  TweakColor,
  TweakButton
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/lumen-codex/tweaks-panel.jsx", error: String((e && e.message) || e) }); }

__ds_ns.Button = __ds_scope.Button;

__ds_ns.Eyebrow = __ds_scope.Eyebrow;

__ds_ns.Keycap = __ds_scope.Keycap;

__ds_ns.Meter = __ds_scope.Meter;

__ds_ns.Panel = __ds_scope.Panel;

__ds_ns.Pill = __ds_scope.Pill;

__ds_ns.Seal = __ds_scope.Seal;

__ds_ns.BoostButton = __ds_scope.BoostButton;

__ds_ns.BreathRow = __ds_scope.BreathRow;

__ds_ns.CovenantRoundel = __ds_scope.CovenantRoundel;

__ds_ns.Joystick = __ds_scope.Joystick;

__ds_ns.StatCell = __ds_scope.StatCell;

__ds_ns.TouchControls = __ds_scope.TouchControls;

__ds_ns.UpgradeCard = __ds_scope.UpgradeCard;

__ds_ns.VerdictBar = __ds_scope.VerdictBar;

})();
