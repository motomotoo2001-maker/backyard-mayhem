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

## Current hero art task
- Root cause of bad slicing identified: old movement sheet clips head/feet in several directions and can include extra artifacts.
- Production standard: 320x320 transparent frames, common ground anchor, safe margins, no labels, no white fringe, no neighboring-frame debris.
- Continue cleaning/replacing idle/run/fire/build/hurt/dash/death in 8 directions.

## Next
1. Finish hero animation replacement and re-run hero contracts.
2. Combat animation and VFX polish.
3. Enemy animation readability / hit reactions / death feedback.
4. Wave and upgrade balance polish.

## New-chat recovery rule
Read `CHECKPOINT.md` and `LATEST_SNAPSHOT.md` first. If local files are unavailable or ambiguous, restore `/BackyardMayhem/LATEST/BackyardMayhem_LATEST.zip` and verify its SHA-256 before continuing. Never guess which archive is current.
