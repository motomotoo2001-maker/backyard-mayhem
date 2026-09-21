# Backyard Mayhem — Game Design & Technical Specification

**Date:** 2026-09-21  
**Engine:** Godot 4.7.2  
**Language:** GDScript  
**Genre:** Comedy roguelike shooter with tower-defence elements  
**Presentation:** 2D / 2.5D isometric backyard scene

## 1. Vision

Backyard Mayhem is a fast, readable, comedic roguelike shooter set in a suburban backyard. The player directly controls a backyard hero armed with absurd improvised weapons while a central home/base grows into an automated defensive machine over the course of a run.

The visual target is the approved concept art: clean hand-painted/cartoon rendering, strong silhouettes, soft shadows, readable isometric depth, expressive characters, bright impact VFX, and no placeholder geometry in the finished vertical slice.

The game combines three layers of play:

1. **Active shooter combat** — movement, aiming, dodging, weapon use and enemy prioritization.
2. **Roguelike progression** — XP-driven random upgrade choices during combat.
3. **Tower-defence progression** — coins spent between waves to improve the defended base and unlock/upgrade automated defences.

## 2. First Milestone: Vertical Slice

The first milestone is a polished five-wave run that proves the whole game loop.

It must contain:

- one complete backyard map;
- one playable hero;
- one weapon: Flip-Flop Launcher;
- three regular enemy archetypes;
- one mini-boss on wave 5;
- one central defended base;
- one automated defence type: Water Turret;
- XP pickups and level-ups;
- coin pickups and between-wave base spending;
- three-choice upgrade UI;
- player HP and base HP;
- wave progression;
- game-over and restart;
- production-quality sprites, animation, VFX and UI for all core objects.

The milestone is not complete merely because it launches. It must meet the acceptance criteria in section 23.

## 3. Explicit Non-Goals for the Vertical Slice

The first milestone will not include:

- a large campaign;
- dozens of weapons;
- a permanent meta-progression tree;
- mid-run save/resume;
- online multiplayer;
- manually placing dozens of freeform tower objects;
- a full procedural world generator;
- a large inventory system;
- full localization infrastructure.

These can be considered after the core loop is proven.

## 4. Visual Direction

### 4.1 Rendering approach

Use true 2D / 2.5D rather than a fully 3D game. The backyard is built from editable Godot scenes and layered art rather than a single baked screenshot.

Depth is communicated with:

- Y-sorting;
- foreground occluders;
- soft elliptical character shadows;
- scale and composition appropriate to an isometric camera;
- consistent ground anchors;
- environmental layers with readable overlap.

### 4.2 Animation approach

Use a hybrid animation pipeline:

- character body motion uses hand-drawn/pixel-clean frame animation where appropriate;
- weapons remain separable from the body when that improves reuse;
- muzzle points, projectiles, shadows, hit effects and VFX are independent nodes/scenes;
- animation must preserve a stable ground anchor to avoid visible sprite hopping.

Target frame counts for production character states:

- idle: 6–8 frames;
- run: 8 frames;
- shoot: 4–6 frames;
- hurt: 3–4 frames;
- death: 6–10 frames;
- special: as required.

Not every animation must be present on day one, but the final vertical slice must not expose crude placeholders for core characters.

### 4.3 Juice and feedback

Use restrained but clear feedback:

- hit flash;
- impact VFX;
- knockback;
- small squash/stretch where appropriate;
- short screen shake on strong attacks;
- short hit-stop for heavy impacts;
- debris and splash particles;
- readable damage and state feedback.

Readability always overrides spectacle.

## 5. Asset Pipeline

Source sheets from the supplied archive must be treated as source material, not as final runtime sprite sheets if they include white backgrounds, labels or inconsistent framing.

Pipeline:

