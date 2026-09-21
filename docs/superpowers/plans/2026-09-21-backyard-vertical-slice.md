# Backyard Mayhem Vertical Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a polished five-wave playable vertical slice of Backyard Mayhem in Godot 4.7.2, using the supplied concept art and sprite-sheet archive, with one hero, Flip-Flop Launcher, three enemy archetypes, a Water Turret, a defended base, XP/coin progression, three-card upgrades, one mini-boss, HUD, save/settings support, and repeatable headless/gameplay/visual QA.

**Architecture:** Use editable 2D/2.5D Godot scenes with component-oriented GDScript, typed `Resource` data, signals for cross-system events, and a strict separation between gameplay state, presentation, and authored data. Every task leaves the project runnable and adds a headless test or smoke scenario before the next subsystem depends on it.

**Tech Stack:** Godot 4.7.2, GDScript, Godot `Resource` data, `CharacterBody2D`, `Area2D`, `AnimatedSprite2D`, `AnimationPlayer`, built-in `Image` processing for asset preparation, Git/GitHub.

**Spec:** `docs/superpowers/specs/2026-09-21-backyard-roguelike-design.md`

## Global Constraints

- Engine is Godot 4.7.2.
- Gameplay code is GDScript.
- Runtime presentation is true 2D/2.5D; do not convert the game into a fully 3D project.
- Core runtime objects remain editable Godot scenes; do not bake the playable yard into one screenshot.
- Moving actors use `CharacterBody2D.velocity` plus `move_and_slide()`.
- Cross-system integration uses signals and explicit references; no deep `get_node("../../../../...")` gameplay dependencies.
- Balance values live in typed `Resource` data wherever practical.
- Every weapon and turret uses an explicit `MuzzlePoint` for projectile spawning.
- Final vertical slice contains no crude placeholder geometry for core characters, enemies, base, weapon, Water Turret, or primary UI.
- Preserve original uploaded/source artwork under `assets/source/`; generated runtime frames are derivative outputs, never destructive edits of source files.
- Combat pauses safely during upgrade selection.
- Base HP reaching zero ends the run; player HP reaching zero temporarily incapacitates and later revives the player.
- Target is 60 FPS with roughly 100 active regular enemies on the target PC class.
- Mid-run save/resume, multiplayer, large campaign, freeform manual tower placement, and full meta-progression are outside this milestone.

## Review Focus

1. **Stale or deleted targets:** weapons and turrets must not crash or fire toward freed enemies; tests verify target invalidation before fire.
2. **Duplicate level-up application:** upgrade overlay applies exactly one selected upgrade and resumes combat exactly once.
3. **Corrupt/missing save fields:** startup recovers to defaults instead of failing.
4. **Projectile origin/facing drift:** tests assert spawned projectile global position equals the active `MuzzlePoint` transform within tolerance; visual QA verifies sprite alignment.
5. **Wave completion edge cases:** waves complete only when spawning is exhausted and required live enemies/bosses are cleared; tests cover a boss surviving after the spawn budget is spent.

---

## File Map

```text
project.godot
.gitignore
README.md

tools/
  process_sprite_sheets.gd
  asset_manifest.json

tests/
  run_all.gd
  test_utils.gd
  test_data_resources.gd
  test_health_component.gd
  test_player_movement.gd
  test_projectile_weapon.gd
  test_enemy_ai.gd
  test_upgrade_system.gd
  test_water_turret.gd
  test_wave_director.gd
  test_game_flow.gd
  test_save_service.gd
  perf_enemy_swarm.gd

assets/
  source/
  characters/
  enemies/
  weapons/
  defenses/
  environment/
  ui/
  vfx/
  audio/

scripts/components/
  health_component.gd
  hurtbox_component.gd
  damage_component.gd
  movement_component.gd
  pickup_collector.gd

scripts/data/
  weapon_data.gd
  enemy_data.gd
  upgrade_data.gd
  wave_data.gd
  base_upgrade_data.gd

scripts/player/
  player.gd
  aim_controller.gd
  weapon_controller.gd

scripts/weapons/
  projectile.gd
  flip_flop_launcher.gd

scripts/enemies/
  enemy.gd
  enemy_ai.gd
  ranged_enemy_ai.gd
  miniboss_ai.gd

scripts/defenses/
  water_turret.gd
  water_projectile.gd
  base_controller.gd

scripts/pickups/
  xp_pickup.gd
  coin_pickup.gd

scripts/systems/
  progression_system.gd
  upgrade_system.gd
  spawn_manager.gd
  wave_director.gd
  game_flow.gd
  save_service.gd

scripts/ui/
  hud.gd
  upgrade_overlay.gd
  between_wave_shop.gd
  game_over_screen.gd

scripts/levels/
  backyard_controller.gd

scenes/player/player.tscn
scenes/weapons/flip_flop_projectile.tscn
scenes/weapons/flip_flop_launcher.tscn
scenes/enemies/raccoon.tscn
scenes/enemies/neighbor_kid.tscn
scenes/enemies/big_neighbor.tscn
scenes/enemies/miniboss.tscn
scenes/defenses/base.tscn
scenes/defenses/water_turret.tscn
scenes/defenses/water_projectile.tscn
scenes/pickups/xp_pickup.tscn
scenes/pickups/coin_pickup.tscn
scenes/ui/hud.tscn
scenes/ui/upgrade_overlay.tscn
scenes/ui/between_wave_shop.tscn
scenes/ui/game_over_screen.tscn
scenes/levels/backyard.tscn

data/weapons/flip_flop_launcher.tres
data/enemies/raccoon.tres
data/enemies/neighbor_kid.tres
data/enemies/big_neighbor.tres
data/enemies/miniboss.tres
data/upgrades/double_trouble.tres
data/upgrades/angry_flip_flop.tres
data/upgrades/garden_pressure.tres
data/base_upgrades/unlock_water_turret.tres
data/base_upgrades/reinforced_walls.tres
data/base_upgrades/turret_pressure.tres
data/waves/wave_01.tres
data/waves/wave_02.tres
data/waves/wave_03.tres
data/waves/wave_04.tres
data/waves/wave_05.tres

docs/qa/vertical-slice-checklist.md
```

