class_name DefenseVisualStateResolver
extends RefCounted

const DAMAGED_THRESHOLD := 0.66
const CRITICAL_THRESHOLD := 0.33
const MAX_VISUAL_UPGRADE_LEVEL := 3

static func resolve_health_state(current_hp: float, max_hp: float) -> String:
    if current_hp <= 0.0 or max_hp <= 0.0:
        return "broken"

    var ratio: float = clampf(current_hp / max_hp, 0.0, 1.0)
    if ratio <= CRITICAL_THRESHOLD:
        return "critical"
    if ratio <= DAMAGED_THRESHOLD:
        return "damaged"
    return "fresh"

static func build_visual_flags(
    current_hp: float,
    max_hp: float,
    electrified: bool = false,
    upgrade_level: int = 0
) -> Dictionary:
    var state := resolve_health_state(current_hp, max_hp)
    var clamped_upgrade := clampi(upgrade_level, 0, MAX_VISUAL_UPGRADE_LEVEL)

    return {
        "state": state,
        "show_cracks": state == "damaged" or state == "critical",
        "show_smoke": state == "critical",
        "show_debris": state == "broken",
        "show_electric": electrified and state != "broken",
        "upgrade_level": clamped_upgrade,
    }