1. preserve the original source asset;
2. remove non-art background cleanly and create transparency;
3. separate frames;
4. normalize canvas dimensions per animation set;
5. align a stable ground/pivot anchor;
6. verify weapon hand position and muzzle position;
7. import into Godot;
8. create `SpriteFrames` / animation resources;
9. test animation at runtime for hopping, clipping and halo artifacts;
10. retain provenance and source naming so assets remain traceable.

Runtime assets are organized under:

```text
res://assets/
  characters/
  enemies/
  weapons/
  defenses/
  environment/
  ui/
  vfx/
  audio/
```

## 6. Project Layout

```text
res://
├── assets/
│   ├── characters/
│   ├── enemies/
│   ├── weapons/
│   ├── defenses/
│   ├── environment/
│   ├── ui/
│   ├── vfx/
│   └── audio/
├── scenes/
│   ├── player/
│   ├── enemies/
│   ├── weapons/
│   ├── defenses/
│   ├── pickups/
│   ├── levels/
│   ├── ui/
│   └── vfx/
├── scripts/
│   ├── components/
│   ├── systems/
│   └── utilities/
├── data/
│   ├── weapons/
│   ├── enemies/
│   ├── upgrades/
│   └── waves/
└── tests/
```

The project should favor small, focused scenes and scripts over large monolithic files.

## 7. Main Level Scene

The first level scene is `Backyard.tscn`.

Suggested hierarchy:

```text
Backyard
├── Ground
├── Environment
├── YSortActors
│   ├── Player
│   ├── Enemies
│   ├── Defenses
│   └── Pickups
├── Projectiles
├── VFX
├── Base
├── SpawnPoints
├── Systems
│   ├── GameFlow
│   ├── WaveDirector
│   ├── SpawnManager
│   └── UpgradeSystem
└── HUD
```

The exact internal node names may evolve, but the responsibility boundaries must remain: environment, actors, projectiles, VFX, systems and UI should not be tightly coupled.

## 8. Component Architecture

Reusable behavior belongs in components rather than being duplicated across characters.

### Player

```text
Player (CharacterBody2D)
├── VisualRoot
├── MovementComponent
├── HealthComponent
├── HurtboxComponent
├── WeaponController
├── PickupCollector
└── AnimationController
```

### Enemy

```text
Enemy (CharacterBody2D)
├── VisualRoot
├── HealthComponent
├── HurtboxComponent
├── DamageComponent
├── NavigationComponent
├── EnemyAI
└── AnimationController
```

### Base

The base uses the same reusable health contract where practical, but has base-specific upgrade and defence-slot logic.

Signals are preferred for cross-system communication. Deep hard-coded scene paths such as `get_node("../../../../...")` are prohibited for gameplay integration.

## 9. Player Combat

### 9.1 Movement

The player uses free 8-direction movement through `CharacterBody2D.velocity` and `move_and_slide()` using Godot 4.7 APIs.

### 9.2 Aiming

The first playable build uses a hybrid aiming model:

- explicit mouse/gamepad aiming takes priority when present;
- when no explicit aiming input is being provided, soft auto-targeting selects a nearby dangerous target;
- aim behavior must remain readable and must not cause projectiles to visibly miss because of stale target coordinates.

### 9.3 Flip-Flop Launcher

The first weapon is data-driven. Its tunable data includes at minimum:

- damage;
- fire rate;
- projectile speed;
- projectile count;
- spread;
- pierce;
- knockback;
- critical chance;
- projectile size.

Every weapon scene has an explicit `MuzzlePoint`. Projectiles spawn from that transform, never from the player's arbitrary scene origin.

Weapons must be swappable without rewriting player movement or health logic.

## 10. Enemies

The vertical slice contains three clearly distinct regular enemies.

### Raccoon

- fast;
- low-to-medium HP;
- close-range pressure;
- intended to create movement pressure.

### Neighbor Kid

- medium speed;
- medium threat;
- can harass from range or interfere with defensive structures;
- must feel behaviorally different from the raccoon.

### Big Neighbor

- slow;
- high HP;
- strongly motivated toward the base;
- acts as a tank/space-control enemy.

