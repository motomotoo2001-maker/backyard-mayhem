# Backyard Mayhem Next Development Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the current Backyard Mayhem vertical slice into a visually coherent, technically stable, replayable isometric roguelike/tower-defense build with production-ready hero/enemy animation, stronger combat VFX, clearer defense progression, and repeatable regression testing.

**Architecture:** Keep Godot 4.7.2 stable as the canonical runtime. Use the Library `BackyardMayhem_LATEST.zip` as the authoritative full gameplay snapshot and `dev/backyard-vertical-slice` as the active integration/QA branch. Art is normalized into runtime-only folders; source sheets remain references and may never be referenced directly by runtime scenes.

**Tech Stack:** Godot 4.7.2 stable, GDScript 2.0, SpriteFrames/AnimatedSprite2D, CharacterBody2D, GitHub Actions, Python/PIL art preprocessing where needed.

**Spec:** `CHECKPOINT.md`

## Global Constraints

- Canonical engine: Godot 4.7.2 stable.
- Godot 4.8-dev6 is compatibility-only until a later migration milestone.
- Runtime hero frames remain 320x320 PNG with fixed ground anchor and safe margins.
- Runtime scenes must never reference raw concept/reference/user_pack sheets directly.
- Every gameplay or animation change requires a focused regression test before integration.
- Every completed milestone updates `CHECKPOINT.md` and creates a Git commit.
- `main` only receives tested milestone builds.

## Review Focus

1. Source sheets with white matte, labels, grids, speech bubbles, or baked VFX must not leak into runtime art.
2. Hero/enemy frame anchors and scale must not drift between animation frames.
3. VFX must trigger on the actual animation contact frame rather than by unrelated timers.
4. One-shot actions must not be interrupted by idle/run unless a higher-priority state such as hurt/death takes over.
5. Full-game CI must test the real gameplay tree, not only the QA/bootstrap slice.

---

### Task 1: Synchronize the Full Gameplay Tree into GitHub

**Files:**
- Replace/sync: `project.godot`
- Sync: `scripts/`
- Sync: `scenes/`
- Sync: `tests/`
- Sync: `tools/`
- Sync: `data/`
- Preserve: `scripts/art/hero_*`
- Preserve: `.github/workflows/godot-tests.yml`

**Interfaces:**
- Consumes: canonical Library snapshot `BackyardMayhem_LATEST.zip`.
- Produces: GitHub dev branch containing the real gameplay text tree used by CI.

- [ ] Extract the canonical ZIP into an isolated worktree and verify `project.godot` exists.
- [ ] Compare `project.godot`, `scripts/`, `scenes/`, `tests/`, `tools/`, and `data/` against `dev/backyard-vertical-slice`.
- [ ] Copy only project source/text resources; exclude `.godot/`, `backups/`, temp captures, and `*.gd.uid`.
- [ ] Run `Godot_v4.7.2-stable_linux.x86_64 --headless --path . --editor --quit`.
- [ ] Run `Godot_v4.7.2-stable_linux.x86_64 --headless --path . --script res://tests/run_all.gd`.
- [ ] Require zero parse/script errors and a zero test exit status.
- [ ] Commit: `chore: synchronize full gameplay snapshot`.

### Task 2: Finish Hero Production Animation Replacement

**Files:**
- Modify: `tools/art/build_new_reference_hero.py`
- Modify: `scenes/player/player.tscn`
- Modify: `scripts/player/player.gd`
- Runtime output: `assets/runtime/characters/builder_hero/*.png`
- Test: `tests/test_hero_safe_margins.gd`
- Test: `tests/test_new_hero_reference_contract.gd`
- Test: `tests/test_new_hero_muzzle_alignment.gd`
- Test: `tests/test_hero_spriteframes_validator.gd`

**Interfaces:**
- Consumes: clean 8-direction hero reference, `HeroAnimationProfile`, direction/state resolvers.
- Produces: 56 complete SpriteFrames animations / 280 normalized runtime frames.

