# Backyard Mayhem — Development Checkpoint

## Canonical workflow
- `main` = latest tested stable version.
- `dev/backyard-vertical-slice` = active development branch.
- After every completed stage: tests -> commit -> push -> update this file.

## Canonical full snapshot
- Engine: Godot 4.7.2
- Project: Backyard Mayhem / Reference A
- Status: playable vertical slice
- Library snapshot: `/BackyardMayhem/LATEST/BackyardMayhem_LATEST.zip`
- SHA-256: `b1247f7b1df490f6051a7f8f006bc2454862695e1707de4d7ada823abd936f22`
- Source archive: `BackyardMayhem_Project_Backup.rar`
- Snapshot excludes generated `.godot` cache, local backups and `*.gd.uid` sidecars.

## Implemented
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

## Hero animation QA — current verified state
- Canonical hero profile now defines all 8 directions and 280 required frames.
- Runtime frame standard: 320x320, top margin >= 18 px, bottom >= 12 px, sides >= 8 px.
- Hero frame validator now rejects large detached alpha islands such as label fragments, neighboring-frame debris and accidentally baked VFX while tolerating tiny antialias/export specks.
- GitHub Actions now treats Godot `SCRIPT ERROR`, `Parse Error`, and failed script loads as hard CI failures even if Godot returns exit code 0.
- Verified on Godot 4.7.2 at commit `7e6682cfce0e9f7cb0716776f730bb83087af92f`: editor parse gate PASS; `TEST SUMMARY: 3 test files, 0 failures`; no hidden script/parse errors.

## Current hero art task
- Root cause of bad slicing identified: old movement sheet clips head/feet in several directions and source sheets can contain labels/white backgrounds/decorative debris.
- Clean 8-direction rotation sheet is the visual identity/silhouette reference, not a runtime atlas.
- Production standard: transparent normalized frames, common ground anchor, no labels, no white fringe, no neighboring-frame debris.
- Continue cleaning/replacing idle/run/fire/build/hurt/dash/death in 8 directions.

## Next
1. Add full 280-frame hero manifest validation (names/counts/directions/actions).
2. Finish hero animation replacement and run frame validator over the real runtime set.
3. Combat animation and VFX polish.
4. Enemy animation readability / hit reactions / death feedback.
5. Wave and upgrade balance polish.

## New-chat recovery rule
Read `CHECKPOINT.md` and `LATEST_SNAPSHOT.md` first. If local files are unavailable or ambiguous, restore `/BackyardMayhem/LATEST/BackyardMayhem_LATEST.zip` and verify its SHA-256 before continuing. Never guess which archive is current.
