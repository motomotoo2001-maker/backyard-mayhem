# Backyard Mayhem — Development Checkpoint

Updated: 2026-09-24

## Canonical workflow
- `main` = latest tested stable version.
- `dev/backyard-vertical-slice` = active development / QA branch.
- Development plan: `docs/superpowers/plans/2026-09-23-backyard-mayhem-next-development.md`.
- Required order remains: full gameplay-tree sync -> hero production animation -> frame-synced combat/VFX -> enemy/water production art -> defenses/telegraphs -> environment/balance/HUD -> release checkpoint.

## Latest verified GitHub milestone
- Verified branch HEAD: `ed36192551ad3299c1ded4fa0de3602be7fc89a6`.
- GitHub Actions run: `35969876567`.
- Engine: Godot 4.7.2 stable.
- Editor parse gate: PASS.
- Headless suite: **59 test files / 0 failures**.
- Visual QA capture: PASS under Xvfb + `gl_compatibility`.
- CI generated and uploaded all three deterministic PNG states:
  - `artifacts/backyard-wave1.png`
  - `artifacts/backyard-damaged-tier1.png`
  - `artifacts/backyard-boss-wave5.png`
- Latest visual artifact: `backyard-preview`, artifact id `10795332292`, ZIP digest `sha256:fd260138dea48d4de5c363a24c1e6bf19bcd245fcf96d2f99a8acd180d52ade9`.
- The artifact ZIP was downloaded into the chat runtime, but local archive extraction is still intermittently failing with an internal runtime error. Do not interpret that as CI/project corruption; CI produced all PNGs successfully.

## Canonical full snapshot
- Project: Backyard Mayhem / Reference A.
- Canonical engine: Godot 4.7.2 stable.
- Status in full snapshot: playable vertical slice.
- ChatGPT Library: `/BackyardMayhem/LATEST/BackyardMayhem_LATEST.zip`.
- Google Drive: `Backyard Mayhem/LATEST/BackyardMayhem_LATEST.zip`.
- Google Drive file id: `15ZdOAJaLP216dY8QFPJkp8SON1vJFjgV`.
- Size: 59,062,266 bytes.
- Verified clean upload metadata: `project.godot` at archive root, 1,842 files, 128 GDScript files, 36 scenes, 796 PNG assets, 69 test scripts.
- Previous verified SHA-256: `b1247f7b1df490f6051a7f8f006bc2454862695e1707de4d7ada823abd936f22`; recompute after the next full packaging pass.

## IMPORTANT: repository scope and current blocker
- The Drive/Library ZIP is the authoritative **full gameplay project**.
- GitHub `dev/backyard-vertical-slice` is still a hardened **QA/bootstrap slice plus safely restored real-project files**, not yet the complete gameplay tree.
- Therefore green GitHub CI currently proves the QA/bootstrap contracts and restored independent real-player code, not the entire full snapshot.
- Plan Task 1 is still OPEN: sync `project.godot`, `scripts/`, `scenes/`, `tests/`, `tools/`, and `data/` from the canonical ZIP while excluding `.godot/`, backups/temp captures, and `*.gd.uid`.
- Current environment blocker: local container/Python archive operations intermittently return internal `RuntimeError`. Retry extraction when the runtime becomes available; never guess missing canonical paths.

## Safe full-project sync progress
### Sync Block A — GREEN
Canonical full-project files restored on the development branch:
- `scripts/player/player.gd` — real `BackyardPlayer` gameplay script from the full snapshot.
- `tools/art/build_new_reference_hero.py` — canonical legacy hero build tool from the full snapshot.

Do **not** restore `scenes/player/player.tscn` yet. Its exact dependencies include files that have not all been independently recovered on this branch:
- `scripts/components/movement_component.gd`
- `scripts/components/health_component.gd`
- `scripts/components/hurtbox_component.gd`
- `scripts/player/aim_controller.gd`
- `assets/runtime/characters/builder_hero/builder_hero_frames.tres`
- `scenes/weapons/flip_flop_launcher.tscn`
- `scripts/components/pickup_collector.gd`
- `scripts/build/build_controller.gd`
- `scripts/components/dash_component.gd`

Never guess the original path of separately indexed files until their canonical path is proven.

## Real BackyardPlayer production-prep completed
The restored real player is being hardened so final authored hero animations/VFX can be dropped in without another gameplay rewrite.

1. **8-direction hysteresis**
   - Uses `HeroDirectionResolver`.
   - Default hysteresis: 6°.
   - Prevents direction flicker near sector boundaries.

2. **Dash animation state + compatibility fallback**
   - Requests `dash_*` while dash is active.
   - Falls back to directional `run_*`, then generic `run` until authored dash frames are present.

3. **Directional hurt/death + legacy fallback**
   - Hurt: `hurt_<direction>` -> generic `hurt`.
   - Death: `death_<direction>` -> `death` -> `defeat_<direction>` -> legacy `defeat`.
   - Incapacitated death animation is held instead of returning to idle.
   - Fire is blocked while hurt/death/defeat reaction is active.

