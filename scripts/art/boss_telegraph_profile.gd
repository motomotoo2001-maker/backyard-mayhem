class_name BossTelegraphProfile
extends RefCounted

const FALLBACK := {
    "windup_seconds": 0.45,
    "telegraph_radius": 100.0,
    "pulse_count": 2,
    "impact_shake": 1.5,
    "impact_flash_seconds": 0.07,
}

const PROFILES := {
    &"heavy_swing": {
        "windup_seconds": 0.48,
        "telegraph_radius": 110.0,
        "pulse_count": 2,
        "impact_shake": 2.1,
        "impact_flash_seconds": 0.085,
    },
    &"radial_slam": {
        "windup_seconds": 0.78,
        "telegraph_radius": 185.0,
        "pulse_count": 3,
        "impact_shake": 3.6,
        "impact_flash_seconds": 0.12,
    },
}

static func for_attack(attack: StringName) -> Dictionary:
    if PROFILES.has(attack):
        return (PROFILES[attack] as Dictionary).duplicate(true)
    return FALLBACK.duplicate(true)
