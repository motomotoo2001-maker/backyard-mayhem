class_name PlayerVisualRig
extends RefCounted

const WEAPON_RECOIL_PX: float = 6.0
const DASH_TRAIL_PEAK_SCALE: float = 1.2
const HURT_FLASH_COLOR: Color = Color(1.28, 0.68, 0.68, 1.0)

static func response_for_event(event_name: StringName, action: StringName) -> Dictionary:
    if event_name == &"recoil_peak" and action == &"fire":
        return {"weapon_recoil_px": WEAPON_RECOIL_PX}
    if event_name == &"recovery" and action == &"fire":
        return {"reset_weapon": true}
    if event_name == &"trail_peak" and action == &"dash":
        return {"dash_trail_scale": DASH_TRAIL_PEAK_SCALE}
    if event_name == &"trail_end" and action == &"dash":
        return {"reset_dash_trail": true}
    if event_name == &"impact" and action == &"hurt":
        return {"hurt_flash": true, "hurt_flash_color": HURT_FLASH_COLOR}
    if event_name == &"recovery" and action == &"hurt":
        return {"clear_hurt_flash": true}
    return {}

static func cleanup_for_action(action: StringName) -> Dictionary:
    match action:
        &"fire":
            return {"reset_weapon": true}
        &"dash":
            return {"reset_dash_trail": true}
        &"hurt":
            return {"clear_hurt_flash": true}
    return {}
