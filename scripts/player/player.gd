class_name BackyardPlayer
extends CharacterBody2D

const HeroDirectionResolver = preload("res://scripts/art/hero_direction_resolver.gd")

const ACTION_ANIMATION_PRIORITIES := {
    &"idle": 0,
    &"run": 0,
    &"fire": 10,
    &"build": 20,
    &"dash": 30,
    &"hurt": 40,
    &"death": 50,
    &"defeat": 50,
}

signal incapacitated
signal revived

@onready var movement_component: Node = $MovementComponent
@onready var aim_controller: Node = $AimController
@onready var aim_area: Area2D = $AimArea
@onready var animated_sprite: AnimatedSprite2D = $VisualRoot/AnimatedSprite2D
@onready var weapon_controller: Node2D = $WeaponMount/FlipFlopLauncher
@onready var health_component: Node = $HealthComponent
@onready var hurtbox: Area2D = $Hurtbox
@onready var build_controller: Node = $BuildController
@onready var dash_component: Node = $DashComponent
@onready var dash_fx: Node2D = $VisualRoot/DashFX

@export var revive_delay: float = 2.0
@export_range(0.05, 1.0) var revive_fraction: float = 0.5
@export_range(0.0, 20.0, 0.5) var direction_hysteresis_degrees: float = 6.0

var _manual_aim_seconds := 0.0
var _incapacitated := false
var _revive_remaining := 0.0
var _building := false
var _action_animation: StringName = &""
var _facing_vector := Vector2(1, 1).normalized()
var _facing_direction: String = "front_right"
var _last_health := 0.0

func _ready() -> void:
    aim_area.body_entered.connect(_on_aim_body_entered)
    aim_area.body_exited.connect(_on_aim_body_exited)
    hurtbox.health_component = health_component
    health_component.died.connect(_on_health_died)
    health_component.health_changed.connect(_on_health_changed)
    _last_health = health_component.current_health
    weapon_controller.configure_aim_controller(aim_controller)
    weapon_controller.shot_fired.connect(_on_weapon_shot_fired)
    animated_sprite.animation_finished.connect(_on_animation_finished)
    dash_component.dash_started.connect(_on_dash_started)
    dash_component.dash_finished.connect(_on_dash_finished)

func _physics_process(delta: float) -> void:
    dash_component.tick(delta)
    if _incapacitated:
        _revive_remaining = maxf(0.0, _revive_remaining - delta)
        velocity = Vector2.ZERO
        if _revive_remaining <= 0.0:
            _finish_revive()
        return
    if _building:
        velocity = Vector2.ZERO
        weapon_controller.tick(delta)
        _update_animation(Vector2.ZERO)
        return
    var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if Input.is_action_just_pressed("dash") and not build_controller.active:
        var dash_direction := input_direction if input_direction.length_squared() > 0.001 else _facing_vector
        dash_component.try_start(dash_direction)
    if dash_component.is_active():
        velocity = dash_component.get_velocity()
        move_and_slide()
        _update_animation(dash_component.get_direction())
        weapon_controller.tick(delta)
        return
    movement_component.apply_to_body(self, input_direction)
    move_and_slide()
    _update_animation(input_direction)
    weapon_controller.tick(delta)
    if Input.is_action_pressed("fire") and not build_controller.active:
        weapon_controller.try_fire()
    if animated_sprite != null:
        animated_sprite.flip_h = false

func _process(delta: float) -> void:
    _manual_aim_seconds = maxf(0.0, _manual_aim_seconds - delta)
    if _manual_aim_seconds > 0.0:
        aim_controller.set_manual_aim_direction(get_global_mouse_position() - global_position, true)
    else:
        aim_controller.set_manual_aim_direction(Vector2.ZERO, false)
    weapon_controller.rotation = aim_controller.get_aim_direction().angle()

func _on_dash_started(direction: Vector2) -> void:
    if hurtbox != null and hurtbox.has_method("set_invulnerable"):
        hurtbox.set_invulnerable(true)
    if dash_fx != null:
        dash_fx.visible = true
        dash_fx.rotation = direction.angle()
    if animated_sprite != null:
        animated_sprite.modulate = Color(1.08, 1.08, 1.15, 1.0)

func _on_dash_finished() -> void:
    if hurtbox != null and hurtbox.has_method("set_invulnerable"):
        hurtbox.set_invulnerable(false)
    if dash_fx != null:
        dash_fx.visible = false
    if animated_sprite != null:
        animated_sprite.modulate = Color.WHITE

func _update_animation(input_direction: Vector2) -> void:
    var sprite: AnimatedSprite2D = animated_sprite if animated_sprite != null else get_node_or_null("VisualRoot/AnimatedSprite2D") as AnimatedSprite2D
    if sprite == null or sprite.sprite_frames == null:
        return

    var desired_state := _select_animation_state(input_direction)
    if _action_animation != &"" and sprite.animation == _action_animation and sprite.is_playing():
        if _should_hold_action_animation(desired_state):
            return
        _action_animation = &""

    var desired := _resolve_animation_name(desired_state, input_direction)
    if sprite.animation != desired or not sprite.is_playing():
        sprite.play(desired)

func _should_hold_action_animation(incoming_state: StringName) -> bool:
    if _action_animation == &"":
        return false
    var current_state := _animation_base_state(_action_animation)
    return _action_priority(current_state) >= _action_priority(incoming_state)

func _animation_base_state(animation_name: StringName) -> StringName:
    var text := String(animation_name)
    var separator := text.find("_")
    if separator < 0:
        return animation_name
    return StringName(text.substr(0, separator))