### Mini-Boss

Wave 5 ends with a mini-boss that uses the same component contracts but has bespoke behavior and presentation. It must be visually and mechanically distinct from simply scaling a normal enemy's HP.

## 11. Central Base and Tower Defence

The central home/base is the defended objective.

The run ends when base HP reaches zero.

The player may be temporarily incapacitated without immediately ending the run. The intended first implementation is:

- player HP reaches zero;
- player becomes inactive for a short recovery period;
- player revives with partial HP;
- the base remains vulnerable during that downtime.

This keeps player death meaningful without ending a long run from a single mistake.

### Base progression

The player does not manually place dozens of towers in the first milestone. Instead, between waves the player spends coins on deliberate base upgrades. These upgrades unlock and improve visible defensive systems on/around the base.

Example progression:

- Base level 1: basic defended yard;
- Base level 2: first Water Turret slot;
- Base level 3: second defence improvement / stronger walls;
- Base level 4: automated sprinkler-style defence;
- Base level 5: special defensive ability.

Exact costs and final upgrade names are balancing data, not hard-coded logic.

## 12. Water Turret

The Water Turret is an editable scene with an explicit firing origin.

Suggested hierarchy:

```text
WaterTurret
├── BaseSprite
├── Head
│   └── MuzzlePoint
├── DetectionArea
├── AnimationPlayer
├── Audio
└── Shadow
```

Runtime behavior:

1. scan eligible enemies within range;
2. choose a valid target;
3. aim the head or presentation toward that target;
4. wait until valid to fire;
5. spawn projectile at `MuzzlePoint`;
6. projectile travels to/through target according to its data;
7. impact applies damage and slow;
8. spawn splash VFX;
9. respect cooldown.

Turret target selection must not be recalculated unnecessarily every physics frame when a less frequent scan is sufficient.

Potential later evolutions include pressure, multi-directional spray, stronger slow and damage-over-time variants, but only the base Water Turret is required for the first milestone.

## 13. Wave Director

Waves are data-driven through `WaveData` rather than fully hand-scripted spawn sequences.

`WaveData` contains at minimum:

- duration or completion rule;
- threat budget;
- spawn interval or pacing parameters;
- enemy pool;
- elite chance;
- optional boss.

Enemy definitions expose `threat_cost`.

Illustrative costs:

- Raccoon: 1;
- Neighbor Kid: 3;
- Big Neighbor: 7;
- Elite variants: higher.

The Wave Director consumes a wave budget and produces pressure while respecting enemy eligibility and pacing constraints.

The first five waves should broadly escalate as:

1. raccoons;
2. raccoons + neighbor kids;
3. denser mix + first elite pressure;
4. big neighbors enter the mix;
5. high-pressure mix + mini-boss.

Exact quantities remain balancing data.

## 14. Progression and Upgrades

### 14.1 XP progression

Enemies drop XP pickups. Collecting XP fills a level bar.

On level-up:

- combat pauses safely;
- three valid upgrade cards are presented;
- player chooses one;
- upgrade is applied;
- combat resumes.

Upgrade categories:

- Weapon;
- Player;
- Defense;
- Utility;
- Rare / Evolution.

Each upgrade is a data resource with at least:

```text
id
title
description
icon
rarity
tags
max_level
effect definition
```

Tags are used to filter invalid choices. The game must not offer an upgrade for a system the player cannot currently use unless the card itself unlocks that system.

Example tags include:

- weapon;
- flip_flop;
- projectile;
- water;
- turret;
- player;
- base.

### 14.2 Coin progression

Coins are the controlled progression currency between waves.

Coins purchase base/defence improvements. XP choices remain randomized roguelike decisions. This keeps both randomness and strategic control in the same run.

## 15. Game Flow and State

The game has explicit flow states.

Core path:

```text
BOOT
→ WAVE_START
→ COMBAT
→ LEVEL_UP (temporary branch, then back to COMBAT)
→ WAVE_COMPLETE
→ SHOP / BASE_UPGRADE
→ NEXT_WAVE
```

Additional states:

- PAUSED;
- GAME_OVER.

State transitions must control whether enemies, projectiles and timers continue to simulate. Selecting an upgrade must not allow enemies to keep attacking in the background.

## 16. Data-Driven Design

Balance values belong in Godot `Resource` data whenever practical rather than being buried in behavior scripts.

Required data families:

- `WeaponData`;
- `EnemyData`;
- `UpgradeData`;
- `WaveData`;
- base upgrade data as needed.

The intent is that designers can rebalance damage, HP, costs, threat values, fire rates and progression through the Inspector without rewriting gameplay code.

## 17. Save Data

The first milestone saves only lightweight persistent state:

```text
settings
  volume
  fullscreen
  screen_shake

progress
  highest_wave
  currency
  unlocked_items
```

Saving and restoring an active run is intentionally out of scope for the first milestone.

Save loading must handle missing/corrupt optional fields by falling back to sensible defaults instead of preventing game startup.

## 18. Performance Constraints

Target: stable 60 FPS with roughly 100 simultaneously active regular enemies on the user's target PC class.

Avoid known scaling traps:

- no per-enemy `get_nodes_in_group()` every frame;
- no unnecessary `Timer` node per tiny repeated behavior when a lightweight accumulator suffices;
- no turret target rescan every physics tick when a lower scan frequency is enough;
- avoid excessive create/free churn for common projectiles and VFX.

Object pooling may be introduced for bullets, XP, hit VFX and splash effects if profiling shows it is useful. Do not add pooling solely for architectural fashion.

## 19. Testing Strategy

Every meaningful implementation stage must be checked at three levels.

### 19.1 Headless / structural check

Run Godot 4.7.2 headlessly to detect:

- parse errors;
- invalid scene/resource references;
- broken scripts;
- missing required resources;
- startup errors.

### 19.2 Gameplay smoke tests

At minimum, verify the complete player attack chain:

```text
spawn player
→ move
→ aim
→ fire
→ projectile starts at MuzzlePoint
→ projectile hits enemy
→ enemy takes damage
→ enemy dies
→ XP drops
→ XP can be collected
```

Verify Water Turret chain:

```text
enemy enters range
→ target selected
→ turret aims
→ projectile starts at turret MuzzlePoint
→ target receives damage + slow
→ splash effect appears
→ cooldown prevents illegal rapid fire
```

Verify game-flow chain:

```text
wave starts
→ combat progresses
→ XP level-up pauses combat
→ upgrade selection applies exactly once
→ combat resumes
→ wave completes
→ base upgrade phase opens
→ next wave starts
```

### 19.3 Visual QA

Inspect rendered gameplay for problems that code tests cannot prove:

- weapon detached from hand;
- projectile spawning from the wrong location;
- animation frame hopping;
- white halos or poorly removed backgrounds;
- incorrect ground anchors;
- broken Y-sort / roof overlap;
- misplaced shadows;
- clipped sprites;
- VFX covering important gameplay;
- unreadable HUD;
- movement/facing mismatch;
- turrets visibly shooting away from their target.

Any visual defect found during a milestone test is fixed and retested before the milestone is considered complete.

## 20. Error Handling and Resilience

Gameplay systems should fail safely where possible.

Examples:

- weapon with no valid target must simply wait rather than fire at an invalid reference;
- turret losing its target mid-aim must reacquire or return to idle safely;
- missing optional UI icon must not crash gameplay;
- invalid upgrade eligibility must remove the card from the candidate pool;
- no eligible upgrade candidates must fall back to a defined safe upgrade or currency reward;
- defeated/freed targets must not leave stale references in projectile or turret logic;
- spawn logic must avoid creating enemies inside invalid collision regions.

## 21. Input and Platform Baseline

Primary development target is desktop Godot 4.7.2.

