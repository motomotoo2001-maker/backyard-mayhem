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
- ChatGPT Library snapshot: `/BackyardMayhem/LATEST/BackyardMayhem_LATEST.zip`.
- Google Drive snapshot: `Backyard Mayhem/LATEST/BackyardMayhem_LATEST.zip`.
- Current Google Drive file id: `15ZdOAJaLP216dY8QFPJkp8SON1vJFjgV`.
- Current Google Drive snapshot size: 59,062,266 bytes.
- Fresh clean upload verified on 2026-09-23: ZIP integrity PASS, `project.godot` at archive root, 1,842 files, 128 GDScript files, 36 scenes, 796 PNG assets, and 69 test scripts.
- Previous verified SHA-256: `b1247f7b1df490f6051a7f8f006bc2454862695e1707de4d7ada823abd936f22` (older canonical snapshot; recompute after next full-game packaging pass).

## Important repository scope
- The Drive/Library ZIP is the authoritative **full gameplay project** with scenes/scripts/assets/tests.
- GitHub `dev/backyard-vertical-slice` is currently a hardened **QA/bootstrap slice**.
- Its green CI proves the QA/parser contracts below, not yet the entire full gameplay snapshot.
- Highest-priority infrastructure task: synchronize the real text tree (`scripts/`, `scenes/`, `tests/`, `tools/`, `data/`, `project.godot`) from the verified clean ZIP, then run full-game CI.

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

## Enemy animation and asset QA
- `enemy_animation_state_resolver.gd` enforces `death > hurt > attack > run/idle`.
- Unfinished attack/hurt/death one-shots cannot be overwritten by locomotion; hurt may interrupt attack and death may interrupt everything.
- `enemy_asset_policy.gd` only accepts normalized single-frame PNGs under `assets/runtime/enemies/<family>/<action>/<action>_NN.png` for raccoon/cat/bulldog/pigeon/neighbor_kid/skateboard_teen/boss.
- Concept/reference/user_pack/contact-sheet assets and unknown enemy families are rejected from runtime paths.
- `enemy_frame_validator.gd` checks transparent frame margins, clipping, detached alpha debris/accidentally baked VFX and sequence ground-anchor drift while allowing each enemy family to choose its own canvas size.

### Raccoon production animation QA
- Runtime canvas: **256×256**, stable ground anchor `(128, 236)`, horizontal flip allowed.
- Canonical actions total **27 frames**: idle 4 @ 6 FPS loop; run 8 @ 12 FPS loop; attack 6 @ 12 FPS one-shot with hit frame 3; hurt 3 @ 12; death 6 @ 9.
- `raccoon_frame_manifest.gd` enforces exactly 27 runtime filenames.
- `raccoon_spriteframes_validator.gd` checks all five animations for frame counts, FPS, loop flags and missing textures.
- Verified run `35905143315` on commit `bfb46623800da8abb6153e8fa7de7fe4f256ea6d`: Godot 4.7.2 parser PASS, **28 test files / 0 failures**.

### Cat production animation QA
- Runtime canvas: **256×256**, stable ground anchor `(128, 238)`, horizontal flip allowed.
- Canonical actions total **27 frames**: idle 4 @ 7 FPS loop; run 8 @ 14 FPS; attack/pounce 6 @ 14 FPS one-shot with hit frame 3; hurt 3 @ 13; death 6 @ 10.
- `cat_frame_manifest.gd` enforces exactly 27 runtime filenames.
- `cat_spriteframes_validator.gd` validates all five Cat animations.
- Verified run `35907817899` on commit `8930ba8dab73ce9df4aac22d41586c3446eaa015`: Godot 4.7.2 parser PASS, **31 test files / 0 failures**.

### Bulldog production animation QA
- Runtime canvas: **288×288**, stable ground anchor `(144, 268)`, horizontal flip allowed.
- Canonical actions total **28 frames**:
  - idle 4 @ 5 FPS loop
  - run 8 @ 9 FPS loop
  - attack 7 @ 10 FPS one-shot; heavy hit event on frame 4
  - hurt 3 @ 9 FPS one-shot
  - death 6 @ 8 FPS one-shot
- `bulldog_frame_manifest.gd` enforces exactly 28 runtime filenames under `assets/runtime/enemies/bulldog/<action>/`.
- `bulldog_spriteframes_validator.gd` checks all five Bulldog animations for frame counts, FPS, loop flags and missing textures.
- Verified run `35909112144` on commit `dfbac2fc67486271fd98d4e87e6a3ee1b939e66b`: Godot 4.7.2 parser PASS, **34 test files / 0 failures**.

