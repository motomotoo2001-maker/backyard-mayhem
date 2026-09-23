# Backyard Mayhem — Development Checkpoint

## Canonical workflow
- `main` = latest tested stable version.
- `dev/backyard-vertical-slice` = active development / QA branch.
- After every completed stage: tests -> commit -> push -> update this file.
- Development plan: `docs/superpowers/plans/2026-09-23-backyard-mayhem-next-development.md`.

## Canonical full snapshot
- Engine baseline: Godot 4.7.2 stable.
- Compatibility candidate: Godot 4.8-dev6, validation only until the 4.7.2 build is fully green.
- Project: Backyard Mayhem / Reference A.
- Status: playable vertical slice.
- ChatGPT Library snapshot: `/BackyardMayhem/LATEST/BackyardMayhem_LATEST.zip`.
- Google Drive snapshot: `Backyard Mayhem/LATEST/BackyardMayhem_LATEST.zip`.
- Current Google Drive file id: `15ZdOAJaLP216dY8QFPJkp8SON1vJFjgV`.
- Current Google Drive snapshot size: 59,062,266 bytes.
- Fresh clean upload verified on 2026-09-23: ZIP integrity PASS, `project.godot` at archive root, 1,842 files, 128 GDScript files, 36 scenes, 796 PNG assets, and 69 test scripts.
- Previous verified SHA-256: `b1247f7b1df490f6051a7f8f006bc2454862695e1707de4d7ada823abd936f22` (older canonical snapshot; recompute after next full-game packaging pass).

## Important repository scope
- The Drive/Library ZIP is the authoritative **full gameplay project** with scenes/scripts/assets/tests.
- GitHub `dev/backyard-vertical-slice` is currently a hardened **QA/bootstrap slice**.
- Its green CI proves the QA/parser contracts below, not yet the entire full gameplay snapshot.
- Highest-priority infrastructure task: synchronize the real text tree (`scripts/`, `scenes/`, `tests/`, `tools/`, `data/`, `project.godot`) from the verified clean ZIP, then run full-game CI.

## Implemented in full snapshot
- Reference A backyard + HUD.
- New 8-direction hero.
- Dash + brief invulnerability + HUD feedback.
- Chair / Garden Hose / Rotary Sprinkler.
- Defense damage states + destruction VFX.
- Electric Fence / Golden Slipper / Super Soaker upgrades.
- Ranged Neighbor Kid.
- Burst AI for Cat / Bulldog / Skateboard Teen.
- Flying Pigeon + splat bombing attack.
- Boss warning + camera impact shake.
- Water/projectile/dust/XP/coin VFX.
- Five-wave / builder / visual / performance test suite.

## Hero animation QA — verified on Godot 4.7.2
- Canonical profile defines 8 directions and **280 required frames**:
  - idle 4 × 8 @ 5 FPS loop
  - run 8 × 8 @ 12 FPS loop
  - fire 4 × 8 @ 14 FPS one-shot
  - build 6 × 8 @ 11 FPS one-shot
  - hurt 3 × 8 @ 12 FPS one-shot
  - dash 4 × 8 @ 18 FPS one-shot
  - death 6 × 8 @ 8 FPS one-shot
- Runtime standard: 320×320 PNG, stable bottom-center ground anchor, safe margins, no labels/white fringe/neighbour debris.
- `hero_frame_validator.gd` rejects clipped frames and detached alpha islands.
- `hero_frame_manifest.gd` enforces the exact 280 canonical filenames.
- `hero_asset_policy.gd` forbids source/user_pack/reference sheets as runtime hero frames.
- `hero_direction_resolver.gd` adds 8-direction deadzone + angular hysteresis.
- `hero_animation_state_resolver.gd` enforces action priority/one-shot locking: `death > hurt > dash > build > fire > run/idle`.
- `hero_spriteframes_validator.gd` checks all 56 SpriteFrames animations for counts, FPS, loop flags and missing textures.

## Enemy animation and asset QA
- `enemy_animation_state_resolver.gd` enforces `death > hurt > attack > run/idle`.
- Unfinished attack/hurt/death one-shots cannot be overwritten by locomotion; hurt may interrupt attack and death may interrupt everything.
- `enemy_asset_policy.gd` only accepts normalized single-frame PNGs under `assets/runtime/enemies/<family>/<action>/<action>_NN.png` for raccoon/cat/bulldog/pigeon/neighbor_kid/skateboard_teen/boss.
- Concept/reference/user_pack/contact-sheet assets and unknown enemy families are rejected from runtime paths.
- `enemy_frame_validator.gd` checks transparent frame margins, clipping, detached alpha debris/accidentally baked VFX and sequence ground-anchor drift while allowing each enemy family to choose its own canvas size.
- Verified run `35889233857` on commit `eeca13875687b99d7289e90dd7801960c28eb700`: parser PASS, **10 test files / 0 failures**.
- Verified run `35889870661` on commit `ef10149d378b625bb4eb62322bb501d1559a6e49`: parser PASS, **12 test files / 0 failures**.
- Verified run `35890282608` on commit `e9c3b6afd5365b4929aa823033a5cb23808b1ab8`: parser PASS, **13 test files / 0 failures**.