---

### Task 1: Bootstrap Godot project and deterministic test harness

**Files:**
- Create: `project.godot`
- Create: `.gitignore`
- Create: `README.md`
- Create: `tests/run_all.gd`
- Create: `tests/test_utils.gd`

**Interfaces:**
- Produces: `tests/run_all.gd` executable with Godot `--headless --script`; `TestUtils.assert_true`, `assert_eq`, `assert_near`.
- Consumes: the provided Godot 4.7.2 Linux binary during execution; the binary itself is not committed.

- [ ] **Step 1: Create minimal project configuration and exact input actions**

Set main scene to `res://scenes/levels/backyard.tscn`, viewport 1280×720, stretch mode `canvas_items`, and GL compatibility renderer. Define `move_left=A`, `move_right=D`, `move_up=W`, `move_down=S`, `fire=Mouse Button Left`, `pause=Escape` in `project.godot` so no editor setup is required.

Initial header:

```ini
[application]
config/name="Backyard Mayhem"
run/main_scene="res://scenes/levels/backyard.tscn"

[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"

[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
```

- [ ] **Step 2: Create dependency-free headless assertions**

`tests/test_utils.gd`:

```gdscript
class_name TestUtils
extends RefCounted

static var failures: Array[String] = []

static func reset() -> void:
    failures.clear()

static func assert_true(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)

static func assert_eq(actual: Variant, expected: Variant, message: String) -> void:
    if actual != expected:
        failures.append("%s | actual=%s expected=%s" % [message, actual, expected])

static func assert_near(actual: float, expected: float, epsilon: float, message: String) -> void:
    if absf(actual - expected) > epsilon:
        failures.append("%s | actual=%f expected=%f" % [message, actual, expected])
```

`tests/run_all.gd` extends `SceneTree`, enumerates `res://tests/test_*.gd` except `test_utils.gd`, instantiates each script, awaits `run()` when it returns a signal/coroutine, prints every failure, and exits `1` on any failure and `0` otherwise.

- [ ] **Step 3: Run the empty harness**

```bash
$GODOT_BIN --headless --path . --script res://tests/run_all.gd
```

Expected: exit code `0`, summary `0 failures`.

- [ ] **Step 4: Add repository hygiene**

`.gitignore`:

```gitignore
.godot/
.tools/
*.tmp
*.log
.DS_Store
```

`README.md` documents Godot 4.7.2, the headless test command, and the source/derived asset split.

- [ ] **Step 5: Commit**

```bash
git add project.godot .gitignore README.md tests
git commit -m "chore: bootstrap Godot project and test harness"
```

---

### Task 2: Ingest supplied art and build repeatable sprite-sheet processing

**Files:**
- Create: `tools/process_sprite_sheets.gd`
- Create: `tools/asset_manifest.json`
- Create/populate: `assets/source/`, `assets/characters/`, `assets/enemies/`, `assets/weapons/`, `assets/defenses/`, `assets/environment/`, `assets/ui/`, `assets/vfx/`
- Create: `assets/source/SOURCE_HASHES.txt`
- Create: `assets/processing_report.json`

**Interfaces:**
- Consumes: PNG source sheets extracted from the supplied archive into `assets/source/`.
- Produces: transparent, padded, anchor-stable PNG frame sequences and processing metadata.

- [ ] **Step 1: Extract source archive without modifying source bytes**

Extract every original PNG under `assets/source/`; preserve the exact original filename. Record SHA-256 hashes:

```bash
find assets/source -type f -iname '*.png' -print0 | sort -z | xargs -0 sha256sum > assets/source/SOURCE_HASHES.txt
```

