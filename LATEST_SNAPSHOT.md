# Backyard Mayhem — Latest Snapshot / Recovery Pointer

Updated: 2026-09-24

## Active development branch
`dev/backyard-vertical-slice`

Latest verified development milestone:
`1afd6eead32fa41d0edf4a33140053e0df2346e1`

GitHub Actions run:
`36021844292`

Verification on Godot 4.7.2 stable:
- Python authored-hero art pipeline: PASS.
- Editor parse gate: PASS.
- Headless test suite: PASS.
- Backyard visual snapshots: PASS.

Latest player-visual milestone:
- authored RUN extraction pipeline remains GREEN;
- frame-synced fire/dash/hurt events remain enabled;
- `PlayerVisualRig` now describes recoil, hurt/dash feedback, muzzle flash and air-blast lifetimes;
- `PlayerVFXEmitter` builds procedural muzzle flash and layered air-blast geometry;
- `BackyardPlayer` now spawns muzzle/air-blast effects from real animation frame events, in front of the weapon mount and aligned to aim/facing;
- transient VFX self-fade/self-clean in live scene trees.

## Canonical full binary snapshot
The authoritative complete project with binary/source art assets remains:

Google Drive:
`Backyard Mayhem/LATEST/BackyardMayhem_LATEST.zip`

Google Drive file id:
`15ZdOAJaLP216dY8QFPJkp8SON1vJFjgV`

Size:
`59,062,266 bytes`

Previous verified SHA-256:
`b1247f7b1df490f6051a7f8f006bc2454862695e1707de4d7ada823abd936f22`

Important: the Drive ZIP has NOT yet been overwritten with the newest dev-branch VFX commits. Keep it as the safe full binary snapshot until the next full-package pass can merge the tested GitHub changes back into the complete project and rerun full acceptance.

## Known visual debt
- `fire_back_00.png` still touches the runtime canvas edge in the Python art-pipeline warning and needs a production crop/margin fix.
- The final 64 authored RUN frames still need binary-source visual contact-sheet QA from the full Drive snapshot when local binary extraction is stable.
- Water VFX and enemy production PNG sets are still pending.

## Next order
1. Finish authored hero RUN visual QA and integrate the 8×8 real run frames.
2. Fix `fire_back_00` edge/safe-margin issue.
3. Add visual QA snapshot for the new muzzle/air-blast effects.
4. Produce/normalize Water VFX.
5. Produce enemy runtime art: Raccoon -> Cat -> Bulldog -> Pigeon -> Neighbor Kid -> Skateboard Teen -> Boss.
6. Merge tested dev changes into the complete project, run five-wave/builder/water/performance acceptance, package a new full ZIP, recompute SHA-256, then replace Google Drive LATEST.

## Recovery rule
In a new chat, read `CHECKPOINT.md`, this file, and the development plan first. Restore the canonical Drive ZIP for binary assets and continue from `dev/backyard-vertical-slice` for the newest tested code changes. Never replace the Drive LATEST archive with a partial QA/bootstrap checkout.
