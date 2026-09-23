# Backyard Mayhem — Development Checkpoint

## Canonical workflow
- `main` = latest tested stable version.
- `dev/backyard-vertical-slice` = active development branch.
- After every completed stage: tests -> commit -> push -> update this file.

## Last confirmed playable checkpoint
- Engine: Godot 4.7.2
- Project: Backyard Mayhem / Reference A
- Status: playable vertical slice
- Last full backup: `BackyardMayhem_ReferenceA_2026-09-22_2322.zip`

## Implemented before full GitHub resync
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
- Five-wave acceptance + performance tests

## Current hero art task
- Root cause of bad slicing identified: old movement source clips the top of the head in several directions.
- Standard: 320x320 transparent frames, common ground anchor, safe margins, no labels/white fringe.
- Next: finish clean idle/run/fire/build/hurt/dash/death set and re-run hero contracts.

## Next
1. Resync latest full project into this branch.
2. Finish hero animation replacement.
3. Combat/VFX polish.
4. Enemy animation readability and wave balance.

If a new chat starts, read this file and the latest commits on this branch first. Do not guess which archive is current.
