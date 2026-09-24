# Backyard Mayhem — Development Checkpoint

Updated: 2026-09-24

## Canonical workflow
- `main` = tested stable milestones.
- `dev/backyard-vertical-slice` = active development / QA branch.
- Development plan: `docs/superpowers/plans/2026-09-23-backyard-mayhem-next-development.md`.
- Canonical full project remains the Google Drive / Library ZIP until the complete gameplay tree is synchronized into GitHub.

## Latest verified GitHub milestone — GREEN
- Verified development commit: `612034a4e929ed72f149ba7d527b503d0c0b78dd` (`vfx: antialias player fire effect lines`).
- Canonical CI engine: Godot 4.7.2 stable.
- Python art pipeline: **16 tests / PASS**.
- Godot editor parse gate: **PASS**.
- Godot headless suite: **69 test files / 0 failures**.
- Visual snapshot gate: **PASS**.
- CI captures Backyard Wave 1, damaged base, boss Wave 5, plus `player-vfx-preview.png` for muzzle/air-blast feedback.
- Player fire VFX now use layered muzzle/core/spark geometry and layered pressure arcs/wisps; all Line2D spark/arc/wisp geometry is antialiased.

## Google Drive canonical snapshot
- File: `Backyard Mayhem/LATEST/BackyardMayhem_LATEST.zip`.
- Drive file id: `15ZdOAJaLP216dY8QFPJkp8SON1vJFjgV`.
- Size: 59,062,266 bytes.
- Drive metadata verified 2026-09-24: shared=true, permission `anyone` currently has role `writer`.
- Archive baseline: `project.godot` at root, 1,842 files, 128 GDScript files, 36 scenes, 796 PNG assets.
- Previous verified SHA-256: `b1247f7b1df490f6051a7f8f006bc2454862695e1707de4d7ada823abd936f22`; recompute only after a new full packaging pass.
- Do not overwrite this full ZIP with a partial QA/bootstrap repository snapshot.

## Repository scope
- GitHub `dev/backyard-vertical-slice` is a hardened QA/bootstrap slice plus safely restored real-project code.
- It is not yet the complete canonical gameplay tree.
- Task 1 remains open: synchronize `project.godot`, `scripts/`, `scenes/`, `tests/`, `tools/`, and `data/` from the canonical full ZIP while excluding `.godot/`, backups/temp captures, and generated UID noise.
- Green GitHub CI therefore proves the QA/contracts and restored real-player layers, not yet the entire Drive snapshot.

## Hero production animation status
- Required contract: 8 directions × idle/run/fire/build/hurt/dash/death = **280 frames / 56 SpriteFrames animations**.
- Runtime standard: 320×320 transparent PNG, stable bottom-center ground anchor, safe margins, no labels, white fringe or detached debris.
- `tools/art/build_new_reference_hero.py` now routes production RUN through `hero_authored_run_resilient.py` rather than procedural bob/squash transforms.
- Authored RUN extraction uses connected-component detection with tested projection recovery fallback for source rows that are vertically joined.
- Presentation labels / upper chrome are stripped conservatively after extraction.
- Python regression coverage includes authored extraction geometry, projection recovery, run-only layout and full-project candidate safety.
- Production art replacement is still incomplete for the whole 280-frame set; authored RUN is the current strongest pipeline segment.

## Real BackyardPlayer / combat feedback status
- 8-direction hysteresis resolver prevents direction flicker.
- Deterministic action priority: `idle/run < fire < build < dash < hurt < death/defeat`.
- Dash requests authored `dash_*` and falls back safely when absent.
- Hurt/death support directional names with legacy fallback.
- `animation_vfx_event(event_name, action, frame)` dispatches frame-synced fire/dash/hurt events through `VisualFeedbackOrchestrator`.
- `PlayerVisualRig` owns recoil/dash/hurt feedback tuning so gameplay code no longer duplicates visual constants.
- `PlayerVFXEmitter` provides scene-facing muzzle flash and air-blast effects.
- Fire VFX now include outer/core flash, two spark streaks, inner/outer pressure arcs and upper/lower wisps; line geometry uses antialiasing.
- CI has a dedicated deterministic `player-vfx-preview.png` snapshot.

## QA/bootstrap gameplay layer
- Five-wave deterministic session with rewards, intermissions and victory/defeat.
- Hero/Base/Utility between-wave upgrade lanes.
- Runtime coordinator + HUD model + visual presenter.
- Base has visual upgrade tiers, turret sockets, damage states and boss warning presentation.
- Boss Alert is kept in a safe HUD area and no longer overlaps the main header.
- CI captures deterministic Wave 1 / damaged tier / boss Wave 5 screenshots.

## Enemy / water production contracts
- Normalized transparent runtime frames only; no concept sheets, white matte, labels, speech bubbles or unrelated baked VFX.
- Raccoon -> Cat -> Bulldog -> Pigeon -> Neighbor Kid -> Skateboard Teen -> Boss remains the production order.
- Manifests, animation profiles and SpriteFrames validators exist for the contracted enemy families.
- Water VFX contract defines 37 canonical frames; production transparent frames still need final normalization/integration.

## Current priorities
1. Complete authored hero production art beyond RUN, beginning with FIRE and then build/hurt/dash/death, preserving 320×320 anchor/margin contracts.
2. Continue frame-synced combat feel: muzzle/air blast/recoil/dash/hurt visual QA and scene integration.
3. Synchronize the full canonical gameplay text tree into GitHub when safe, then run the same Godot 4.7.2 gates against the complete game.
4. Produce/normalize the 37 Water VFX frames.
5. Produce enemy runtime art in order: Raccoon -> Cat -> Bulldog -> Pigeon -> Neighbor Kid -> Skateboard Teen -> Boss.
6. Integrate base/defense/boss/HUD visual profiles into the full gameplay scenes.
7. Polish backyard environment, five-wave balance and HUD readability.
8. Run full five-wave acceptance + builder/water regressions + 100-enemy performance.
9. Package a new full `BackyardMayhem_LATEST.zip`, recompute SHA-256 and replace the Drive/Library LATEST only after the full project is GREEN.

## New-chat recovery rule
Read `CHECKPOINT.md`, `LATEST_SNAPSHOT.md`, and the development plan first. Restore the canonical Drive/Library ZIP if the local full project is unavailable. Never guess which archive is current, and never replace the Drive LATEST with a partial QA snapshot.
