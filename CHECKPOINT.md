# Backyard Mayhem — Development Checkpoint

Updated: 2026-09-24

## Canonical workflow
- `main` = latest tested stable version.
- `dev/backyard-vertical-slice` = active development / QA branch.
- Development plan: `docs/superpowers/plans/2026-09-23-backyard-mayhem-next-development.md`.
- Required order remains: full gameplay-tree sync -> hero production animation -> frame-synced combat/VFX -> enemy/water production art -> defenses/telegraphs -> environment/balance/HUD -> release checkpoint.

## Latest verified GitHub milestone
- Branch HEAD before this checkpoint update: `c26b1fd49ee66d709739e9589f089787dc47955f`.
- GitHub Actions run: `35922466486`.
- Engine: Godot 4.7.2 stable.
- Editor parse gate: PASS.
- Headless suite: **53 test files / 0 failures**.
- Visual QA capture: PASS under Xvfb + `gl_compatibility`.
- CI now requires and uploads three deterministic PNG states:
  - `artifacts/backyard-wave1.png`
  - `artifacts/backyard-damaged-tier1.png`
  - `artifacts/backyard-boss-wave5.png`
- Visual artifact: `backyard-preview`, artifact id `10777372842`, ZIP digest `sha256:da47365e9a3de9f18d703b0f211439c99ddfb4dec8fe56157d1985bdb2e0be53`.
- The three captures were generated and uploaded successfully by CI. They have not been manually pixel-inspected in this chat because the local container runtime is currently failing archive operations with an internal `RuntimeError`.

## Canonical full snapshot
- Project: Backyard Mayhem / Reference A.
- Canonical engine: Godot 4.7.2 stable.
- Status in full snapshot: playable vertical slice.
- ChatGPT Library: `/BackyardMayhem/LATEST/BackyardMayhem_LATEST.zip`.
- Google Drive: `Backyard Mayhem/LATEST/BackyardMayhem_LATEST.zip`.
- Google Drive file id: `15ZdOAJaLP216dY8QFPJkp8SON1vJFjgV`.
- Size: 59,062,266 bytes.
- Verified clean upload metadata from 2026-09-23: `project.godot` at archive root, 1,842 files, 128 GDScript files, 36 scenes, 796 PNG assets, 69 test scripts.
- Previous verified SHA-256: `b1247f7b1df490f6051a7f8f006bc2454862695e1707de4d7ada823abd936f22`; recompute after the next full packaging pass.
- The Drive ZIP was fetched successfully again on 2026-09-24 and mounted as `/mnt/data/BackyardMayhem_LATEST.zip`.

## IMPORTANT: repository scope and current blocker
- The Drive/Library ZIP is the authoritative **full gameplay project**.
- GitHub `dev/backyard-vertical-slice` is still a hardened **QA/bootstrap slice**, not yet the complete gameplay tree.
- Therefore a green GitHub CI currently proves the QA/bootstrap contracts below, not the entire full snapshot.
- Plan Task 1 is still OPEN: sync `project.godot`, `scripts/`, `scenes/`, `tests/`, `tools/`, and `data/` from the canonical ZIP while excluding `.godot/`, backups/temp captures, and `*.gd.uid`.
- Current session blocker: the local container/Python execution service repeatedly returns internal `RuntimeError` before ZIP extraction starts. Do not interpret this as project/archive corruption. Retry extraction first when the runtime becomes available.

## Implemented in the full gameplay snapshot
- Reference A backyard + HUD.
- 8-direction hero runtime foundation.
- Dash + brief invulnerability + HUD feedback.
- Chair / Garden Hose / Rotary Sprinkler defenses.
- Defense damage states + destruction VFX.
- Electric Fence / Golden Slipper / Super Soaker upgrades.
- Ranged Neighbor Kid.
- Burst AI for Cat / Bulldog / Skateboard Teen.
- Flying Pigeon + splat bombing.
- Boss warning + camera impact shake.
- Water/projectile/dust/XP/coin VFX.
- Five-wave / builder / visual / performance tests.

## Current QA/bootstrap gameplay layer
- `vertical_slice_session.gd`: deterministic five-wave state machine with rewards, intermissions, purchases, base HP/tier, victory and defeat.
- `wave_progression_profile.gd`: five-wave curve ending in mixed boss finale.
- `between_wave_upgrade_profile.gd`: Hero/Base/Utility lanes after waves 1-4.
- `backyard_runtime_coordinator.gd`: scene-facing API combining session, wave profile and visual-feedback data.
- `backyard_hud_model.gd`: view-model for wave/coins/base/threat/focus/intermission state.
- `backyard_visual_presenter.gd`: base-tier/damage/boss-warning presentation state.
- `backyard_bootstrap_controller.gd`: interactive preview controls:
  - `SPACE` wave/intermission flow
  - `1/2/3` Hero/Base/Utility upgrade
  - `D` damage base
  - `H` repair base
  - `R` reset