- [ ] **Step 2: Build the manifest from discovered exact filenames**

`tools/process_sprite_sheets.gd -- --index-only` scans `assets/source/` with `DirAccess`, sorts filenames deterministically, classifies known sheets by lowercase keyword rules (`hero`, `raccoon`, `neighbor`, `turret`, `water`, `flip`, `upgrade`, `yard/backyard`), and writes `tools/asset_manifest.json`. Unclassified files are written with category `review_required` and cause index mode to exit `2`, forcing explicit classification before processing.

Each resolved manifest entry contains exact `source`, `output_dir`, `prefix`, `min_component_area`, `white_threshold`, `padding`, and `anchor`. No manual crop rectangles are stored.

- [ ] **Step 3: Implement background removal and connected-component extraction with Godot `Image`**

For each manifest entry:

1. load with `Image.load_from_file()`;
2. convert pixels with R/G/B each >= `white_threshold / 255.0` to alpha 0;
3. flood-fill 4-connected nontransparent components;
4. discard components below `min_component_area`;
5. sort remaining components top-to-bottom then left-to-right by center;
6. crop with configured padding;
7. normalize all frames in that sheet to the sheet maximum width/height;
8. place using `bottom_center` anchor;
9. save `prefix_000.png`, `prefix_001.png`, etc.;
10. write bounds/dimensions/warnings to `assets/processing_report.json`.

Exit non-zero if any classified sheet produces zero usable frames.

- [ ] **Step 4: Run indexing then processing**

```bash
$GODOT_BIN --headless --path . --script res://tools/process_sprite_sheets.gd -- --index-only
$GODOT_BIN --headless --path . --script res://tools/process_sprite_sheets.gd -- --process
```

Expected: all required core categories classified, no white background, stable frame canvas dimensions per animation set.

- [ ] **Step 5: Visual QA generated hero/enemy/weapon/turret/VFX/UI frames**

Reject and reprocess any set with white halos, cropped limbs, text fragments, inconsistent ground anchor, or obvious frame ordering mistakes.

- [ ] **Step 6: Commit**

```bash
git add tools assets
git commit -m "art: ingest and normalize supplied sprite assets"
```

---

### Task 3: Add typed gameplay data resources

**Files:**
- Create: `scripts/data/weapon_data.gd`
- Create: `scripts/data/enemy_data.gd`
- Create: `scripts/data/upgrade_data.gd`
- Create: `scripts/data/wave_data.gd`
- Create: `scripts/data/base_upgrade_data.gd`
- Create: `data/weapons/flip_flop_launcher.tres`
- Create: `data/enemies/raccoon.tres`
- Create: `data/enemies/neighbor_kid.tres`
- Create: `data/enemies/big_neighbor.tres`
- Create: `tests/test_data_resources.gd`

**Interfaces:**
- Produces: typed `WeaponData`, `EnemyData`, `UpgradeData`, `WaveData`, `BaseUpgradeData`.

- [ ] **Step 1: Define `WeaponData`**

```gdscript
class_name WeaponData
extends Resource

@export var damage: float = 18.0
@export var fire_rate: float = 2.2
@export var projectile_speed: float = 720.0
@export var projectile_count: int = 1
@export var spread_degrees: float = 3.0
@export var pierce: int = 0
@export var knockback: float = 120.0
@export_range(0.0, 1.0) var crit_chance: float = 0.05
@export var projectile_scale: float = 1.0
```

- [ ] **Step 2: Define other resource contracts**

`EnemyData`: `max_health`, `move_speed`, `contact_damage`, `threat_cost`, `coin_drop`, `xp_drop`, `target_priority`.

`UpgradeData`: `id`, `title`, `description`, `icon`, `rarity`, `tags`, `max_level`, `effect_key`, `magnitude`.

`WaveData`: `wave_index`, `threat_budget`, `spawn_interval`, `enemy_pool: Array[EnemyData]`, `elite_chance`, `boss_scene`.

`BaseUpgradeData`: `id`, `title`, `cost`, `max_level`, `effect_key`, `magnitude`.

- [ ] **Step 3: Author initial balance resources**

```text
Raccoon:      HP 24, speed 165, contact 8, threat 1, XP 3, coins 1
Neighbor Kid: HP 55, speed 105, contact 10, threat 3, XP 7, coins 2
Big Neighbor: HP 180, speed 58, contact 22, threat 7, XP 16, coins 5
```

Flip-Flop Launcher uses the `WeaponData` defaults above.

- [ ] **Step 4: Write and run `test_data_resources.gd`**

Assert each `.tres` loads, positive values are positive, threat cost is at least 1, and invalid empty IDs are rejected by validation helpers.

```bash
$GODOT_BIN --headless --path . --script res://tests/run_all.gd
```

- [ ] **Step 5: Commit**