func _action_priority(state: StringName) -> int:
    return int(ACTION_ANIMATION_PRIORITIES.get(state, 0))

func _select_animation_state(input_direction: Vector2) -> StringName:
    if dash_component != null and is_instance_valid(dash_component) and dash_component.has_method("is_active"):
        if bool(dash_component.call("is_active")):
            return &"dash"
    if _building:
        return &"build"
    if input_direction.length_squared() > 0.001:
        return &"run"
    return &"idle"

func _on_weapon_shot_fired(_projectile) -> void:
    if _building or _incapacitated or animated_sprite == null:
        return
    var action_text := String(_action_animation)
    if action_text.begins_with("hurt") or action_text.begins_with("death") or action_text.begins_with("defeat"):
        return
    _action_animation = _resolve_animation_name(&"fire", Vector2.ZERO)
    animated_sprite.play(_action_animation)

func _on_animation_finished() -> void:
    if animated_sprite == null:
        return
    if _incapacitated and _action_animation != &"" and animated_sprite.animation == _action_animation:
        return
    if _action_animation != &"" and animated_sprite.animation == _action_animation:
        _action_animation = &""
        var movement_hint := velocity.normalized() if velocity.length_squared() > 0.001 else Vector2.ZERO
        _update_animation(movement_hint)

func set_building(value: bool) -> void:
    if value and dash_component != null and dash_component.has_method("cancel"):
        dash_component.cancel()
    _building = value
    if value:
        velocity = Vector2.ZERO
        _action_animation = &""
    _update_animation(Vector2.ZERO)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion or event is InputEventMouseButton:
        _manual_aim_seconds = 1.2

func set_controls_enabled(enabled: bool) -> void:
    movement_component.enabled = enabled
    if not enabled and dash_component != null and dash_component.has_method("cancel"):
        dash_component.cancel()
    if not enabled:
        velocity = Vector2.ZERO

func get_aim_direction() -> Vector2:
    return aim_controller.get_aim_direction()

func get_aim_target() -> Node2D:
    return aim_controller.get_target()

func _on_aim_body_entered(body: Node2D) -> void:
    if body != self:
        aim_controller.consider_candidate(body)

func _on_aim_body_exited(body: Node2D) -> void:
    aim_controller.forget_candidate(body)

func is_incapacitated() -> bool:
    return _incapacitated

func _on_health_changed(current: float, _maximum: float) -> void:
    var took_damage := current < _last_health - 0.001
    _last_health = current
    if not took_damage or current <= 0.0 or _incapacitated or animated_sprite == null:
        return
    _action_animation = _resolve_animation_name(&"hurt", Vector2.ZERO)
    if animated_sprite.sprite_frames.has_animation(_action_animation):
        animated_sprite.play(_action_animation)

func _on_health_died(_source) -> void:
    if _incapacitated:
        return
    _incapacitated = true
    _revive_remaining = maxf(revive_delay, 0.05)
    set_controls_enabled(false)
    if animated_sprite != null and animated_sprite.sprite_frames != null:
        _action_animation = _resolve_animation_name(&"death", Vector2.ZERO)
        if animated_sprite.sprite_frames.has_animation(_action_animation):
            animated_sprite.play(_action_animation)
    incapacitated.emit()

func _finish_revive() -> void:
    health_component.revive(revive_fraction)
    _last_health = health_component.current_health
    _incapacitated = false
    _action_animation = &""
    set_controls_enabled(true)
    _update_animation(Vector2.ZERO)
    revived.emit()

func _resolve_animation_name(base_state: StringName, input_direction: Vector2) -> StringName:
    var sprite := animated_sprite
    if sprite == null or sprite.sprite_frames == null:
        return base_state
    var direction_suffix := _resolve_direction_suffix(base_state, input_direction)
    var directional_name := StringName("%s_%s" % [String(base_state), direction_suffix])
    if sprite.sprite_frames.has_animation(directional_name):
        return directional_name
    if sprite.sprite_frames.has_animation(base_state):
        return base_state

    if base_state == &"dash":
        var directional_run := StringName("run_%s" % direction_suffix)
        if sprite.sprite_frames.has_animation(directional_run):
            return directional_run
        if sprite.sprite_frames.has_animation(&"run"):
            return &"run"

    if base_state == &"death":
        var directional_defeat := StringName("defeat_%s" % direction_suffix)
        if sprite.sprite_frames.has_animation(directional_defeat):
            return directional_defeat
        if sprite.sprite_frames.has_animation(&"defeat"):
            return &"defeat"

    return base_state

func _resolve_direction_suffix(base_state: StringName, input_direction: Vector2) -> String:
    var direction := Vector2.ZERO
    var aim_direction := Vector2.ZERO
    if aim_controller != null and is_instance_valid(aim_controller) and aim_controller.has_method("get_aim_direction"):
        aim_direction = aim_controller.get_aim_direction()
    if base_state == &"run" and input_direction.length_squared() > 0.001:
        direction = input_direction
    elif aim_direction.length_squared() > 0.001:
        direction = aim_direction
    elif input_direction.length_squared() > 0.001:
        direction = input_direction
    else:
        direction = _facing_vector

    if direction.length_squared() > 0.001:
        _facing_vector = direction.normalized()

    _facing_direction = HeroDirectionResolver.resolve(
        _facing_vector,
        _facing_direction,
        0.0,
        direction_hysteresis_degrees
    )
    return _facing_direction
