# Backyard Mayhem — Development Checkpoint

## Canonical workflow
- `main` = latest tested stable version.
- `dev/backyard-vertical-slice` = active development / QA branch.
- After every completed stage: tests -> commit -> push -> update this file.

## Canonical full snapshot
- Engine: Godot 4.7.2
- Project: Backyard Mayhem / Reference A
- Status: playable vertical slice
- Library snapshot: `/BackyardMayhem/LATEST/BackyardMayhem_LATEST.zip`
- SHA-256: `b1247f7b1df490f6051a7f8f006bc2454862695e1707de4d7ada823abd936f22`
- Source archive: `BackyardMayhem_Project_Backup.rar`
- Snapshot excludes generated `.godot` cache, local backups and `*.gd.uid` sidecars.

## Important repository scope
- The Library ZIP above is the authoritative **full gameplay project** with the latest scenes/scripts/assets/tests.
- The current GitHub `dev/backyard-vertical-slice` tree is still a **QA/bootstrap slice** used to harden animation/art contracts and CI.
- Its `scenes/levels/backyard.tscn` is an older bootstrap scene, so a green GitHub Actions run currently proves the QA helpers/parser are clean, **not yet the entire full gameplay snapshot**.
- Next major repository task, once ZIP extraction is available in the execution runtime, is to synchronize the real text project tree (`scripts/`, `scenes/`, `tests/`, `tools/`, `data/`, `project.godot`) from `BackyardMayhem_LATEST.zip` into this branch and then run full-game CI.

## Implemented in full snapshot
- Reference A backyard + HUD
- New 8-direction hero
- Dash + brief invulnerability + HUD feedback
- Chair / Garden Hose / Rotary Sprinkler
- Defense damage states + destruction VFX
- Electric Fence / Golden Slipper / Super Soaker upgrades
- Ranged Neighbor Kid
- Burst AI for Cat / Bulldog / Skateboard Teen
- Flying Pigeon + splat bombing attack
- Boss warning + camera impact shake
- Water/projectile/dust/XP/coin VFX
- Five-wave / builder / visual / performance test suite

## Hero animation QA — verified on Godot 4.7.2
- Canonical profile defines 8 directions and **280 required frames**:
  - idle 4 × 8
  - run 8 × 8
  - fire 4 × 8
  - build 6 × 8
  - hurt 3 × 8
  - dash 4 × 8
  - death 6 × 8
- Runtime standard: 320×320 PNG, top margin >= 18 px, bottom >= 12 px, sides >= 8 px, stable ground anchor.
- `hero_frame_validator.gd` rejects clipped frames and large detached alpha islands such as label fragments, neighboring-frame debris or accidentally baked VFX, while tolerating tiny export/AA specks.
- `hero_frame_manifest.gd` enforces the exact 280 canonical filenames and rejects missing, unexpected and duplicate frames.
- `hero_asset_policy.gd` forbids source/user_pack/reference sheets from being referenced as runtime hero frames; only normalized canonical PNGs under `assets/runtime/characters/builder_hero/` are accepted.
- `hero_direction_resolver.gd` adds 8-direction facing with movement/aim deadzone and angular hysteresis to prevent FRONT↔FRONT-RIGHT sprite flicker near sector boundaries.
- GitHub Actions treats `SCRIPT ERROR`, `Parse Error`, and failed script loads as hard failures even when Godot returns process exit code 0.

## Fresh QA evidence
- Run `35872806284`: parser PASS, 3 test files / 0 failures.
- Run `35873347067`: parser PASS, 4 test files / 0 failures.
- Run `35874071147`: parser PASS, 5 test files / 0 failures.
- Run `35874752071` on commit `13e9d2ffbd0b8515939c3bc2ea51e98ccb7a0c34`: parser PASS, **6 test files / 0 failures**, no hidden script/parse errors.

## Current hero art task
- Root cause of bad slicing: old movement sheets clip head/feet in several directions and some source sheets contain labels, white backgrounds, grids or decorative debris.
- The clean 8-direction rotation sheet is the visual identity/silhouette reference, not a runtime atlas.
- Production standard: transparent normalized frames, common ground anchor, no labels, no white fringe, no neighboring-frame debris.
- Continue cleaning/replacing idle/run/fire/build/hurt/dash/death in 8 directions.

## Next
1. Add one-shot hero animation state priority/locking so idle/run cannot interrupt fire/build/hurt/dash/death mid-action.
2. Synchronize the full gameplay text tree from the Library ZIP into GitHub as soon as archive extraction is available again, then expand CI to the real game.
3. Finish hero animation replacement and run the frame validator over all real runtime frames.
4. Combat animation/VFX polish: recoil, muzzle/air blast, hit reactions, impacts, dash readability.
5. Enemy animation readability / death feedback, then wave and upgrade balance polish.

## New-chat recovery rule
Read `CHECKPOINT.md` and `LATEST_SNAPSHOT.md` first. If local files are unavailable or ambiguous, restore `/BackyardMayhem/LATEST/BackyardMayhem_LATEST.zip` and verify its SHA-256 before continuing. Never guess which archive is current.