```bash
git add scripts/data data tests/test_data_resources.gd
git commit -m "feat: add typed gameplay data resources"
```

---

### Task 4: Implement reusable health, hurtbox and damage components

**Files:**
- Create: `scripts/components/health_component.gd`
- Create: `scripts/components/hurtbox_component.gd`
- Create: `scripts/components/damage_component.gd`
- Create: `tests/test_health_component.gd`

**Interfaces:**
- Produces: `HealthComponent.damage(amount, source := null)`, `heal(amount)`, `reset()`, signals `health_changed(current, maximum)`, `died(source)`; `HurtboxComponent.receive_hit(amount, knockback, source)`.

- [ ] **Step 1: Write failing tests** for damage clamping, healing clamping, one `died` emission, and damage ignored after death.

```gdscript
var health := HealthComponent.new()
health.max_health = 100.0
health.reset()
health.damage(35.0)
TestUtils.assert_near(health.current_health, 65.0, 0.001, "damage reduces health")
```

- [ ] **Step 2: Run and confirm expected failure**

```bash
$GODOT_BIN --headless --path . --script res://tests/run_all.gd
```

- [ ] **Step 3: Implement `HealthComponent`** as a `Node` with exported `max_health`, runtime `current_health`, explicit `reset()`, internal dead flag, and a one-shot death signal.

- [ ] **Step 4: Implement hurtbox/damage bridge**

`HurtboxComponent` forwards validated positive damage to an exported `HealthComponent`. `DamageComponent` stores contact damage and a cooldown accumulator so sustained overlap cannot damage every physics tick.

- [ ] **Step 5: Run tests and commit**

```bash
$GODOT_BIN --headless --path . --script res://tests/run_all.gd
git add scripts/components tests/test_health_component.gd
git commit -m "feat: add reusable combat health components"
```

---

### Task 5: Build player movement, aiming and scene structure

**Files:**
- Create: `scripts/components/movement_component.gd`
- Create: `scripts/player/player.gd`
- Create: `scripts/player/aim_controller.gd`
- Create: `scenes/player/player.tscn`
- Create: `tests/test_player_movement.gd`

**Interfaces:**
- Produces: `AimController.get_aim_direction() -> Vector2`, `AimController.get_target() -> Node2D`, `Player.set_controls_enabled(enabled: bool)`.
- Consumes: `HealthComponent` and processed player animation assets.

- [ ] **Step 1: Write tests** for normalized diagonal input, controls disabled => zero velocity, explicit aim priority, and freed auto-target => null/reacquire without invalid access.

- [ ] **Step 2: Implement movement**

```gdscript
var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
body.velocity = input_dir * move_speed
body.move_and_slide()
```

The component receives its owning `CharacterBody2D`; no scene-tree search every frame.

- [ ] **Step 3: Implement hybrid aim controller**

Mouse/global cursor direction wins when explicit aim is present. Otherwise select nearest valid candidate from a cached `Area2D` candidate set. Validate with `is_instance_valid()` immediately before returning a target.

- [ ] **Step 4: Assemble `player.tscn`**

Root `CharacterBody2D` children: `VisualRoot`, `AnimatedSprite2D`, `Shadow`, `CollisionShape2D`, `HealthComponent`, `Hurtbox`, `AimArea`, `AimController`, `WeaponMount`, `PickupArea`.

- [ ] **Step 5: Run tests and scene-load check**

```bash
$GODOT_BIN --headless --path . --script res://tests/run_all.gd
$GODOT_BIN --headless --path . --editor --quit
```

- [ ] **Step 6: Commit**

```bash
git add scripts/components/movement_component.gd scripts/player scenes/player tests/test_player_movement.gd
git commit -m "feat: add player movement and hybrid aiming"
```

---

### Task 6: Implement projectile system and Flip-Flop Launcher

**Files:**
- Create: `scripts/weapons/projectile.gd`
- Create: `scripts/player/weapon_controller.gd`
- Create: `scripts/weapons/flip_flop_launcher.gd`
- Create: `scenes/weapons/flip_flop_projectile.tscn`
- Create: `scenes/weapons/flip_flop_launcher.tscn`
- Create: `tests/test_projectile_weapon.gd`

**Interfaces:**
- Produces: `Projectile.launch(origin, direction, speed, damage, pierce, knockback)`, `WeaponController.try_fire()`, signal `shot_fired(projectile)`.
- Consumes: `WeaponData`, `AimController`, `MuzzlePoint`.

- [ ] **Step 1: Write failing tests** for exact muzzle origin, fire cadence, symmetric spread, and stale target handling.

Create a test weapon root with `Marker2D` at `(32, -8)`; after `try_fire()`, projectile global position must match within `0.01`.

- [ ] **Step 2: Implement projectile motion/hit**

Projectile is an `Area2D`; `_physics_process(delta)` advances `global_position += direction * speed * delta`. Compatible hurtbox overlap applies damage/knockback, decrements pierce, and frees when exhausted. Zero-length launch direction is rejected.

