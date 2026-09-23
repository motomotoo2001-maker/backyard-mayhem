# Backyard Mayhem — Visual QA / Production Asset Plan

Updated: 2026-09-23

## Production rule
Source sheets, contact sheets, concept art, labels, grids, white mattes, speech bubbles and baked gameplay VFX are **reference material only**. Runtime animation textures must be normalized production frames under `assets/runtime/` with stable anchor/scale and transparent backgrounds.

## Priority 1 — Main hero
- Keep the clean 8-direction rotation sheet as identity/silhouette reference only.
- Runtime target: 320×320 RGBA, common bottom-center ground anchor, no clipped head/feet, no detached alpha islands, no baked speed lines.
- Required states: idle/run/fire/build/hurt/dash/death × 8 directions.
- Fire muzzle/air-blast/recoil must be synchronized to a single contact frame via `CombatVFXTimingProfile`.
- Dash trail remains a separate VFX layer rather than baked into hero art.

## Priority 2 — Water combat VFX
Current water source sheets have a good cartoon language but are presentation sheets with white backgrounds, labels and grids. They must not be referenced directly at runtime.

Production strips needed:
- continuous water stream: 8 frames
- water projectile/glob: 8–12 frames depending on use
- impact splash: 6–8 frames
- pressure burst / air-water impact: 6 frames
- super-soaker vortex: 8 frames

Rules:
- transparent background
- no text/grid/frame labels
- consistent origin at nozzle/contact point
- no character/turret baked into VFX
- stream thickness and highlight style consistent across upgrades

## Priority 3 — Neighbor Kid
Problems in source sheet:
- presentation labels/background
- water spray is baked into firing frames
- pose scale drifts slightly across attack sequence

Fix:
- isolate kid body/weapon animation from water VFX
- common foot anchor
- separate muzzle/nozzle marker for projectile spawn
- clear anticipation → fire → recoil → recovery timing

## Priority 4 — Pigeon Bomber
Problems in source sheet:
- source is a concept/action sheet rather than a normalized strip
- dive lines, hat/debris and defeat dust are baked into some poses
- frame extents vary strongly between hover and dive

Fix:
- normalize hover/dive/bomb/hurt/death independently
- keep bomb projectile and ground splat as separate VFX
- stabilize body center while wings animate

## Priority 5 — Bulldog / Cat burst enemies
Bulldog source problems:
- speech bubble / comic bark marks baked into attack poses
- tears/drool/debris should be separate VFX
- attack silhouette changes strongly frame-to-frame

Cat source problems:
- mixed front/rear orientations inside one presentation sheet
- ground shadows vary by frame
- pounce needs a stable takeoff/contact/recovery arc

Fix:
- split body animation from dust, bark/hiss symbols and hit effects
- common body/foot anchors
- dedicated hurt/death reaction so hits are readable

## Priority 6 — Skateboard Teen
Problems in source sheet:
- mixed front, front-down and isometric views
- board-only frames mixed with character frames
- inconsistent body/board anchor during kickflip/fall

Fix:
- choose one game camera direction set and regenerate/normalize around it
- board and rider may use separate layers for falls if needed
- contact shadow must be runtime effect, not painted differently per frame

## Combat readability rules
- projectile spawn / muzzle VFX happens on the action contact frame, not animation start
- small attacks: short flash / compact splash; heavy attacks: larger silhouette and longer recovery
- enemy hurt state must remain visible long enough to read but cannot permanently interrupt AI
- death VFX must not hide collectible/XP drops
- boss telegraphs remain readable above ordinary splash/dust clutter

## Runtime asset acceptance gate
Every production animation should pass:
1. correct frame count and FPS
2. transparent background
3. stable anchor and scale
4. no clipping
5. no detached label/debris alpha islands
6. no source-sheet/reference path used by runtime scenes
7. VFX separated from character sprites when it needs independent timing
8. in-engine preview at gameplay scale before replacing the previous asset

## Replacement order
1. Hero fire/run/build/hurt/dash/death
2. Water stream/projectile/impact VFX
3. Neighbor Kid ranged attack
4. Pigeon hover/bomb/death
5. Bulldog + Cat burst/hurt/death
6. Skateboard Teen locomotion/fall
7. Boss attack telegraphs / impact pass
