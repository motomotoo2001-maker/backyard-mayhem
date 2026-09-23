class_name BackyardRuntimeCoordinator
extends RefCounted

const VerticalSliceSessionScript = preload("res://scripts/gameplay/vertical_slice_session.gd")
const Waves = preload("res://scripts/gameplay/wave_progression_profile.gd")
const Visuals = preload("res://scripts/art/visual_feedback_orchestrator.gd")

var _session = VerticalSliceSessionScript.new()

func reset() -> void:
    _session.reset()

func snapshot() -> Dictionary:
    var session_state: Dictionary = _session.snapshot()
    var wave_number := int(session_state.get("current_wave", 1))
    var wave_data: Dictionary = Waves.wave(wave_number)
    var base_tier := int(session_state.get("base_tier", 0))
    var base_hp := float(session_state.get("base_hp", 100.0))
    var base_max_hp := float(session_state.get("base_max_hp", 100.0))
    var owned: Array = session_state.get("owned_upgrades", []) as Array
    var electrified := owned.has(&"electric_fence")

    session_state["threat_budget"] = int(wave_data.get("threat_budget", 0))
    session_state["reward_coins"] = int(wave_data.get("reward_coins", 0))
    session_state["intermission_seconds"] = float(wave_data.get("intermission_seconds", 0.0))
    session_state["enemy_pool"] = (wave_data.get("enemy_pool", []) as Array).duplicate()
    session_state["is_boss_wave"] = bool(wave_data.get("is_boss_wave", false))
    session_state["focus"] = StringName(wave_data.get("focus", &""))
    session_state["base_visual"] = Visuals.defense_visual_snapshot(base_hp, base_max_hp, electrified, base_tier, true)
    return session_state

func complete_wave() -> Dictionary:
    _session.complete_current_wave()
    return snapshot()

func start_next_wave() -> bool:
    return _session.start_next_wave()

func purchase_upgrade(category: StringName, upgrade_id: StringName) -> bool:
    return _session.purchase_upgrade(category, upgrade_id)

func damage_base(amount: float) -> bool:
    return _session.damage_base(amount)

func repair_base(amount: float) -> bool:
    return _session.repair_base(amount)

func hero_frame_events(action: StringName, frame: int) -> Array[StringName]:
    return Visuals.hero_frame_events(action, frame)

func boss_warning(attack: StringName) -> Dictionary:
    return Visuals.boss_telegraph_snapshot(attack)

func enemy_hit_feedback(enemy_class: StringName, lethal: bool = false) -> Dictionary:
    return Visuals.enemy_hit_snapshot(enemy_class, lethal)