- [ ] **Step 3: Implement fire cadence** using a float accumulator: interval `1.0 / maxf(data.fire_rate, 0.01)`.

- [ ] **Step 4: Spawn every projectile from `MuzzlePoint.global_position`** and distribute multi-projectile spread symmetrically around aim angle.

- [ ] **Step 5: Add Flip-Flop presentation** using processed art; rotate/tumble sprite while collision remains independent.

- [ ] **Step 6: Test, visually fire at a stationary dummy, commit**

```bash
$GODOT_BIN --headless --path . --script res://tests/run_all.gd
git add scripts/weapons scripts/player/weapon_controller.gd scenes/weapons tests/test_projectile_weapon.gd
git commit -m "feat: add Flip-Flop Launcher and projectile combat"
```

---

### Task 7: Implement three enemy archetypes and drops

**Files:**
- Create: `scripts/enemies/enemy.gd`
- Create: `scripts/enemies/enemy_ai.gd`
- Create: `scripts/enemies/ranged_enemy_ai.gd`
- Create: `scripts/pickups/xp_pickup.gd`
- Create: `scripts/pickups/coin_pickup.gd`
- Create: `scenes/enemies/raccoon.tscn`
- Create: `scenes/enemies/neighbor_kid.tscn`
- Create: `scenes/enemies/big_neighbor.tscn`
- Create: `scenes/pickups/xp_pickup.tscn`
- Create: `scenes/pickups/coin_pickup.tscn`
- Create: `tests/test_enemy_ai.gd`

**Interfaces:**
- Produces: `Enemy.configure(data: EnemyData)`, signal `enemy_died(enemy, world_position, xp_amount, coin_amount)`; pickups signal `collected(value)`.
- Consumes: player/base target nodes, `EnemyData`, combat components.

- [ ] **Step 1: Write AI intent tests**: Raccoon selects player, Big Neighbor prefers base, Neighbor Kid maintains ranged band; freed targets reacquire safely.

- [ ] **Step 2: Implement shared AI think cadence** at 0.1 s while movement uses the last desired direction every physics frame. No per-frame global group query.

- [ ] **Step 3: Implement archetype behavior**

Raccoon: fast chase/contact pressure. Neighbor Kid: ranged-band movement and periodic nuisance projectile. Big Neighbor: slow base-first tank with heavy contact damage.

- [ ] **Step 4: Emit death payload once**; level layer owns XP/coin scene spawning. Enemy code never accesses HUD/progression paths.

- [ ] **Step 5: Assemble scenes with processed artwork, soft shadows, collisions, stable anchors and idle/run/hurt animations**.

- [ ] **Step 6: Run tests plus 20-enemy smoke scenario, commit**

```bash
$GODOT_BIN --headless --path . --script res://tests/run_all.gd
git add scripts/enemies scripts/pickups scenes/enemies scenes/pickups tests/test_enemy_ai.gd
git commit -m "feat: add enemy archetypes and loot drops"
```

---

### Task 8: Add XP, coins and three-choice roguelike upgrades

**Files:**
- Create: `scripts/components/pickup_collector.gd`
- Create: `scripts/systems/progression_system.gd`
- Create: `scripts/systems/upgrade_system.gd`
- Create: `scripts/ui/upgrade_overlay.gd`
- Create: `scenes/ui/upgrade_overlay.tscn`
- Create: `data/upgrades/double_trouble.tres`
- Create: `data/upgrades/angry_flip_flop.tres`
- Create: `data/upgrades/garden_pressure.tres`
- Create: `tests/test_upgrade_system.gd`

**Interfaces:**
- Produces: `ProgressionSystem.add_xp(amount)`, `add_coins(amount)`, signal `level_ready(level)`; `UpgradeSystem.get_choices(count)`, `apply_upgrade(data)`.
- Consumes: active player/weapon/defense tags.

- [ ] **Step 1: Write tests** for XP thresholds, XP overflow, unique valid choices, turret-tag filtering, and exactly-once selection application.

- [ ] **Step 2: Implement XP threshold** `required_xp = 12 + (level - 1) * 8`; carry overflow; coins are non-negative integers.

- [ ] **Step 3: Implement initial upgrades**

```text
DOUBLE TROUBLE: projectile_count_add +1
ANGRY FLIP-FLOP: weapon_damage_mult 1.25
GARDEN PRESSURE: turret_fire_rate_mult 1.25, requires turret tag
```

- [ ] **Step 4: Build overlay** with three icon/title/description cards. Disable all card buttons immediately after first valid selection and emit chosen `UpgradeData` once.

- [ ] **Step 5: Run tests and commit**

```bash
$GODOT_BIN --headless --path . --script res://tests/run_all.gd
git add scripts/components/pickup_collector.gd scripts/systems/progression_system.gd scripts/systems/upgrade_system.gd scripts/ui/upgrade_overlay.gd scenes/ui/upgrade_overlay.tscn data/upgrades tests/test_upgrade_system.gd
git commit -m "feat: add roguelike progression and upgrade choices"
```