4. **Deterministic action interruption priority — GREEN**
   - Runtime priority: `idle/run < fire < build < dash < hurt < death/defeat`.
   - Fire is allowed to finish over locomotion, but build/dash can interrupt it.
   - Build is not interrupted by lower-priority fire, but dash can interrupt build.
   - Hurt cannot be interrupted by dash; death/defeat remains highest priority.
   - RED run `35924940952`: **58 test files / 1 expected failure** (`_should_hold_action_animation` missing).
   - GREEN run `35969549962`: **58 / 0**, parser PASS, three visual snapshots PASS.
   - Visual artifact id `10796020562`, digest `sha256:455b9b5920c2963f61c62bfef1f6b90846772b7ec06bc7111bd6257ec0e7fcb0`.

5. **Frame-synced player combat/VFX events — GREEN**
   - `BackyardPlayer` now exposes `animation_vfx_event(event_name, action, frame)`.
   - `AnimatedSprite2D.frame_changed` is routed through `VisualFeedbackOrchestrator.hero_frame_events`.
   - Current deterministic timing contract:
     - fire frame 1 -> `muzzle`, `recoil_peak`, `air_blast`
     - fire frame 3 -> `recovery`
     - dash frame 0 -> `trail_start`
     - dash frame 1 -> `trail_peak`
     - dash frame 3 -> `trail_end`
     - hurt frame 0 -> `impact`
     - hurt frame 2 -> `recovery`
     - locomotion emits no combat VFX events.
   - RED run `35969730094`: **59 / 2 expected failures** (signal/lookup missing).
   - GREEN run `35969876567`: **59 / 0**, parser PASS, three visual snapshots PASS.
   - Visual artifact id `10795332292`, digest `sha256:fd260138dea48d4de5c363a24c1e6bf19bcd245fcf96d2f99a8acd180d52ade9`.

## Important legacy hero-tool note
`tools/art/build_new_reference_hero.py` is restored because it is part of the canonical full snapshot, **not because its generated animation quality is final**.
- It still creates run frames using procedural bob/sway/squash/stretch from clean direction stills.
- Generic authored build is reused across directions.
- Hurt/defeat are generic legacy sequences.
- Legacy anchor is `(160,306)`.
- The user rejected this quality level. Final production art must replace it with genuinely authored/generated action strips while preserving the runtime contracts below.

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
- `backyard_bootstrap_controller.gd`: interactive preview controls: `SPACE` flow, `1/2/3` upgrades, `D` damage, `H` repair, `R` reset.
- `backyard.tscn`: visible base tier features, turret sockets, health bar, cracks/smoke/debris/electric overlay and boss alert.
- `backyard_snapshot_driver.gd`: deterministic start / damaged-tier1 / boss-wave states for CI screenshots.

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
- Runtime standard: 320×320 transparent PNG; stable bottom-center ground anchor; safe top/bottom/side margins; no labels, white fringe, detached debris or concept-sheet contamination.
- Existing QA: frame manifest, asset policy, frame validator, 8-dir hysteresis resolver, action-state resolver, SpriteFrames validator.
- Production art replacement is NOT complete yet.

## Enemy production contracts
- Common policy: normalized transparent runtime frames under `assets/runtime/enemies/<family>/<action>/`; no concept sheets, labels, white matte, speech bubbles or baked unrelated VFX.
- Raccoon: 27 frames, 256×256, anchor `(128,236)`.
- Cat: 27 frames, 256×256, anchor `(128,238)`.
- Bulldog: 28 frames, 288×288, anchor `(144,268)`.
- Pigeon: 27 frames, 256×256, flight anchor `(128,156)`.
- Neighbor Kid: 27 frames, 288×320, anchor `(144,300)`.
- Skateboard Teen: 28 frames, 288×320, anchor `(144,300)`.
- Boss: 41 frames across 6 animations, 384×384, anchor `(192,356)`.
- Manifests/animation profiles/SpriteFrames validators exist; production PNG sets still need production/integration.

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

## Current priorities
1. Retry local extraction and complete **Task 1: synchronize the real full gameplay text tree** from the verified Drive ZIP into GitHub; then run full-game Godot 4.7.2 CI.
2. While extraction remains unavailable, continue only safe Library-backed sync blocks and real-player integration work with proven canonical paths.
3. Finish/validate all **280 hero runtime frames** and replace real Player SpriteFrames with genuinely authored actions rather than procedural run transforms.
4. Connect the new frame-synced player VFX events to scene-facing recoil, muzzle/air blast, dash trail and hurt-impact consumers.
5. Produce/normalize the **37 Water VFX frames**.
6. Produce normalized enemy frames in order: Raccoon -> Cat -> Bulldog -> Pigeon -> Neighbor Kid -> Skateboard Teen -> Boss.
7. Integrate base/defense tier visuals and boss/HUD profiles into the real gameplay scenes.
8. Polish backyard composition/environment, wave/economy balance and HUD.
9. Run five-wave acceptance + builder/water regressions + 100-enemy performance on the full project.
10. Package a new `BackyardMayhem_LATEST.zip`, recompute SHA-256, replace Drive/Library LATEST and promote a tested milestone to `main`.

## New-chat recovery rule
Read `CHECKPOINT.md`, `LATEST_SNAPSHOT.md`, and the development plan first. Restore the canonical Drive/Library ZIP if the local project is unavailable. Never guess which archive is current. Never mark Task 1 complete until the real full-tree Godot 4.7.2 parser and tests pass on GitHub.