## Defense / base visual QA
- `defense_visual_state_resolver.gd` standardizes defense/base health visuals: fresh > 66%, damaged <= 66%, critical <= 33%, broken at 0 HP.
- Visual flags unify cracks, smoke, debris and Electric Fence overlay behavior across Chair/Hose/Sprinkler/base scenes.
- `base_upgrade_visual_profile.gd` defines four visually distinct central-base tiers:
  - tier 0: simple base, no turret socket
  - tier 1: sandbags + 1 turret socket
  - tier 2: armor + power cables + 2 turret sockets
  - tier 3: beacon + power coils + 3 turret sockets
- Base silhouette grows slightly per tier so progression is readable without HUD text.
- Verified commit `1047c67f636bedc60919baf1bf5c4bcc768c662c`: Godot 4.7.2 parser PASS and defense/base tests GREEN.

## Combat/VFX QA
- `combat_vfx_timing_profile.gd` synchronizes combat feedback to animation frames instead of loose timers:
  - fire muzzle/recoil/air-blast on frame 1; recovery on frame 3.
  - dash trail start/peak/end on frames 0/1/3.
  - hurt impact/recovery on frames 0/2.
- `enemy_hit_feedback_profile.gd` defines standard/heavy/boss flash, hit-stop, knockback, shake and death-burst intensity.
- `boss_telegraph_profile.gd` differentiates boss attacks:
  - Heavy Swing: shorter windup, compact radius, 2 anticipation pulses.
  - Radial Slam: longer windup, much larger danger radius, 3 pulses and heavier impact shake.
- `water_vfx_asset_policy.gd` only allows canonical transparent runtime paths under `assets/runtime/vfx/water/<kind>/<kind>_NN.png` for stream/splash/impact/projectile/foam/vortex families; raw concept sheets and turret-baked effects are rejected.
- Verified run `35889565334` on commit `6fd13a91d9bc2d28dcdbf2b73f18773c95922fc5`: parser PASS, **11 test files / 0 failures**.
- Verified run `35896867038` on commit `4ef714ef8707c5b00101c3e47fc307ae5995121e`: parser PASS, **17 test files / 0 failures**.

## HUD readability QA
- `hud_readability_profile.gd` defines minimum readable card sizes for Dash, Health, Wave Transition, Upgrade Hint, Boss Warning and generic Status.
- Warning priority is explicit: `boss_warning > critical_health > wave_transition > upgrade_hint > status`.
- Low-priority status cannot cover a boss warning; at most 2 transient cards may occupy the playfield at once.
- Verified run `35897158357` on commit `c2e3a8132f8620b81fe170f37c14688a5e8e9dab`: parser PASS, **18 test files / 0 failures**.

## CI hardening
- GitHub Actions runs Godot 4.7.2 editor parse gate + headless tests.
- `SCRIPT ERROR`, `Parse Error` and failed script loads are hard failures.
- `tests/run_all.gd` rejects non-instantiable scripts with `Script.can_instantiate()` instead of hanging until timeout.
- Earlier timing-test parse issue was traced to Godot 4.7.2 type inference; explicit float typing fixed it at the source.

## Visual audit findings
- Several uploaded enemy/water sheets are good style references but are **concept sheets, not production atlases**.
- Common defects to exclude from runtime assets: white backgrounds, labels, UI counters, mixed camera angles, baked speech bubbles/dust/VFX/shadows and inconsistent per-frame scale.
- Water VFX should be normalized into separate transparent assets: stream, projectile, splash/impact, foam/droplets, vortex/super attack.
- Enemy priority for normalized runtime animation: Raccoon -> Cat -> Bulldog -> Pigeon -> Neighbor Kid -> Skateboard Teen -> Boss.

## Current priorities
1. Synchronize the real gameplay text tree from the verified Google Drive `BackyardMayhem_LATEST.zip` into GitHub, then run full-game CI.
2. Integrate verified defense/base/boss/HUD profiles into the real gameplay scenes after tree sync.
3. Improve five-wave progression and between-wave hero/base upgrade choices.
4. Finish/validate all 280 hero runtime frames and hook them into real SpriteFrames.
5. Integrate combat timing profile into real Player/VFX code: recoil, muzzle/air blast, dash trail, hurt impact.
6. Normalize Water VFX into transparent strips with fixed origins/anchors.
7. Normalize first enemy production set: Raccoon, validate every frame, then Cat -> Bulldog -> Pigeon -> Kid -> Skater -> Boss.
8. Polish backyard composition and HUD readability.
9. Re-run five-wave acceptance, builder/water regressions and 100-enemy performance.
10. Create a new canonical `BackyardMayhem_LATEST.zip`, SHA-256, Drive checkpoint and GitHub tag after the full-game gate is green.

## New-chat recovery rule
Read `CHECKPOINT.md`, `LATEST_SNAPSHOT.md`, and the development plan first. Restore the canonical Google Drive/Library ZIP if the local project is unavailable. Never guess which archive is current.
