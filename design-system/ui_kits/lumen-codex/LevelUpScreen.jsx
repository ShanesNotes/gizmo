/* Level-Up — the Illumination. Field dims; pick a covenant blessing. */
function LevelUpScreen({ onPick, level = 8 }) {
  const { ASSET, VOID_BG, Stipple } = window.KitCommon;
  const { UpgradeCard, Button } = window.KitCommon.DS;

  const cards = [
    { rarity: 'rare', name: 'Pulse Driver', hotkey: '1', iconIndex: 2, desc: 'Your pulse fires a second beat on every shot.', statLabel: 'Fire Rate', statValue: '+18%' },
    { rarity: 'epic', name: 'Nova Bloom', hotkey: '2', iconIndex: 5, desc: 'Level-up Novas leave a burning bloom that melts shapes.', statLabel: 'Blast Area', statValue: '+30%' },
    { rarity: 'evolve', name: 'Echo Coil', hotkey: '3', iconIndex: 3, desc: 'Echo windows now chain into a Surge burst. Evolved.', statLabel: 'Evolved', statValue: 'MAX' },
  ];

  return (
    <div style={{ position: 'absolute', inset: 0, overflow: 'hidden', color: 'var(--lumen)', fontFamily: 'var(--font-body)', background: VOID_BG }}>
      {/* blurred field behind */}
      <div style={{ position: 'absolute', inset: 0, filter: 'blur(7px) brightness(.6)' }}>
        <img src={`${ASSET}/sprites/enemy-drifter.svg`} alt="" style={{ position: 'absolute', left: 200, top: 160, width: 120 }} />
        <img src={`${ASSET}/sprites/enemy-bumper.svg`} alt="" style={{ position: 'absolute', right: 220, top: 200, width: 110 }} />
        <img src={`${ASSET}/sprites/pickup-spark.svg`} alt="" style={{ position: 'absolute', left: 380, bottom: 180, width: 70 }} />
        <img src={`${ASSET}/sprites/gizmo-illuminated.svg`} alt="" style={{ position: 'absolute', left: '50%', top: '54%', transform: 'translate(-50%,-50%)', width: 150 }} />
      </div>
      <div style={{ position: 'absolute', inset: 0, background: 'rgba(8,6,18,.66)', backdropFilter: 'blur(3px)' }} />
      <Stipple opacity={0.3} size={15} />

      <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
        <img src={`${ASSET}/brand/emblem-illuminated.svg`} alt="" style={{ width: 74, height: 74, marginBottom: 6, filter: 'drop-shadow(0 0 26px rgba(255,210,74,.6))' }} />
        <div style={{ fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 52, letterSpacing: 1, lineHeight: 1, background: 'linear-gradient(180deg,#fff,var(--surge))', WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent', filter: 'drop-shadow(0 0 30px rgba(255,210,74,.4))' }}>ILLUMINATE</div>
        <div style={{ fontFamily: 'var(--font-manuscript)', fontWeight: 700, fontSize: 17, letterSpacing: 2, textTransform: 'uppercase', color: 'var(--lumen-dim)', marginTop: 8 }}>
          Choose your blessing&nbsp;·&nbsp;Rank {level}
        </div>

        <div style={{ display: 'flex', gap: 18, marginTop: 26 }}>
          {cards.map((c) => (
            <div key={c.name} onClick={() => onPick(c.name)} style={{ cursor: 'pointer' }}>
              <UpgradeCard {...c} iconSrc={`${ASSET}/sprites/icons.svg`} />
            </div>
          ))}
        </div>

        <div style={{ marginTop: 24 }}>
          <Button variant="seal" iconLeft={<span>↻</span>}>Reroll Spark&nbsp;&nbsp;<b style={{ color: 'var(--surge)' }}>×2</b></Button>
        </div>
      </div>
    </div>
  );
}
window.LevelUpScreen = LevelUpScreen;
