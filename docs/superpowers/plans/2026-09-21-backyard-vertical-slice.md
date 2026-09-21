# Backyard Mayhem Vertical Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a polished five-wave playable vertical slice of Backyard Mayhem in Godot 4.7.2, using the supplied concept art and sprite-sheet archive, with one hero, Flip-Flop Launcher, three enemy archetypes, a Water Turret, a defended base, XP/coin progression, three-card upgrades, one mini-boss, HUD, save/settings support, and repeatable headless/gameplay/visual QA.

**Architecture:** Use editable 2D/2.5D Godot scenes with component-oriented GDScript, data stored in typed `Resource` classes, signals for cross-system events, and a strict separation between gameplay state, presentation, and authored data. Every task leaves the project runnable and adds a headless test or smoke scenario before the next subsystem depends on it.

**Tech Stack:** Godot 4.7.2, GDScript, Godot `Resource` data, `CharacterBody2D`, `Area2D`, `AnimatedSprite2D`, `AnimationPlayer`, built-in `Image` processing for asset preparation, Git/GitHub.

**Spec:** `docs/superpowers/specs/2026-09-21-backyard-roguelike-design.md`

## Global Constraints

- Engine is Godot 4.7.2.
- Gameplay code is GDScript.
- Runtime presentation is true 2D/2.5D; do not convert the game into a fully 3D project.
- Core runtime objects must remain editable Godot scenes; do not bake the playable yard into one screenshot.
- Use `CharacterBody2D.velocity` plus `move_and_slide()` for moving actors.
- Cross-system integration uses signals and explicit references; do not introduce deep `get_node("../../../../...")` gameplay dependencies.
- Balance values live in typed `Resource` data wherever practical.
- Every weapon and turret uses an explicit `MuzzlePoint` for projectile spawning.
- Final vertical slice contains no crude placeholder circles/capsules/gray boxes for core characters, enemies, base, weapon, Water Turret, or primary UI.
- Preserve original uploaded/source artwork under a source-art directory; generated runtime frames must be derivative outputs, never destructive edits of source files.
- The game must pause combat safely during upgrade selection.
- Base HP reaching zero ends the run; player HP reaching zero temporarily incapacitates and later revives the player.
- Target is 60 FPS with roughly 100 active regular enemies on the target PC class.
- Mid-run save/resume, multiplayer, large campaign, freeform manual tower placement, and full meta-progression are outside this milestone.

## Review Focus

1. **Stale or deleted targets:** weapons and turrets must not crash or fire toward freed enemies; tests verify target invalidation before fire.
2. **Duplicate level-up application:** opening/closing the upgrade overlay must apply exactly one selected upgrade and resume exactly once.
3. **Corrupt/missing save fields:** startup must recover to defaults instead of failing.
4. **Projectile origin/facing drift:** tests assert spawned projectile global position equals the active `MuzzlePoint` transform within tolerance, and visual QA checks the sprite aligns with that origin.
5. **Wave completion edge cases:** waves must complete only when budget/spawning is exhausted and required live enemies/bosses are cleared; tests cover a boss surviving after the spawn budget is spent.

---

## File Map