- [ ] Write/extend tests that reject missing frames, white-fringe contamination, detached alpha islands, wrong FPS/loop flags, and anchor drift.
- [ ] Generate one full strip per action+direction from an approved seed rather than generating individual frames.
- [ ] Normalize every strip to 320x320 with one shared scale and bottom-center anchor.
- [ ] Lock first frame to the approved seed when the action begins from idle.
- [ ] Replace `idle/run/fire/build/hurt/dash/death` for all eight directions.
- [ ] Rebuild SpriteFrames in `player.tscn` using only `assets/runtime/characters/builder_hero/`.
- [ ] Run all hero validators plus direct `player.tscn` load.
- [ ] Capture a live contact-sheet and an in-engine combat screenshot.
- [ ] Commit: `art: replace hero animations with normalized production frames`.

### Task 3: Synchronize Combat Animation and VFX Events

**Files:**
- Create/modify: `scripts/art/combat_vfx_timing_profile.gd`
- Modify: `scripts/player/player.gd`
- Modify: `scenes/player/player.tscn`
- Test: `tests/test_combat_vfx_timing_profile.gd`

**Interfaces:**
- Consumes: hero animation FPS/frame counts from `HeroAnimationProfile`.
- Produces: deterministic frame-based events for muzzle, recoil, air blast, dash trail, hurt impact, and recovery.

- [ ] Keep fire contact on frame 1 at 14 FPS and dash trail peak on frame 1 at 18 FPS.
- [ ] Replace timer-only muzzle/recoil triggers with frame/event triggers.
- [ ] Fire sequence: muzzle + recoil + air blast on contact frame; recovery on final fire frame.
- [ ] Dash sequence: trail starts frame 0, peaks frame 1, ends frame 3.
- [ ] Hurt sequence: impact flash frame 0; recovery frame 2.
- [ ] Add tests for invalid actions/events returning `-1` rather than firing arbitrary VFX.
- [ ] Commit: `feat: synchronize combat VFX with animation contact frames`.

### Task 4: Upgrade Weapon Feedback and Hit Readability

**Files:**
- Modify: `scenes/player/player.tscn`
- Modify: `scripts/player/player.gd`
- Modify: projectile/hit scripts under `scripts/projectiles/` and/or `scripts/combat/` after Task 1 sync.
- Runtime VFX: `assets/runtime/vfx/`
- Test: add focused combat feedback tests under `tests/`.

**Interfaces:**
- Consumes: frame-timed events from Task 3.
- Produces: recoil impulse, muzzle air cone, projectile trail, hit flash, knockback/dust response.

- [ ] Separate character sprite from VFX layers; do not bake muzzle/impact FX into hero frames.
- [ ] Add short recoil displacement and return easing without moving collision geometry.
- [ ] Add a readable air-blast cone with short lifetime and tapered opacity.
- [ ] Add impact star/dust/water reactions selected by attack type.
- [ ] Add enemy hit flash and a short directional recoil without breaking AI navigation.
- [ ] Verify muzzle origin for all eight directions.
- [ ] Commit: `vfx: improve weapon recoil muzzle and hit feedback`.

### Task 5: Normalize Enemy Animation Assets

**Files:**
- Runtime output: `assets/runtime/enemies/raccoon/`, `cat/`, `bulldog/`, `pigeon/`, `neighbor_kid/`, `skateboard_teen/`, `boss/`
- Modify enemy SpriteFrames scenes under `scenes/enemies/` after Task 1 sync.
- Add: `scripts/art/enemy_frame_validator.gd`
- Add: `tests/test_enemy_frame_validator.gd`

**Interfaces:**
- Consumes: existing concept sheets as visual references only.
- Produces: transparent, anchor-stable runtime enemy frames with no labels/backgrounds/baked speech bubbles.