- `backyard.tscn` includes visible base tier features, turret sockets, health bar, cracks/smoke/debris/electric overlay and boss alert.
- `backyard_snapshot_driver.gd` produces deterministic start / damaged-tier1 / boss-wave visual states for CI screenshots.

## Hero animation production contract
- 8 directions: `front`, `front_right`, `right`, `back_right`, `back`, `back_left`, `left`, `front_left`.
- Required runtime set: **280 frames / 56 SpriteFrames animations**:
  - idle 4 × 8 @ 5 FPS loop
  - run 8 × 8 @ 12 FPS loop
  - fire 4 × 8 @ 14 FPS one-shot
  - build 6 × 8 @ 11 FPS one-shot
  - hurt 3 × 8 @ 12 FPS one-shot
  - dash 4 × 8 @ 18 FPS one-shot
  - death 6 × 8 @ 8 FPS one-shot
- Runtime frame standard: 320×320 transparent PNG; stable bottom-center ground anchor; safe top/bottom/side margins; no labels, white fringe, detached debris or concept-sheet contamination.
- Existing QA: frame manifest, asset policy, frame validator, 8-dir hysteresis resolver, action-state resolver, SpriteFrames validator.
- Production art replacement is NOT complete yet. The old source crop problem was identified earlier; final authored strips still need generation/normalization/integration after full-tree sync.

## Enemy production contracts
- Common policy: runtime-only normalized transparent frames under `assets/runtime/enemies/<family>/<action>/`; no concept sheets, labels, white matte, speech bubbles or baked unrelated VFX.
- Raccoon: 27 frames, 256×256, anchor `(128,236)`.
- Cat: 27 frames, 256×256, anchor `(128,238)`.
- Bulldog: 28 frames, 288×288, anchor `(144,268)`.
- Pigeon: 27 frames, 256×256, flight anchor `(128,156)`.
- Neighbor Kid: 27 frames, 288×320, anchor `(144,300)`.
- Skateboard Teen: 28 frames, 288×320, anchor `(144,300)`.
- Boss: 41 frames across 6 animations, 384×384, anchor `(192,356)`.
- Manifests/animation profiles/SpriteFrames validators exist; normalized production PNG sets still need production/integration.

## Combat / VFX / visual contracts
- `combat_vfx_timing_profile.gd`: deterministic fire/dash/hurt contact-frame timing.
- `enemy_hit_feedback_profile.gd`: flash/hit-stop/knockback/shake/death-burst profiles.
- `boss_telegraph_profile.gd`: Heavy Swing and Radial Slam anticipation/impact profiles.
- `visual_feedback_orchestrator.gd`: scene-ready hero, defense/base, boss, enemy hit/death snapshots.
- `defense_visual_state_resolver.gd`: fresh/damaged/critical/broken plus cracks/smoke/debris/electric overlay.
- `base_upgrade_visual_profile.gd`: four base tiers with 0/1/2/3 turret sockets plus sandbags/armor/cables/beacon/coils.
- Water VFX contract defines **37 canonical frames**; actual transparent production frames still need production/normalization.

## HUD readability contract
- Priority: `boss_warning > critical_health > wave_transition > upgrade_hint > status`.
- Maximum two transient cards over the playfield.
- Bootstrap preview now includes readable base HP and boss warning states.

## Current priorities
1. Retry local extraction and complete **Task 1: synchronize the real full gameplay text tree** from the verified Drive ZIP into GitHub; then run full-game Godot 4.7.2 CI.
2. Finish/validate all **280 hero runtime frames** and replace real Player SpriteFrames.
3. Integrate frame-synchronized recoil, muzzle/air blast, dash trail, hurt impact and enemy hit/death feedback into real gameplay scripts.
4. Produce/normalize the **37 Water VFX frames**.
5. Produce normalized enemy frames in order: Raccoon -> Cat -> Bulldog -> Pigeon -> Neighbor Kid -> Skateboard Teen -> Boss.
6. Integrate base/defense tier visuals and boss/HUD profiles into the real gameplay scenes.
7. Polish backyard composition/environment, wave/economy balance and HUD.
8. Run five-wave acceptance + builder/water regressions + 100-enemy performance on the full project.
9. Package a new `BackyardMayhem_LATEST.zip`, recompute SHA-256, replace Drive/Library LATEST and promote a tested milestone to `main`.

## New-chat recovery rule
Read `CHECKPOINT.md`, `LATEST_SNAPSHOT.md`, and the development plan first. Restore the canonical Drive/Library ZIP if the local project is unavailable. Never guess which archive is current. Never mark Task 1 complete until the real full-tree Godot 4.7.2 parser and tests pass on GitHub.
