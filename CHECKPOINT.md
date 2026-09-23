# Backyard Mayhem — Development Checkpoint

## Canonical workflow

- `main` = latest tested stable version.
- `dev` = active development branch.
- After every completed stage: run tests -> commit -> push -> update this file.
- Large ZIP/RAR backups are secondary safety copies only; GitHub is the source of truth for source code, scenes, tests, configs and project metadata.

## Last confirmed playable checkpoint

- Engine: Godot 4.7.2
- Project: Backyard Mayhem / Reference A
- Status: playable vertical slice
- Last full backup: `BackyardMayhem_ReferenceA_2026-09-22_2322.zip`

## Implemented before GitHub resync

- Reference A backyard environment and HUD
- New main hero with 8-direction movement
- Player dash with short invulnerability and HUD feedback
- Chair Barricade / Garden Hose / Rotary Sprinkler
- Defense damage states and destruction VFX
- Electric Fence / Golden Slipper / Super Soaker upgrades
- Ranged Neighbor Kid projectile attack
- Burst AI for Cat / Bulldog / Skateboard Teen
- Flying Pigeon with splat bombing attack
- Boss warning feedback and camera impact shake
- Water, projectile, dust, XP and coin VFX
- Five-wave gameplay acceptance tests and performance tests

## Hero art work in progress

- Root cause of bad hero slicing identified: source crop boxes clipped the top of the head in several 8-direction run cells.
- Target standard: 320x320 transparent frames, common ground anchor, safe top/bottom margins, no labels, no white fringe.
- Hero idle/run pipeline is being moved away from the clipped movement sheet.

## Next development tasks

1. Resync the latest full project into GitHub.
2. Finish clean hero idle/run/fire/build/hurt/dash/death animation set.
3. Re-run hero safe-margin and animation contracts.
4. Continue combat feel/VFX polish.
5. Improve enemy animation readability and wave balance.

## Important

If a new ChatGPT chat starts, read this file and the latest commits first, then continue from `dev`. Do not guess which old ZIP/RAR is current.