- [ ] Reject concept sheets that include labels, white matte, grids, UI, speech balloons, or multiple unrelated poses inside one runtime texture.
- [ ] Normalize common ground anchors and consistent scale per enemy type.
- [ ] Prioritize Raccoon, Cat, Bulldog, Pigeon, Neighbor Kid, then Skateboard Teen/Boss.
- [ ] Separate dust/speed lines/splash from enemy body sprites into VFX nodes.
- [ ] Add readable death/defeat pose for each archetype.
- [ ] Commit each enemy family separately to keep visual regressions easy to bisect.

### Task 6: Production Water/Hose VFX

**Files:**
- Runtime VFX: `assets/runtime/vfx/water/`
- Modify: Garden Hose and Rotary Sprinkler scenes/scripts.
- Test: water VFX timing/range regression under `tests/`.

**Interfaces:**
- Consumes: current water sheets as style references only.
- Produces: clean stream/splash/projectile strips with consistent nozzle origin.

- [ ] Create an 8-frame continuous water-stream strip with fixed left-side nozzle origin and transparent background.
- [ ] Create separate splash/impact strip; do not bake the turret into the effect frames.
- [ ] Create a separate droplet/projectile sequence for Neighbor Kid / water weapons.
- [ ] Bind effect lifetime and damage frame to animation frames.
- [ ] Verify impact position matches collision location and does not float above enemies.
- [ ] Commit: `art: replace water concept sheets with production VFX strips`.

### Task 7: Defense Visual Upgrade and Upgrade Progression

**Files:**
- Modify: Chair / Hose / Rotary defense scenes and scripts.
- Modify: `scenes/levels/backyard.tscn`
- Modify: `scenes/ui/hud.tscn`
- Add/update defense regression tests.

**Interfaces:**
- Consumes: existing Chair/Hose/Rotary, Electric Fence, Golden Slipper, Super Soaker systems.
- Produces: visually distinct upgrade tiers and clearer damage/repair states.

- [ ] Keep the defended central building as the progression anchor.
- [ ] Make post-wave upgrades visibly alter the building/defense setup instead of only changing stats.
- [ ] Give fresh/damaged/critical states distinct silhouettes, not only tint changes.
- [ ] Add construction/deploy burst VFX and repair feedback.
- [ ] Add range preview that is visible but subordinate to combat readability.
- [ ] Commit: `feat: improve defense progression and visual states`.

### Task 8: Enemy Combat Readability and Telegraphs

**Files:**
- Modify enemy AI scripts and scenes after Task 1 sync.
- Modify boss warning/camera feedback systems.
- Add regression tests for attack telegraphs.

**Interfaces:**
- Consumes: normalized enemy animations from Task 5.
- Produces: readable anticipation/attack/recovery windows for melee, burst, ranged, bomber, and boss attacks.

- [ ] Add short anticipation frames before Cat/Bulldog/Skater burst attacks.
- [ ] Pigeon bombing must visibly separate flight, drop, projectile fall, and splat.
- [ ] Neighbor Kid water shot must originate at the pistol muzzle and visibly travel before damage.
- [ ] Boss heavy swing/radial slam telegraphs must remain readable under particle load.
- [ ] Add hit/death feedback without freezing the whole game excessively.
- [ ] Commit: `feat: improve enemy telegraphs and combat readability`.

### Task 9: Backyard Environment and Lighting Pass

**Files:**
- Modify: `scenes/levels/backyard.tscn`
- Runtime art: `assets/runtime/environment/`
- Modify camera/environment helper scripts as needed.

**Interfaces:**
- Consumes: Reference A backyard art direction.
- Produces: clearer combat lanes, stronger depth separation, coherent environment palette.

- [ ] Separate playable lane from decorative background through value/contrast rather than hard UI outlines.
- [ ] Unify bushes, fences, props, house, ground, and debris into one illustration style.
- [ ] Keep enemy silhouettes readable against grass/soil at night/dusk.
- [ ] Add restrained contact shadows and ambient occlusion-like grounding under characters/defenses.
- [ ] Reduce decorative clutter near projectile paths and build locations.
- [ ] Capture before/after screenshots at identical camera position.
- [ ] Commit: `art: polish backyard environment and combat readability`.

