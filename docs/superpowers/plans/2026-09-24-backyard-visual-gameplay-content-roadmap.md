# Backyard Mayhem — Visual, Gameplay & Content Roadmap

Date: 2026-09-24
Branch: `dev/backyard-vertical-slice`
Canonical full project: Google Drive `Backyard Mayhem/LATEST/BackyardMayhem_LATEST.zip`

## Development rule

Every major phase ends with:
1. tests and parser gate,
2. visual QA / screenshot where applicable,
3. a Git checkpoint with exact commit SHA,
4. a full-project candidate ZIP,
5. only after GREEN: archive previous Drive LATEST to CHECKPOINTS and replace LATEST.

Character animation remains authored SpriteFrames. Combat VFX remain separate scene/particle/AnimationPlayer nodes and are not baked into character sprites.

## Phase A — Finish the visual foundation

### A1. Hero authored RUN — current priority
- Fix resilient 8-direction RUN extraction from `hero_new_8dir_movement_sheet.png`.
- Require 8 directions × 8 unique authored frames.
- Remove RUN labels, white matte, neighboring-row fragments and antialias residue.
- Preserve 320×320 canvas, stable ground anchor and safe margins.
- Produce an 8×8 contact sheet and inspect it before runtime replacement.
- Run full-project Godot 4.7.2 hero + five-wave regression before Drive update.

### A2. Remaining hero actions
- Rebuild/normalize fire, build, hurt, dash and death with the same identity, scale and anchor.
- Add authored anticipation/recovery where current sheets support it.
- Remove current legacy edge-touching fire frames.

### A3. Combat VFX pass
- Frame-synced muzzle / air blast / recoil.
- Dash streaks with directional taper.
- Hurt flash + impact particles.
- Enemy hit flash, knockback dust, death poof/debris.
- Boss windup pulses, ground telegraphs and impact rings.
- Keep VFX in dedicated nodes; use SpriteFrames/AnimationPlayer/GPUParticles2D as appropriate.

### A4. Water VFX production set
- Hose stream loop.
- Water projectile.
- Splash impact.
- Foam / droplets.
- Sprinkler arcs.
- Puddle / wet-state readability.
- Transparent runtime assets only; no turret or labels baked into VFX.

### A5. Enemy sprite normalization
Order: Raccoon → Cat → Bulldog → Pigeon → Neighbor Kid → Skater → Boss.
For every enemy:
- clean transparent frames,
- stable anchor/scale,
- readable silhouettes,
- attack anticipation,
- hit/death states,
- runtime asset policy + visual validator + SpriteFrames validator.

### A6. Backyard environment polish
- Bring the playable yard closer to Reference A.
- Improve house/shed/fence/foliage cohesion.
- Add contact shadows and consistent ground depth.
- Improve path/lawn material contrast.
- Add selective props that support gameplay readability.
- Add damaged/destruction states for the defended base and nearby props.

## Phase B — Combat and tower-defense depth

### B1. Weapon feel
- Leaf-blower cone: push, stagger and crowd control readability.
- Water weapon: wet/slow state and stronger impact feedback.
- Slipper secondary: clear projectile arc and hit identity.
- Tune hit-stop/camera shake conservatively so large waves remain readable.

### B2. Defense synergies
- Wet enemy + Electric Fence = bonus chain/stun interaction.
- Sprinkler creates control zones instead of only raw damage.
- Chair barricade creates funnels and breaks visibly by damage state.
- Garden Hose prioritizes useful targets and communicates range clearly.
- Central base upgrades add visible turret sockets and defense modules.

### B3. Enemy combat roles
- Raccoon: baseline swarm/thief pressure.
- Cat: fast flanker/burst.
- Bulldog: heavy charger/tank.
- Pigeon: aerial bomber that ignores barricade lanes.
- Neighbor Kid: ranged pressure.
- Skater: fast lane breaker.
- Boss: multi-pattern telegraphed threat.

### B4. Five-wave pacing
- Wave 1: fundamentals.
- Wave 2: speed/flanking.
- Wave 3: heavy + air.
- Wave 4: ranged + mixed pressure.
- Wave 5: mixed elite pressure + boss.
- Between waves: meaningful Hero / Base / Utility choice.
- Validate economy so each reward enables at least one interesting decision.

### B5. Boss expansion
- Phase 1: heavy swing / readable radial slam.
- Phase 2: arena pressure + adds.
- Enrage/last-stand pattern only after visual telegraphs are reliable.
- Distinct warning language, radius and camera response per move.

## Phase C — New content after the visual foundation is stable

### C1. New enemies — proposed
- **Squirrel Thief**: steals dropped coins/resources and tries to escape.
- **Mole**: tunnels under the frontline and surfaces near the central base; clear ground telegraph before surfacing.
- **Wasp/Hornet Swarm**: fragile air harassment that forces anti-air attention.
- **Possum Trickster**: briefly fakes death, then re-enters unless finished/controlled.

Implement one at a time, each with a unique gameplay role; do not inflate enemy count before readability/performance remains green.

### C2. New defenses — proposed
- **Rake Trap**: short stun/trip lane control.
- **Garden Gnome Decoy**: taunt/redirect aggro, finite durability.
- **Compost Sludge**: slow zone / wet-style synergy.
- **Patio Fan**: directional push field that synergizes with blower knockback and funnels.

### C3. New hero perks — proposed
- Pressure Tank: stronger push / slower recharge tradeoff.
- Turbo Nozzle: narrower but stronger cone.
- Slipper Ricochet: controlled bounce upgrade.
- Panic Repair: short emergency base heal with cooldown.
- Wet Combo: bonus control/damage on soaked targets.

### C4. Backyard event modifiers — proposed
- Rain: water stronger; electric effects more dangerous/valuable.
- Night Shift: reduced ambient visibility, stronger warning lights/telegraphs.
- BBQ Smoke: temporary sight/aim disruption zones.
- Gusty Wind: affects lightweight projectiles/air units and visually animates foliage.

## Phase D — Presentation, audio and performance

### D1. HUD/shop polish
- Keep combat center clear.
- Strong hierarchy: critical health > boss warning > wave state > upgrade hints.
- Better between-wave cards with cost, category, effect and current tier.
- Add compact enemy/boss status only when it improves decisions.

### D2. Audio
- Unique weapon attack layers.
- Water impacts and sprinkler loop.
- Enemy hit/death identities.
- Boss windup/impact stingers.
- Wave-start/end stingers and escalating music layers.

### D3. Performance
- Pool frequent projectiles/VFX where profiling shows allocation pressure.
- Cap/degrade secondary particles at very high enemy counts.
- Test 100+ enemies + active defenses + water VFX.
- Maintain gameplay readability before increasing raw particle density.

### D4. Vertical-slice acceptance
- Full five-wave run.
- Hero/build/water/boss regression.
- Performance capture.
- Wave 1 / damaged base / boss screenshots.
- Package full candidate ZIP, SHA-256, checkpoint Drive copy, then update LATEST.

## Content scope recommendation

Keep the current vertical slice at 5 waves until visuals, combat feel and performance are production-stable. Add new enemies/defenses incrementally after Phase A/B rather than expanding to 8–10 waves immediately. A polished 15–20 minute five-wave run is the target before broader content expansion.
