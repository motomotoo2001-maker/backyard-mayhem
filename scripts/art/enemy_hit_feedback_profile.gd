class_name EnemyHitFeedbackProfile
extends RefCounted

const PROFILES := {
    &"standard": {
        "flash_seconds": 0.065,
        "hit_stop_seconds": 0.022,
        "knockback_speed": 150.0,
        "shake_strength": 1.15,
        "shake_seconds": 0.055,
        "death_burst_scale": 0.85,
    },
    &"heavy": {
        "flash_seconds": 0.085,
        "hit_stop_seconds": 0.035,
        "knockback_speed": 90.0,
        "shake_strength": 2.0,
        "shake_seconds": 0.08,
        "death_burst_scale": 1.2,
    },
    &"boss": {
        "flash_seconds": 0.10,
        "hit_stop_seconds": 0.05,
        "knockback_speed": 35.0,
        "shake_strength": 3.25,
        "shake_seconds": 0.12,
        "death_burst_scale": 1.65,
    },
}

static func profile(enemy_class: StringName) -> Dictionary:
    var key: StringName = enemy_class
    if not PROFILES.has(key):
        key = &"standard"
    return (PROFILES[key] as Dictionary).duplicate(true)

static func flash_seconds(enemy_class: StringName) -> float:
    return float(profile(enemy_class).get("flash_seconds", 0.0))

static func hit_stop_seconds(enemy_class: StringName) -> float:
    return float(profile(enemy_class).get("hit_stop_seconds", 0.0))

static func knockback_speed(enemy_class: StringName) -> float:
    return float(profile(enemy_class).get("knockback_speed", 0.0))

static func shake_strength(enemy_class: StringName) -> float:
    return float(profile(enemy_class).get("shake_strength", 0.0))

static func shake_seconds(enemy_class: StringName) -> float:
    return float(profile(enemy_class).get("shake_seconds", 0.0))

static func death_burst_scale(enemy_class: StringName) -> float:
    return float(profile(enemy_class).get("death_burst_scale", 1.0))