### Pigeon production animation QA
- Runtime canvas: **256×256**, stable flight anchor `(128, 156)`, horizontal flip allowed.
- Canonical actions total **27 frames**:
  - idle 4 @ 6 FPS loop
  - fly 8 @ 12 FPS loop
  - attack/bomb 6 @ 11 FPS one-shot; `bomb_release` event on frame 3
  - hurt 3 @ 12 FPS one-shot
  - death/fall 6 @ 9 FPS one-shot
- `pigeon_frame_manifest.gd` enforces exactly 27 runtime filenames under `assets/runtime/enemies/pigeon/<action>/`.
- `pigeon_spriteframes_validator.gd` checks all five Pigeon animations for frame counts, FPS, loop flags and missing textures.
- Verified run `35909887761` on commit `7853934cb2c1fb361588cabdf406d7b5f9df09ea`: Godot 4.7.2 parser PASS, **37 test files / 0 failures**.

## Defense / base visual QA
- `defense_visual_state_resolver.gd` standardizes fresh/damaged/critical/broken states plus cracks/smoke/debris/electric overlay.
- `base_upgrade_visual_profile.gd` defines four visibly distinct central-base tiers with 0/1/2/3 turret sockets, sandbags, armor, cables, beacon and power coils.

## Combat/VFX QA
- `combat_vfx_timing_profile.gd` synchronizes fire/dash/hurt feedback to animation frames.
- `enemy_hit_feedback_profile.gd` defines standard/heavy/boss flash, hit-stop, knockback, shake and death-burst intensity.
- `boss_telegraph_profile.gd` differentiates Heavy Swing and Radial Slam anticipation/impact.
- `water_vfx_asset_policy.gd`, `water_vfx_sequence_profile.gd`, `water_vfx_manifest.gd`, and `water_vfx_spriteframes_validator.gd` define/validate **37 canonical Water VFX frames**.
- `visual_feedback_orchestrator.gd` exposes scene-ready snapshots for hero cues, defense/base visuals, boss warning/HUD data and enemy hit/death feedback.

## HUD readability QA
- `hud_readability_profile.gd` defines minimum readable card sizes and explicit priority `boss_warning > critical_health > wave_transition > upgrade_hint > status`.
- At most 2 transient cards may occupy the playfield at once.

## Five-wave gameplay progression QA
- `wave_progression_profile.gd` defines the five-wave curve: Raccoon -> Cat -> Bulldog/Pigeon -> Neighbor Kid/Skateboard Teen -> mixed Boss finale.
- `between_wave_upgrade_profile.gd` guarantees Hero/Base/Utility strategic lanes after waves 1–4.
- `vertical_slice_session.gd` orchestrates wave -> reward -> intermission -> purchase -> next wave -> victory without duplicate rewards/upgrades.

## CI hardening
- GitHub Actions runs Godot 4.7.2 editor parse gate + headless tests.
- `SCRIPT ERROR`, `Parse Error` and failed script loads are hard failures.
- `tests/run_all.gd` rejects non-instantiable scripts with `Script.can_instantiate()` instead of hanging.

## Visual audit findings
- Several uploaded enemy/water sheets are style references, not production atlases; runtime assets must exclude white backgrounds, labels, UI counters, mixed camera angles, baked speech bubbles/dust/VFX/shadows and inconsistent scale.
- Water VFX contract is complete; actual 37 transparent frames still need production/normalization.
- Enemy production-contract status: **Raccoon complete, Cat complete, Bulldog complete, Pigeon complete; next Neighbor Kid -> Skateboard Teen -> Boss**.

## Current priorities
1. Synchronize the real gameplay text tree from verified Google Drive `BackyardMayhem_LATEST.zip` into GitHub, then run full-game CI.
2. Integrate `vertical_slice_session.gd`, `visual_feedback_orchestrator.gd`, and verified defense/base/boss/HUD/wave profiles into real gameplay scenes after tree sync.
3. Continue enemy production contracts: **Neighbor Kid -> Skateboard Teen -> Boss**.
4. Produce/normalize the 37 canonical Water VFX frames and assemble validated SpriteFrames.
5. Finish/validate all 280 hero runtime frames and hook them into real SpriteFrames.
6. Integrate combat timing into real Player/VFX code: recoil, muzzle/air blast, dash trail, hurt impact and enemy hit/death feedback.
7. Produce/normalize actual runtime enemy frames after contracts are complete.
8. Polish backyard composition and HUD readability.
9. Re-run five-wave acceptance, builder/water regressions and 100-enemy performance.
10. Create a new canonical `BackyardMayhem_LATEST.zip`, SHA-256, Drive checkpoint and GitHub tag after the full-game gate is green.

## New-chat recovery rule
Read `CHECKPOINT.md`, `LATEST_SNAPSHOT.md`, and the development plan first. Restore the canonical Google Drive/Library ZIP if the local project is unavailable. Never guess which archive is current.
