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
- Canonical snapshot: `/BackyardMayhem/LATEST/BackyardMayhem_LATEST.zip`.
- Previous verified SHA-256: `b1247f7b1df490f6051a7f8f006bc2454862695e1707de4d7ada823abd936f22`.

## Important repository scope
- The Library ZIP is the authoritative **full gameplay project** with scenes/scripts/assets/tests.
- GitHub `dev/backyard-vertical-slice` is currently a hardened **QA/bootstrap slice**.
- Its green CI proves the QA/parser contracts below, not yet the entire full gameplay snapshot.
- Highest-priority infrastructure task: synchronize the real text tree (`scripts/`, `scenes/`, `tests/`, `tools/`, `data/`, `project.godot`) from the latest ZIP as soon as archive extraction runtime is healthy, then run full-game CI.

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

## Combat/VFX QA
- `combat_vfx_timing_profile.gd` synchronizes combat feedback to animation frames instead of loose timers:
  - fire muzzle/recoil/air-blast on frame 1; recovery on frame 3.
  - dash trail start/peak/end on frames 0/1/3.
  - hurt impact/recovery on frames 0/2.
- Test timing is derived from the canonical hero FPS profile, including Dash = 18 FPS.

## CI hardening
- GitHub Actions runs Godot 4.7.2 editor parse gate + headless tests.
- `SCRIPT ERROR`, `Parse Error` and failed script loads are hard failures.
- `tests/run_all.gd` now rejects non-instantiable scripts with `Script.can_instantiate()` instead of hanging until timeout.
- Fresh verified run `35888694500` on commit `6b967ed061fbdbbf344d47627df9ba004d377692`: parser PASS, **9 test files / 0 failures**, no hidden parse/script errors.

## Visual audit findings
- Several uploaded enemy/water sheets are good style references but are **concept sheets, not production atlases**.
- Common defects to exclude from runtime assets: white backgrounds, labels, UI counters, mixed camera angles, baked speech bubbles/dust/VFX/shadows and inconsistent per-frame scale.
- Water VFX should be normalized into separate transparent assets: stream, projectile, splash/impact, foam/droplets, vortex/super attack.
- Enemy priority for normalized runtime animation: Raccoon -> Cat -> Bulldog -> Pigeon -> Neighbor Kid -> Skateboard Teen -> Boss.

## Current priorities
1. Synchronize full gameplay text tree from `BackyardMayhem_LATEST.zip` into GitHub when the archive execution runtime is available.
2. Finish/validate all 280 hero runtime frames and hook them into real SpriteFrames.
3. Integrate combat timing profile into real Player/VFX code: recoil, muzzle/air blast, dash trail, hurt impact.
4. Normalize Water VFX into transparent strips with fixed origins/anchors.
5. Normalize enemy runtime sprites and add readable hit/death feedback.
6. Polish tower/building upgrade visuals, backyard composition and HUD readability.
7. Re-run five-wave acceptance, builder/water regressions and 100-enemy performance.
8. Create a new canonical `BackyardMayhem_LATEST.zip`, SHA-256, checkpoint/tag after the full-game gate is green.

## New-chat recovery rule
Read `CHECKPOINT.md`, `LATEST_SNAPSHOT.md`, and the development plan first. Restore the canonical ZIP if the local project is unavailable. Never guess which archive is current.