---

### Task 9: Build central base and Water Turret defense

**Files:**
- Create: `scripts/defenses/base_controller.gd`
- Create: `scripts/defenses/water_turret.gd`
- Create: `scripts/defenses/water_projectile.gd`
- Create: `scenes/defenses/base.tscn`
- Create: `scenes/defenses/water_turret.tscn`
- Create: `scenes/defenses/water_projectile.tscn`
- Create: `data/base_upgrades/unlock_water_turret.tres`
- Create: `data/base_upgrades/reinforced_walls.tres`
- Create: `data/base_upgrades/turret_pressure.tres`
- Create: `tests/test_water_turret.gd`

**Interfaces:**
- Produces: `BaseController.apply_upgrade(data)`, `WaterTurret.set_enabled(value)`, signal `base_destroyed`; water projectile applies damage plus slow.
- Consumes: enemy candidates, health component, progression coins.

- [ ] **Step 1: Write turret tests** covering nearest target, freed target before fire, cooldown, exact MuzzlePoint origin, slow application, and disabled turret.

- [ ] **Step 2: Implement candidate caching** from `DetectionArea` enter/exit and rescore every 0.15 s, not every physics tick.

- [ ] **Step 3: Implement water projectile**: apply damage and slowdown to compatible enemy; non-slowable target still receives damage; splash VFX emitted by signal.

- [ ] **Step 4: Implement base upgrades**

`unlock_water_turret`: cost 20, max level 1, enables turret. `reinforced_walls`: cost 25, max level 3, adds 50 max HP per level. `turret_pressure`: cost 30, max level 3, multiplies Water Turret fire rate by 1.15 per level. Purchase refuses insufficient coins.

- [ ] **Step 5: Integrate processed Water Turret/splash art** and visually confirm water originates from nozzle.

- [ ] **Step 6: Run tests and commit**

```bash
$GODOT_BIN --headless --path . --script res://tests/run_all.gd
git add scripts/defenses scenes/defenses data/base_upgrades tests/test_water_turret.gd
git commit -m "feat: add defended base and Water Turret"
```

---

### Task 10: Implement Spawn Manager and five-wave threat-budget director

**Files:**
- Create: `scripts/systems/spawn_manager.gd`
- Create: `scripts/systems/wave_director.gd`
- Create: `data/waves/wave_01.tres`
- Create: `data/waves/wave_02.tres`
- Create: `data/waves/wave_03.tres`
- Create: `data/waves/wave_04.tres`
- Create: `data/waves/wave_05.tres`
- Create: `tests/test_wave_director.gd`

**Interfaces:**
- Produces: `WaveDirector.start_wave(data)`, signals `enemy_spawn_requested(enemy_data)`, `wave_finished(index)`; `SpawnManager.spawn_enemy(data, position)`.

- [ ] **Step 1: Write tests** for budget cap, eligibility, spawn exhaustion, deterministic seeded choices, and boss-survives-budget edge case.

- [ ] **Step 2: Implement seeded budget spending** using injected `RandomNumberGenerator`; choose only enemy data with `threat_cost <= remaining_budget`; when none fit, stop spawning and wait for live enemies.

- [ ] **Step 3: Author wave resources**

```text
Wave 1: budget 18, interval 0.85, raccoon
Wave 2: budget 32, interval 0.72, raccoon + neighbor kid
Wave 3: budget 48, interval 0.62, raccoon + neighbor kid, elite chance 0.08
Wave 4: budget 68, interval 0.55, all regular enemies, elite chance 0.12
Wave 5: budget 85, interval 0.50, all regular enemies + miniboss scene
```

- [ ] **Step 4: Spawn-point policy**: reject points inside player/base collision or camera-safe radius; if preferred points are blocked, choose farthest valid configured point.

- [ ] **Step 5: Run tests and commit**

```bash
$GODOT_BIN --headless --path . --script res://tests/run_all.gd
git add scripts/systems/spawn_manager.gd scripts/systems/wave_director.gd data/waves tests/test_wave_director.gd
git commit -m "feat: add threat-budget wave director"
```

---

### Task 11: Implement explicit game flow, HUD, between-wave shop and game over

**Files:**
- Create: `scripts/systems/game_flow.gd`
- Create: `scripts/ui/hud.gd`
- Create: `scripts/ui/between_wave_shop.gd`
- Create: `scripts/ui/game_over_screen.gd`
- Create: `scenes/ui/hud.tscn`
- Create: `scenes/ui/between_wave_shop.tscn`
- Create: `scenes/ui/game_over_screen.tscn`
- Create: `tests/test_game_flow.gd`

