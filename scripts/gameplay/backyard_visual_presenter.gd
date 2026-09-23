class_name BackyardVisualPresenter
extends RefCounted

const HUDProfile = preload("res://scripts/art/hud_readability_profile.gd")

static func from_runtime(runtime_state: Dictionary) -> Dictionary:
    var base_visual: Dictionary = (runtime_state.get("base_visual", {}) as Dictionary).duplicate(true)
    var is_boss_wave := bool(runtime_state.get("is_boss_wave", false))
    var state := StringName(runtime_state.get("state", &"wave"))
    var boss_alert_visible := is_boss_wave and state == &"wave"

    return {
        "base_level": int(base_visual.get("level", runtime_state.get("base_tier", 0))),
        "base_health_state": String(base_visual.get("state", "fresh")),
        "show_cracks": bool(base_visual.get("show_cracks", false)),
        "show_smoke": bool(base_visual.get("show_smoke", false)),
        "show_debris": bool(base_visual.get("show_debris", false)),
        "show_electric": bool(base_visual.get("show_electric", false)),
        "turret_slots": int(base_visual.get("turret_slots", 0)),
        "show_sandbags": bool(base_visual.get("show_sandbags", false)),
        "show_armor": bool(base_visual.get("show_armor", false)),
        "show_power_cables": bool(base_visual.get("show_power_cables", false)),
        "show_beacon": bool(base_visual.get("show_beacon", false)),
        "show_power_coils": bool(base_visual.get("show_power_coils", false)),
        "base_scale": float(base_visual.get("silhouette_scale", 1.0)),
        "boss_alert_visible": boss_alert_visible,
        "boss_alert_text": "BOSS WAVE — WATCH THE TELEGRAPHS" if boss_alert_visible else "",
        "boss_alert_priority": HUDProfile.priority(&"boss_warning") if boss_alert_visible else 0,
        "boss_alert_size": HUDProfile.card_min_size(&"boss_warning") if boss_alert_visible else Vector2i.ZERO,
    }