Initial controls must support:

- keyboard movement;
- mouse aiming;
- mouse/keyboard firing as defined by the chosen combat mode;
- pause;
- upgrade/UI selection.

Gamepad support should be architecturally possible, but complete controller polish is not required before the first vertical slice unless implementation effort is low.

## 22. Quality Rules

1. Core gameplay objects remain editable Godot scenes; do not bake the entire level into one monolithic image.
2. Do not substitute primitive circles/capsules/gray boxes for required production visuals in the final vertical slice.
3. Projectiles must use explicit firing origins.
4. Sprite animations must preserve consistent pivots/ground anchors.
5. New systems should be modular and data-driven.
6. Prefer signals and explicit interfaces over deep scene-tree paths.
7. Use Godot 4.7-compatible APIs.
8. Every significant change is followed by appropriate structural, gameplay and visual checks.
9. Do not claim something was visually verified unless it was actually rendered/captured and inspected.
10. Fix regressions before layering major new features on top.

## 23. Vertical Slice Acceptance Criteria

The vertical slice is accepted only when all of the following are true:

- Godot 4.7.2 opens the project without parse/startup errors;
- the player spawns and moves correctly;
- aiming and firing are reliable;
- Flip-Flop Launcher projectiles visibly originate from its `MuzzlePoint`;
- all three regular enemy archetypes spawn and behave differently;
- enemies take damage, die and drop XP/coins as intended;
- Water Turret detects, aims, fires from its `MuzzlePoint`, damages and slows targets;
- the central base can take damage and can end the run when destroyed;
- player incapacitation/revival works without corrupting the run state;
- five waves progress correctly;
- wave 5 contains a mechanically distinct mini-boss;
- XP level-ups pause combat and show three valid choices;
- upgrades apply once and affect the intended system;
- between-wave coin spending improves the base/defence system;
- HUD shows player HP, base HP, XP, coins and wave state clearly;
- game-over and restart work repeatedly without stale state;
- supplied art has been cleaned/normalized for runtime use where required;
- no obvious white-background remnants, frame hopping, broken pivots or incorrect Y-sort remain;
- no major projectile/turret aiming mismatch remains;
- representative combat remains performant with approximately 100 regular enemies;
- the final scene visually reads as the approved comedic backyard concept rather than a placeholder prototype.

## 24. Tooling Workflow

Use connected development tools when they materially improve correctness or quality:

- **Godot 4.7.2 binary supplied by the user** for runtime/headless checks;
- **Context7** for current Godot 4.7 API verification;
- **GitHub** for source control and reviewable changes;
- **Superpowers** for implementation planning, TDD, debugging and verification workflows;
- **Game Development Studio** for asset/visual/performance workflows when its local CLI is available and authorized;
- **Figma** for UI/layout work when useful;
- **Meshy** only where a 3D source asset is genuinely needed;
- **DevMotion / GIF tooling** for preview/animation communication where useful, not as substitutes for in-engine verification.

Provider spend, credential use, external generation and destructive/write-sensitive tooling must follow their own explicit authorization boundaries.

## 25. Milestone Order

Implementation should progress in dependency order:

1. repository/project bootstrap and automated Godot structural check;
2. source asset inventory and normalization pipeline;
3. backyard level scene and sorting/depth rules;
4. player movement and animation foundation;
5. Flip-Flop Launcher projectile combat;
6. reusable health/hurt/damage components;
7. Raccoon enemy end-to-end;
8. Neighbor Kid and Big Neighbor variants;
9. XP/coins and pickup collection;
10. level-up and three-card upgrade flow;
11. base health and defeat condition;
12. Water Turret end-to-end;
13. Wave Director and five-wave data;
14. between-wave base upgrades;
15. mini-boss;
16. HUD, VFX, audio and visual polish;
17. stress/performance pass;
18. full regression and acceptance test pass.

Each stage must leave a runnable, testable project rather than relying on a large final integration step.