**Interfaces:**
- Produces enum `GameFlow.State { BOOT, WAVE_START, COMBAT, LEVEL_UP, WAVE_COMPLETE, SHOP, PAUSED, GAME_OVER }`, `transition_to(next_state)`, signal `state_changed(previous, current)`.

- [ ] **Step 1: Write transition tests** for normal wave path, LEVEL_UP returning once to COMBAT, GAME_OVER blocking combat transitions, and player death not causing game over.

- [ ] **Step 2: Implement simulation gating** via explicit `simulation_enabled` signals; UI remains processable during LEVEL_UP. Avoid using `get_tree().paused` as the only control mechanism.

- [ ] **Step 3: Build HUD** for player HP, base HP, XP, level, coins, wave; update by signals rather than frame polling.

- [ ] **Step 4: Build shop** for the three base upgrades; purchase validates coins and max level before applying.

- [ ] **Step 5: Implement player incapacity/revive and base game-over**; restart reloads a clean run scene.

- [ ] **Step 6: Run tests and commit**

```bash
$GODOT_BIN --headless --path . --script res://tests/run_all.gd
git add scripts/systems/game_flow.gd scripts/ui scenes/ui tests/test_game_flow.gd
git commit -m "feat: add game flow and core UI"
```

---

### Task 12: Assemble editable Backyard level and integrate final core art

**Files:**
- Create: `scripts/levels/backyard_controller.gd`
- Create: `scenes/levels/backyard.tscn`
- Modify: `project.godot`
- Populate approved runtime art in `assets/environment/`, `assets/characters/`, `assets/enemies/`, `assets/weapons/`, `assets/defenses/`, `assets/vfx/`

**Interfaces:**
- Consumes all gameplay scenes/systems.
- Produces first fully playable scene and composition-root signal wiring.

- [ ] **Step 1: Build hierarchy**

```text
Backyard (Node2D)
├── Ground
├── Environment
├── Base
├── Actors (Node2D, y_sort_enabled=true)
│   ├── Player
│   ├── Enemies
│   ├── Defenses
│   └── Pickups
├── Projectiles
├── VFX
├── SpawnPoints
├── Systems
│   ├── ProgressionSystem
│   ├── UpgradeSystem
│   ├── SpawnManager
│   ├── WaveDirector
│   └── GameFlow
└── HUD (CanvasLayer)
```

- [ ] **Step 2: Reconstruct concept layout as editable layers**: ground, base/house, shed/fence/bush/tree props and foreground occluders separately. Use Y-sort for actors and authored z-index for roof/foreground.

- [ ] **Step 3: Add collisions/playable bounds** with explicit shapes matching walkable silhouettes; spawn points sit near perimeter approaches.

- [ ] **Step 4: Wire signals only in `backyard_controller.gd`**

Connect enemy death → drop spawn; pickup → progression; level ready → upgrade overlay/GameFlow; base destroyed → GAME_OVER; wave finished → SHOP; shop continue → next wave; restart → scene reload. No alternative editor-only wiring path is used for these core integrations.

- [ ] **Step 5: Run complete 5-minute smoke playthrough** across movement, aim, combat, three enemies, XP/coins, level-up, turret, base damage, wave progression and shop.

- [ ] **Step 6: Visual QA against concept** for Y-sort, ground anchors, weapon hand alignment, muzzle origin, white halos, clipping, VFX scale, HUD readability, actor scale consistency and foreground occlusion.

- [ ] **Step 7: Commit**

```bash
git add scripts/levels scenes/levels project.godot assets/environment assets/characters assets/enemies assets/weapons assets/defenses assets/vfx
git commit -m "feat: assemble playable backyard level"
```

---

### Task 13: Add resilient settings/progress saves

**Files:**
- Create: `scripts/systems/save_service.gd`
- Create: `tests/test_save_service.gd`

**Interfaces:**
- Produces: `SaveService.load_data(path := default_path) -> Dictionary`, `save_data(data, path := default_path) -> Error`, `defaults() -> Dictionary`.

- [ ] **Step 1: Write tests** for missing file, missing `screen_shake`, wrong currency type, malformed JSON.

- [ ] **Step 2: Implement versioned JSON default**

```json
{
  "version": 1,
  "settings": {"volume": 1.0, "fullscreen": false, "screen_shake": true},
  "progress": {"highest_wave": 0, "currency": 0, "unlocked_items": []}
}
```

Validate each field independently and fall back per field rather than rejecting the entire save when only one optional field is wrong.

- [ ] **Step 3: Apply settings at startup and save highest wave/currency/unlocks on game over; do not save active run state.**

- [ ] **Step 4: Run tests and commit**

```bash
$GODOT_BIN --headless --path . --script res://tests/run_all.gd
git add scripts/systems/save_service.gd tests/test_save_service.gd
git commit -m "feat: add resilient save and settings service"
```

---

### Task 14: Add Wave 5 mini-boss