### Task 10: Wave, Economy, and Upgrade Balance

**Files:**
- Modify wave director/data files after Task 1 sync.
- Modify upgrade/economy data.
- Test: five-wave acceptance/performance tests.

**Interfaces:**
- Consumes: current five-wave playable loop.
- Produces: escalating pressure with meaningful weapon/building upgrade choices.

- [ ] Wave 1 teaches movement/primary weapon.
- [ ] Wave 2 introduces build/repair pressure.
- [ ] Wave 3 introduces mixed burst/ranged threats.
- [ ] Wave 4 combines flyer + pressure archetypes.
- [ ] Wave 5 culminates in boss + adds without turning into unavoidable damage.
- [ ] Tune money so at least one meaningful upgrade is affordable after each successful wave.
- [ ] Ensure weapon upgrades and building upgrades compete for the same economy deliberately.
- [ ] Run five-wave acceptance and 100-enemy performance test.
- [ ] Commit: `balance: tune waves economy and upgrade pacing`.

### Task 11: HUD and Player Feedback Pass

**Files:**
- Modify: `scenes/ui/hud.tscn`
- Modify HUD controller scripts.
- Update visual regression tests.

**Interfaces:**
- Consumes: combat/build/upgrade states.
- Produces: compact HUD with legible HP, wave, currency, dash, weapon/upgrade state, and boss warnings.

- [ ] Remove redundant labels and keep combat-important information in the primary visual hierarchy.
- [ ] Preserve Dash cooldown readability and boss warning legibility.
- [ ] Add concise post-wave upgrade summary.
- [ ] Ensure UI never covers active combat/build locations at target resolution.
- [ ] Commit: `ui: improve combat and upgrade readability`.

### Task 12: Performance, Regression, and Release Checkpoint

**Files:**
- Modify: `.github/workflows/godot-tests.yml`
- Modify/add full-game smoke/performance tests.
- Update: `CHECKPOINT.md`
- Update: `LATEST_SNAPSHOT.md`

**Interfaces:**
- Consumes: all previous milestones.
- Produces: reproducible tested checkpoint ready for `main`.

- [ ] Run editor parse gate on Godot 4.7.2 stable.
- [ ] Run complete test suite with no hidden `SCRIPT ERROR` / `Parse Error`.
- [ ] Run five-wave unattended acceptance test.
- [ ] Run hero/enemy animation validators over real runtime assets.
- [ ] Run 100-enemy + defenses performance test and record average/p95 frame time.
- [ ] Run optional Godot 4.8-dev6 compatibility smoke test; failures here do not block stable release unless they expose project-format corruption.
- [ ] Capture final gameplay screenshots for hero combat, defense upgrade, enemy swarm, boss telegraph, and upgrade UI.
- [ ] Update `CHECKPOINT.md` with exact commit, test results, known issues, and next milestone.
- [ ] Create new full `BackyardMayhem_LATEST.zip` and update `LATEST_SNAPSHOT.md` SHA-256.
- [ ] Promote tested milestone to `main`.
- [ ] Commit/tag: `checkpoint-visual-combat-v2`.

## Execution Order

The required order is: **1 → 2 → 3 → 4 → 5/6 → 7/8 → 9 → 10 → 11 → 12**. Tasks 5 and 6 can run independently after Task 4. Tasks 7 and 8 can run independently after their required art assets are normalized.

## Definition of Done for the Next Major Milestone

- Full gameplay tree is synchronized to GitHub and is what CI actually tests.
- Hero has complete clean 8-direction production animation set.
- Combat VFX are frame-synchronized and not baked into body sprites.
- Core enemy roster uses normalized runtime sprites without labels/white matte/artifacts.
- Water/impact/dash VFX are visually coherent and correctly anchored.
- Five-wave loop remains playable and passes automated acceptance/performance gates.
- `CHECKPOINT.md` and canonical `BackyardMayhem_LATEST.zip` both point to the exact same tested milestone.