The implementation creates this stable structure. Additional imported `.png`, `.tres`, and `.res` files may appear under the named asset/data folders, but gameplay responsibilities stay within these paths.

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
  test_health_component.gd
  test_projectile_weapon.gd
  test_enemy_ai.gd
  test_upgrade_system.gd
  test_water_turret.gd
  test_wave_director.gd
  test_game_flow.gd
  test_save_service.gd

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
data/upgrades/*.tres
data/waves/wave_01.tres ... wave_05.tres
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
- Produces: `tests/run_all.gd` executable via Godot `--headless --script`; assertion helpers `TestUtils.assert_true(condition, message)`, `assert_eq(actual, expected, message)`, `assert_near(actual, expected, epsilon, message)`.
- Consumes: provided Godot 4.7.2 Linux binary during execution; the binary itself is not committed.

- [ ] **Step 1: Create the minimal project configuration and input map**

`project.godot` must define the main scene later at `res://scenes/levels/backyard.tscn`, window size 1280×720, stretch mode `canvas_items`, and input actions `move_left`, `move_right`, `move_up`, `move_down`, `fire`, `pause`.

Use this initial project header:

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

Add the six input actions through `InputEventKey` entries so keyboard movement works without editor setup.

- [ ] **Step 2: Create a dependency-free headless test harness**

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

`tests/run_all.gd` extends `SceneTree`, loads every `res://tests/test_*.gd` except `test_utils.gd`, awaits `run()` when needed, prints failures, and exits with code `1` on any failure and `0` otherwise.

- [ ] **Step 3: Run the empty harness**

Run:

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

`README.md` must document the exact Godot version, the headless test command, and that source sprite sheets live in `assets/source/` while runtime-ready frames live in derived asset folders.

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
- Create directories: `assets/source/`, `assets/characters/`, `assets/enemies/`, `assets/weapons/`, `assets/defenses/`, `assets/environment/`, `assets/ui/`, `assets/vfx/`
- Populate: derived PNG frames from the supplied asset archive

**Interfaces:**
- Consumes: PNG source sheets extracted from the supplied archive into `assets/source/`.
- Produces: transparent, padded, anchor-stable PNG frame sequences plus a generated report `assets/processing_report.json`.

- [ ] **Step 1: Extract source archive without modifying its files**

Extract the user-supplied archive so each original PNG is preserved byte-for-byte under `assets/source/`. Record SHA-256 hashes in `assets/source/SOURCE_HASHES.txt` using:

```bash
find assets/source -type f -iname '*.png' -print0 | sort -z | xargs -0 sha256sum > assets/source/SOURCE_HASHES.txt
```

- [ ] **Step 2: Write a manifest format that never depends on hard-coded editor import regions**

`tools/asset_manifest.json` uses one entry per sheet with:

```json
{
  "source": "assets/source/<actual-file-name>.png",
  "output_dir": "assets/defenses/water_turret",
  "prefix": "water_turret",
  "min_component_area": 1200,
  "white_threshold": 245,
  "padding": 16,
  "anchor": "bottom_center"
}
```

During execution, populate `source` entries from the actual extracted filenames. The processing algorithm, not manual crop coordinates, determines component bounds.

- [ ] **Step 3: Implement background removal and component extraction using Godot `Image`**

`tools/process_sprite_sheets.gd` must:

1. load each PNG with `Image.load_from_file()`;
2. convert near-white pixels where `r`, `g`, and `b` are all at least `white_threshold / 255.0` to alpha `0`;
3. flood-fill 4-connected non-transparent components;
4. discard components below `min_component_area`;
5. sort components top-to-bottom then left-to-right by bounding-box center;
6. crop each component with padding;
7. normalize all frames from the same sheet to the maximum width/height of that sheet;
8. place each crop using the requested `bottom_center` anchor;
9. save `prefix_000.png`, `prefix_001.png`, ...;
10. write frame bounds, output dimensions and warnings to `assets/processing_report.json`.

The script exits non-zero when no usable component is found for a manifest entry.

- [ ] **Step 4: Run processing and inspect generated frames**

Run:

```bash
$GODOT_BIN --headless --path . --script res://tools/process_sprite_sheets.gd
```

Expected: no white background, no label text retained as a large component, stable frame canvas dimensions per animation set.

- [ ] **Step 5: Perform visual QA before gameplay integration**

Open generated frames for the hero, raccoon, Neighbor Kid, Big Neighbor, Water Turret, water projectile/splash, Flip-Flop Launcher and upgrade UI. Reject/reprocess any set with visible white halos, cropped limbs, inconsistent ground anchors, or text fragments.

- [ ] **Step 6: Commit source provenance, processor, manifest and approved derived frames**

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

**Interfaces:**
- Produces: `WeaponData`, `EnemyData`, `UpgradeData`, `WaveData`, `BaseUpgradeData` typed resources used by all later systems.

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

- [ ] **Step 2: Define enemy/wave/upgrade/base resource contracts**

`EnemyData` exposes `max_health`, `move_speed`, `contact_damage`, `threat_cost`, `coin_drop`, `xp_drop`, `target_priority`.

`UpgradeData` exposes `id`, `title`, `description`, `icon`, `rarity`, `tags`, `max_level`, `effect_key`, `magnitude`.

`WaveData` exposes `wave_index`, `threat_budget`, `spawn_interval`, `enemy_pool: Array[EnemyData]`, `elite_chance`, `boss_scene`.

`BaseUpgradeData` exposes `id`, `title`, `cost`, `max_level`, `effect_key`, `magnitude`.

Use typed exports and safe defaults; IDs default to empty string and are validated before use.

- [ ] **Step 3: Create first balancing resources**

Initial values:

```text
Raccoon:      HP 24, speed 165, contact 8, threat 1, XP 3, coins 1
Neighbor Kid: HP 55, speed 105, contact 10, threat 3, XP 7, coins 2
Big Neighbor: HP 180, speed 58, contact 22, threat 7, XP 16, coins 5
```

Flip-Flop Launcher uses the defaults shown in `WeaponData`.

- [ ] **Step 4: Add a resource-load smoke test to `tests/run_all.gd` or a dedicated `test_data_resources.gd`**

Assert every `.tres` loads, values are positive where required, and `threat_cost >= 1`.

- [ ] **Step 5: Run tests and commit**

```bash
$GODOT_BIN --headless --path . --script res://tests/run_all.gd
git add scripts/data data tests
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
- Produces: `HealthComponent.damage(amount, source := null)`, `heal(amount)`, signals `health_changed(current, maximum)`, `died(source)`; `HurtboxComponent.receive_hit(amount, knockback, source)`.

- [ ] **Step 1: Write failing health tests**

Tests must cover damage clamping, healing clamping, a single `died` emission, and ignoring damage after death.

Example assertion:

```gdscript
var health := HealthComponent.new()
health.max_health = 100.0
health.reset()
health.damage(35.0)
TestUtils.assert_near(health.current_health, 65.0, 0.001, "damage reduces health")
```

- [ ] **Step 2: Run and verify failure because classes do not exist**

```bash
$GODOT_BIN --headless --path . --script res://tests/run_all.gd
```

Expected: non-zero exit mentioning missing `HealthComponent`.

- [ ] **Step 3: Implement `HealthComponent`**

Use a `Node` with exported `max_health`, runtime `current_health`, explicit `reset()`, and an internal dead flag. Emit `died` once when health crosses zero.

- [ ] **Step 4: Implement hurtbox/damage bridge**

`HurtboxComponent` stores an exported `HealthComponent` reference and forwards validated positive damage. `DamageComponent` stores contact damage and a cooldown accumulator so sustained overlap cannot damage every physics tick.

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
- Consumes: `HealthComponent`, player runtime animation assets.

- [ ] **Step 1: Write movement/aim tests**

Test normalized diagonal input, disabled controls producing zero velocity, explicit aim direction taking priority, and auto-target returning `null` when all candidates are freed.

- [ ] **Step 2: Implement movement using Godot 4.7 conventions**

Core logic:

```gdscript
var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
body.velocity = input_dir * move_speed
body.move_and_slide()
```

Movement component receives its owning `CharacterBody2D`; it must not search the scene tree every frame.

- [ ] **Step 3: Implement hybrid aim controller**

Mouse/global cursor direction is explicit aim when sufficiently displaced from player center. Otherwise choose the nearest valid enemy from a cached candidate list maintained by an `Area2D` detection region. Validate targets with `is_instance_valid()` immediately before returning them.

- [ ] **Step 4: Assemble `player.tscn`**

Root `CharacterBody2D` children: `VisualRoot`, `AnimatedSprite2D`, `Shadow`, `CollisionShape2D`, `HealthComponent`, `Hurtbox`, `AimArea`, `AimController`, `WeaponMount`, `PickupArea`.

- [ ] **Step 5: Run tests and headless scene-load check**

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
- Produces: `Projectile.launch(origin: Vector2, direction: Vector2, speed: float, damage: float, pierce: int, knockback: float)`; `WeaponController.try_fire()`; signal `shot_fired(projectile)`.
- Consumes: `WeaponData`, `AimController`, `MuzzlePoint`.

- [ ] **Step 1: Write failing tests for muzzle origin, cadence and stale target handling**

Build a weapon test scene in memory with a `Marker2D` at `(32, -8)`. After `try_fire()`, assert projectile global position matches the marker within `0.01`. Free the selected target before a second shot and assert no crash occurs and fallback aim remains finite.

- [ ] **Step 2: Implement projectile motion and hit contract**

Projectile is an `Area2D`; `_physics_process(delta)` advances `global_position += direction * speed * delta`. On compatible hurtbox overlap it calls `receive_hit`, decrements pierce, and queues free when exhausted. Reject zero-length launch directions.

- [ ] **Step 3: Implement fire cadence from `WeaponData.fire_rate`**

Use an accumulator/cooldown float, not a `Timer` node per projectile. Compute interval as `1.0 / maxf(data.fire_rate, 0.01)`.

- [ ] **Step 4: Spawn every projectile from `MuzzlePoint.global_position`**

For multi-projectile fire, distribute spread symmetrically around the aim angle. Do not offset from the player root.

- [ ] **Step 5: Add Flip-Flop presentation**

Use the approved processed flip-flop art, rotate the projectile sprite along velocity, and add a subtle rotation animation while travelling. Keep gameplay collision independent of sprite dimensions.

- [ ] **Step 6: Run tests, visually fire at a stationary dummy, commit**

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
- Consumes: player/base target nodes, `EnemyData`, health/damage components.

- [ ] **Step 1: Write AI tests for target intent**

Raccoon selects player when available; Big Neighbor prefers base; Neighbor Kid maintains a minimum ranged distance. Verify dead/freed targets cause reacquisition instead of invalid access.

- [ ] **Step 2: Implement shared enemy movement**

`EnemyAI` computes desired direction at a controlled think rate (for example every `0.1` seconds), while movement itself runs every physics frame using the last desired direction. No per-frame global group query is allowed.

- [ ] **Step 3: Implement archetype-specific behavior**

Raccoon: chase and contact pressure. Neighbor Kid: maintain a ranged band and periodically launch a simple nuisance projectile. Big Neighbor: prefer the base and apply high contact damage at low speed.

- [ ] **Step 4: Implement death drops through a signal-driven drop path**

Enemy emits a single death payload. The level/spawn layer creates XP and coin pickups at the death position. Enemy code must not hard-code the HUD or progression system path.

- [ ] **Step 5: Assemble scenes with processed artwork and stable anchors**

Each scene uses `AnimatedSprite2D`, soft shadow, collision, hurtbox, health, damage, AI. Confirm animation does not hop when switching idle/run/hurt.

- [ ] **Step 6: Run tests and a 20-enemy smoke scene, then commit**

```bash
$GODOT_BIN --headless --path . --script res://tests/run_all.gd
git add scripts/enemies scripts/pickups scenes/enemies scenes/pickups tests/test_enemy_ai.gd
git commit -m "feat: add enemy archetypes and loot drops"
```

---

### Task 8: Add XP, coin progression and three-choice upgrades

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
- Produces: `ProgressionSystem.add_xp(amount)`, `add_coins(amount)`, signal `level_ready(level)`; `UpgradeSystem.get_choices(count: int) -> Array[UpgradeData]`, `apply_upgrade(data)`.
- Consumes: current player/weapon/defense tags.

- [ ] **Step 1: Write tests for XP thresholds, tag filtering and one-shot application**

Verify a turret upgrade is excluded when no turret tag is active, three unique valid choices are returned when available, and selecting a card twice only applies it once for the same overlay session.

- [ ] **Step 2: Implement progression counters**

Use deterministic XP threshold formula `required_xp = 12 + (level - 1) * 8` for the vertical slice. Carry overflow XP into the next level. Coins are non-negative integers.

- [ ] **Step 3: Implement upgrade filtering and effects**

Initial upgrade effects:

```text
DOUBLE TROUBLE: effect_key=projectile_count_add, magnitude=1
ANGRY FLIP-FLOP: effect_key=weapon_damage_mult, magnitude=1.25
GARDEN PRESSURE: effect_key=turret_fire_rate_mult, magnitude=1.25, requires tag=turret
```

- [ ] **Step 4: Build upgrade overlay**

Three cards show icon/title/description. Opening overlay emits a request to `GameFlow` to enter `LEVEL_UP`; buttons disable immediately after one selection; selection signal carries the chosen `UpgradeData` exactly once.

- [ ] **Step 5: Run tests and commit**

```bash
$GODOT_BIN --headless --path . --script res://tests/run_all.gd
git add scripts/components/pickup_collector.gd scripts/systems scripts/ui scenes/ui/upgrade_overlay.tscn data/upgrades tests/test_upgrade_system.gd
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
- Create: `data/base_upgrades/*.tres`
- Create: `tests/test_water_turret.gd`

**Interfaces:**
- Produces: `BaseController.apply_upgrade(data)`, `WaterTurret.set_enabled(value)`, signal `base_destroyed`; Water projectile applies damage plus slow.
- Consumes: enemy candidate overlaps, `HealthComponent`, progression coins.

- [ ] **Step 1: Write turret tests**

Cover nearest-valid-target selection, target freed between scan and fire, fire cooldown, exact `MuzzlePoint` projectile origin, slow application, and no fire when disabled.

- [ ] **Step 2: Implement target scanning at fixed cadence**

Maintain candidates from `DetectionArea` enter/exit signals. Rescore at `0.15` second intervals, not every physics tick. Before firing, verify `is_instance_valid(target)` and target is not dead.

- [ ] **Step 3: Implement water projectile**

On hit: apply base damage and call a slowdown interface on compatible enemies for a bounded duration. Non-slowable targets still take damage. Spawn splash VFX via signal so the projectile does not know the level VFX container path.

- [ ] **Step 4: Build base upgrade behavior**

Base starts with health and visible defense slots. First purchased turret unlock enables Water Turret. Further vertical-slice upgrades can increase base max HP and turret fire rate; costs come from `.tres` data and purchase refuses insufficient coins.

- [ ] **Step 5: Integrate supplied Water Turret and splash art**

Base sprite is stationary; head/aim visual rotates or flips independently when the asset allows it. Confirm water visibly originates from the nozzle/muzzle.

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
- Consumes: spawn points and enemy-scene mapping.

- [ ] **Step 1: Write wave-budget tests**

Verify threat spending never exceeds budget, enemy eligibility by wave, spawning stops after budget exhaustion, and wave completion waits for all live enemies including a surviving boss.

- [ ] **Step 2: Implement deterministic budget spending**

Use a seeded `RandomNumberGenerator` injected into tests. At each spawn interval choose an enemy whose `threat_cost <= remaining_budget`; if none fit, stop spawning and wait for live enemies to clear.

- [ ] **Step 3: Author five wave resources**

Use initial budgets/pacing:

```text
Wave 1: budget 18, interval 0.85, raccoon
Wave 2: budget 32, interval 0.72, raccoon + neighbor kid
Wave 3: budget 48, interval 0.62, raccoon + neighbor kid, elite chance 0.08
Wave 4: budget 68, interval 0.55, all regular enemies, elite chance 0.12
Wave 5: budget 85, interval 0.50, all regular enemies + miniboss scene
```

These are starting balance values and stay editable in Inspector.

- [ ] **Step 4: Implement spawn point selection**

Prefer points outside the player camera-safe radius and avoid spawning directly on player/base collision shapes. If all preferred points are blocked, use the farthest valid configured point rather than creating an invalid position.

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
- Produces: enum `GameFlow.State { BOOT, WAVE_START, COMBAT, LEVEL_UP, WAVE_COMPLETE, SHOP, PAUSED, GAME_OVER }`, method `transition_to(next_state)`, signal `state_changed(previous, current)`.
- Consumes: wave, progression, base death, player incapacitation and UI events.

- [ ] **Step 1: Write transition tests**

Assert legal path BOOT→WAVE_START→COMBAT→WAVE_COMPLETE→SHOP→WAVE_START, LEVEL_UP returns to the prior COMBAT state, GAME_OVER blocks combat transitions until restart, and upgrade selection cannot resume twice.

- [ ] **Step 2: Implement state ownership without relying on global `get_tree().paused` for every case**

Combat simulation nodes receive an explicit simulation-enabled signal; UI remains interactive. During `LEVEL_UP`, enemy/projectile/turret simulation stops while overlay buttons continue processing.

- [ ] **Step 3: Build HUD**

HUD displays player HP, base HP, XP progress, level, coins and wave number. It subscribes to signals; it does not poll actor nodes every frame.

- [ ] **Step 4: Build between-wave shop**

Show available base upgrades and costs. Purchase checks coins through progression service, applies one upgrade, refreshes UI, and cannot spend negative balance.

- [ ] **Step 5: Build game-over/restart**

Base death transitions to GAME_OVER; restart reloads the gameplay scene with fresh run state. Player death alone starts a timed incapacity/revive path and does not open game over.

- [ ] **Step 6: Run tests and commit**

```bash
$GODOT_BIN --headless --path . --script res://tests/run_all.gd
git add scripts/systems/game_flow.gd scripts/ui scenes/ui tests/test_game_flow.gd
git commit -m "feat: add game flow and core UI"
```

---

### Task 12: Assemble the editable Backyard level and integrate final core art

**Files:**
- Create: `scenes/levels/backyard.tscn`
- Modify: `project.godot`
- Populate: `assets/environment/`, approved actor/defense/VFX runtime frames

**Interfaces:**
- Consumes all gameplay scenes and systems.
- Produces the first fully playable scene and named containers `Actors`, `Enemies`, `Defenses`, `Pickups`, `Projectiles`, `VFX`, `Systems`, `HUD`.

- [ ] **Step 1: Build the level hierarchy**

Required hierarchy:

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

- [ ] **Step 2: Reconstruct the concept layout as editable layers**

Place ground, house/base, shed/fence/bush/tree props and foreground occluders separately. Use Y-sort for actors and authored z-index for roof/foreground elements. Do not use the concept screenshot as the collision map.

- [ ] **Step 3: Add collisions and playable bounds**

House, fence and solid garden props get explicit collision shapes that follow walkable silhouettes without excessive tiny segments. Spawn points sit near perimeter approaches.

- [ ] **Step 4: Wire signals at composition root**

Connect enemy deaths to drop spawning, pickups to progression, level-up to overlay, base death to game flow, wave completion to shop, and restart to scene reload. Keep the wiring in a focused level/controller script or explicit editor connections, not inside unrelated components.

- [ ] **Step 5: Run a full 5-minute smoke playthrough**

Check player movement, aim, Flip-Flop hits, three enemy behaviors, XP, coin pickup, level-up pause/resume, turret fire, base damage, wave progression and shop transition.

- [ ] **Step 6: Perform visual QA against concept**

Reject and fix: wrong Y-sort, hovering feet, detached weapon, bad muzzle position, white halos, clipped animation frames, oversized VFX, unreadable UI, enemy sprite scale inconsistency, and foreground objects failing to occlude correctly.

- [ ] **Step 7: Commit**

```bash
git add scenes/levels project.godot assets/environment assets/characters assets/enemies assets/weapons assets/defenses assets/vfx
git commit -m "feat: assemble playable backyard level"
```

---

### Task 13: Add resilient settings/progress saves

**Files:**
- Create: `scripts/systems/save_service.gd`
- Create: `tests/test_save_service.gd`

**Interfaces:**
- Produces: `SaveService.load_data(path := default_path) -> Dictionary`, `save_data(data, path := default_path) -> Error`, `defaults() -> Dictionary`.

- [ ] **Step 1: Write tests for missing, partial and corrupt files**

Cases: no file returns defaults; missing `screen_shake` fills default; wrong type for `currency` falls back safely; malformed JSON does not crash and returns defaults.

- [ ] **Step 2: Implement versioned JSON save**

Default shape:

```json
{
  "version": 1,
  "settings": {"volume": 1.0, "fullscreen": false, "screen_shake": true},
  "progress": {"highest_wave": 0, "currency": 0, "unlocked_items": []}
}
```

Validate each field independently and never trust loaded types.

- [ ] **Step 3: Apply settings on startup and record run progress on game over**

Persist highest wave using `max(previous, current)`. Do not persist the active run itself.

- [ ] **Step 4: Run tests and commit**

```bash
$GODOT_BIN --headless --path . --script res://tests/run_all.gd
git add scripts/systems/save_service.gd tests/test_save_service.gd
git commit -m "feat: add resilient save and settings service"
```

---

### Task 14: Add the Wave 5 mini-boss

**Files:**
- Create: `scripts/enemies/miniboss_ai.gd`
- Create: `scenes/enemies/miniboss.tscn`
- Create: `data/enemies/miniboss.tres`
- Modify: `data/waves/wave_05.tres`
- Extend: `tests/test_enemy_ai.gd`, `tests/test_wave_director.gd`

**Interfaces:**
- Produces a boss with at least two readable attack states and normal `Enemy` health/death contracts.

- [ ] **Step 1: Add boss tests**

Verify boss does not count as a regular budget spawn, wave 5 cannot complete while boss is alive, and boss state transitions remain valid if player becomes incapacitated.

- [ ] **Step 2: Implement two-state boss behavior**

State A: slow pursuit toward base/player zone with telegraphed heavy contact/ground attack. State B: stops briefly and performs a radial or fan nuisance attack with a clear wind-up. State changes use cooldowns and health threshold, not random state changes every frame.

- [ ] **Step 3: Give boss bespoke presentation**

Use a visibly distinct processed sprite/scale, boss health bar and stronger but readable VFX. Do not create the boss by simply multiplying Big Neighbor HP.

- [ ] **Step 4: Run wave-5 smoke test and commit**

```bash
$GODOT_BIN --headless --path . --script res://tests/run_all.gd
git add scripts/enemies/miniboss_ai.gd scenes/enemies/miniboss.tscn data/enemies/miniboss.tres data/waves/wave_05.tres tests
git commit -m "feat: add wave five mini-boss"
```

---

### Task 15: Performance pass, full regression and acceptance gate

**Files:**
- Modify only files proven by profiling/QA to need changes
- Create: `tests/perf_enemy_swarm.gd`
- Create: `docs/qa/vertical-slice-checklist.md`

**Interfaces:**
- Consumes entire vertical slice.
- Produces a tested milestone with documented evidence and no known acceptance-blocking defects.

- [ ] **Step 1: Run full headless regression**

```bash
$GODOT_BIN --headless --path . --script res://tests/run_all.gd
$GODOT_BIN --headless --path . --editor --quit
```

Expected: exit code `0`, no parse/startup/resource errors.

- [ ] **Step 2: Run 100-enemy stress scenario**

`tests/perf_enemy_swarm.gd` loads the backyard or a stripped performance scene, spawns 100 regular enemies, runs simulation for a fixed 30 seconds, and reports average/max physics-frame time plus active node count. Treat sustained physics time above 16.67 ms on the target PC as a profiling trigger, not as permission for blind rewrites.

- [ ] **Step 3: Profile only measured hotspots**

First checks: AI think cadence, target scanning frequency, projectile churn, VFX churn, collision layer breadth. Introduce pooling only if create/free churn is confirmed materially expensive.

- [ ] **Step 4: Complete the acceptance playthrough**

Document pass/fail for:

```text
player spawns and moves
manual aim and soft auto-target both work
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

- [ ] **Step 5: Complete visual QA against the approved concept**

Capture gameplay at representative moments: player firing, crowded combat, turret firing, upgrade overlay, wave-5 boss. Inspect for all visual failure cases listed in the spec. Fix and recapture every failure before marking the checklist complete.

- [ ] **Step 6: Final regression after fixes**

Re-run all headless tests, editor-load check, stress scenario and one complete five-wave playthrough.

- [ ] **Step 7: Commit milestone evidence**

```bash
git add tests/perf_enemy_swarm.gd docs/qa
git add -u
git commit -m "test: complete vertical slice acceptance pass"
```

---

## Execution Order and Gates

Execute tasks strictly in order because later tasks rely on interfaces defined earlier. A task is complete only when its own tests pass and its stated runtime/visual check has been performed. Do not batch several failing tasks into a later cleanup pass.

The development loop for every task is:

```text
write/extend failing test
→ run and confirm expected failure
→ implement minimal correct behavior
→ run automated tests
→ run the task-specific gameplay/visual smoke check
→ fix defects
→ rerun
→ commit
```

## Final Self-Review

- Spec coverage: all vertical-slice requirements map to Tasks 1–15.
- No mid-run save, multiplayer, freeform tower placement, campaign or large inventory work is included.
- Core interfaces are defined before consumers: data → components → player/weapons/enemies → progression/defense → waves/game-flow → level → saves/boss/performance.
- Review Focus items are explicitly tested in Tasks 6, 8, 9, 10, 11 and 13.
- Visual QA is required at asset ingestion, level assembly and final acceptance; it is not deferred to the end only.
- Performance optimization is evidence-driven and occurs after a measurable stress baseline.