**Files:**
- Create: `scripts/enemies/miniboss_ai.gd`
- Create: `scenes/enemies/miniboss.tscn`
- Create: `data/enemies/miniboss.tres`
- Modify: `data/waves/wave_05.tres`
- Modify: `tests/test_enemy_ai.gd`
- Modify: `tests/test_wave_director.gd`

**Interfaces:**
- Produces boss with normal `Enemy` health/death contract plus at least two readable attack states.

- [ ] **Step 1: Add tests**: boss is not spent as a regular threat-budget spawn, wave 5 waits while boss lives, boss reacquires a valid objective when player is incapacitated.

- [ ] **Step 2: Implement two-state boss behavior**

State A: slow pursuit with telegraphed heavy ground/contact attack. State B: brief stop plus clearly telegraphed fan/radial nuisance attack. State changes use cooldown plus health threshold, not per-frame randomness.

- [ ] **Step 3: Add bespoke presentation**: distinct processed sprite/scale, boss HP bar, stronger readable VFX; do not reuse Big Neighbor with only multiplied HP.

- [ ] **Step 4: Run wave-5 smoke test and commit**

```bash
$GODOT_BIN --headless --path . --script res://tests/run_all.gd
git add scripts/enemies/miniboss_ai.gd scenes/enemies/miniboss.tscn data/enemies/miniboss.tres data/waves/wave_05.tres tests/test_enemy_ai.gd tests/test_wave_director.gd
git commit -m "feat: add wave five mini-boss"
```

---

### Task 15: Performance pass, regression and acceptance gate

**Files:**
- Create: `tests/perf_enemy_swarm.gd`
- Create: `docs/qa/vertical-slice-checklist.md`
- Modify only gameplay files proven by profiling/QA to need correction

**Interfaces:**
- Consumes the complete vertical slice.
- Produces documented automated, performance and visual QA evidence.

- [ ] **Step 1: Run full headless regression**

```bash
$GODOT_BIN --headless --path . --script res://tests/run_all.gd
$GODOT_BIN --headless --path . --editor --quit
```

Expected: exit code 0, no parse/startup/resource errors.

- [ ] **Step 2: Run 100-enemy stress scenario**

`tests/perf_enemy_swarm.gd` loads gameplay, spawns 100 regular enemies, runs fixed 30 seconds, and reports average/max physics-frame time and active node count. Sustained physics time above 16.67 ms on target PC triggers profiling.

- [ ] **Step 3: Profile only measured hotspots** in AI think cadence, target scanning, projectile/VFX churn and collision breadth. Introduce pooling only if churn is proven material.

- [ ] **Step 4: Complete acceptance playthrough and record each item in `docs/qa/vertical-slice-checklist.md`**

```text
player spawns and moves
manual aim and soft auto-target work
Flip-Flop projectile starts at MuzzlePoint
three enemies are behaviorally distinct
player damage/incapacity/revive works
base damage and base game-over work
XP and coin drops collect correctly
level-up pauses combat
three valid upgrade cards appear
upgrade applies exactly once
Water Turret targets, aims and fires from nozzle
water applies damage + slow
five waves progress correctly
between-wave shop spends coins safely
wave 5 mini-boss is distinct and gates completion
restart begins a clean run
save corruption falls back safely
```

- [ ] **Step 5: Capture representative gameplay frames** for player firing, crowded combat, turret firing, upgrade overlay and boss; inspect every visual failure class in the spec and fix/retest failures.

- [ ] **Step 6: Final regression**: rerun all tests, editor-load check, stress scenario and one full five-wave playthrough.

- [ ] **Step 7: Commit evidence and fixes**

```bash
git add tests/perf_enemy_swarm.gd docs/qa
git add -u
git commit -m "test: complete vertical slice acceptance pass"
```

---

## Execution Order and Gates

Execute Tasks 1–15 in order. A task completes only when its automated test and stated gameplay/visual check pass. Do not carry known failures into the next task.

Per-task loop:

```text
write/extend failing test
→ run and confirm expected failure
→ implement minimal correct behavior
→ run automated tests
→ run task-specific gameplay/visual smoke check
→ fix defects
→ rerun
→ commit
```

## Final Self-Review

- Spec coverage: every vertical-slice requirement maps to Tasks 1–15.
- Placeholder scan: no TBD/TODO/fill-in-later instructions remain; source filenames are discovered deterministically from the supplied archive at execution time instead of being guessed in this plan.
- Type/interface consistency: data contracts precede consumers; `MuzzlePoint`, enemy death payload, progression, game-flow states and save-service signatures are used consistently.
- Review Focus coverage: stale targets (Tasks 5/6/9), duplicate upgrade application (Tasks 8/11), corrupt saves (Task 13), muzzle origin (Tasks 6/9), wave/boss completion (Tasks 10/14).
- Visual QA occurs at asset ingestion, level assembly and final acceptance instead of being deferred only to the end.
- Performance work is evidence-driven after a 100-enemy baseline.
