class_name BackyardHUDModel
extends RefCounted

const Waves = preload("res://scripts/gameplay/wave_progression_profile.gd")
const HUDProfile = preload("res://scripts/art/hud_readability_profile.gd")

static func from_runtime(runtime_state: Dictionary) -> Dictionary:
    var current_wave := int(runtime_state.get("current_wave", 1))
    var total_waves := Waves.wave_count()
    var state := StringName(runtime_state.get("state", &"wave"))
    var coins := int(runtime_state.get("coins", 0))
    var base_tier := int(runtime_state.get("base_tier", 0))
    var base_hp := float(runtime_state.get("base_hp", 0.0))
    var base_max_hp := maxf(float(runtime_state.get("base_max_hp", 0.0)), 0.0)
    var base_health_ratio := clampf(base_hp / base_max_hp, 0.0, 1.0) if base_max_hp > 0.0 else 0.0
    var focus := StringName(runtime_state.get("focus", &""))
    var primary_card := _primary_card_for_state(state, base_health_ratio)

    return {
        "wave_text": "WAVE %d / %d" % [current_wave, total_waves],
        "coins_text": "COINS %d" % coins,
        "base_text": "BASE TIER %d" % base_tier,
        "base_hp_text": "BASE HP %d / %d" % [int(round(base_hp)), int(round(base_max_hp))],
        "base_health_ratio": base_health_ratio,
        "state_text": _state_text(state),
        "focus_text": _humanize(focus),
        "threat_text": "THREAT %d" % int(runtime_state.get("threat_budget", 0)),
        "wave_progress": clampf(float(current_wave) / float(maxi(total_waves, 1)), 0.0, 1.0),
        "primary_card": primary_card,
        "primary_card_size": HUDProfile.card_min_size(primary_card),
        "primary_card_priority": HUDProfile.priority(primary_card),
        "offers": (runtime_state.get("offers", []) as Array).duplicate(true),
        "is_boss_wave": bool(runtime_state.get("is_boss_wave", false)),
    }

static func _primary_card_for_state(state: StringName, base_health_ratio: float) -> StringName:
    if state == &"defeat" or base_health_ratio <= 0.33:
        return &"critical_health"
    match state:
        &"intermission":
            return &"upgrade_hint"
        &"victory":
            return &"wave_transition"
        _:
            return &"status"

static func _state_text(state: StringName) -> String:
    match state:
        &"intermission":
            return "CHOOSE AN UPGRADE"
        &"victory":
            return "YARD SAVED!"
        &"defeat":
            return "BASE DESTROYED"
        _:
            return "DEFEND THE YARD"

static func _humanize(value: StringName) -> String:
    return String(value).replace("_", " ").to_upper()
