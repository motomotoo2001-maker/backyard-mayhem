class_name WaterVFXSequenceProfile
extends RefCounted

const PROFILES := {
    &"stream": {
        "frames": 8,
        "fps": 12.0,
        "loop": true,
        "origin_role": &"nozzle_left",
    },
    &"projectile": {
        "frames": 4,
        "fps": 14.0,
        "loop": true,
        "origin_role": &"center",
    },
    &"splash": {
        "frames": 6,
        "fps": 16.0,
        "loop": false,
        "origin_role": &"impact_center",
    },
    &"impact": {
        "frames": 5,
        "fps": 18.0,
        "loop": false,
        "origin_role": &"impact_center",
    },
    &"foam": {
        "frames": 6,
        "fps": 12.0,
        "loop": false,
        "origin_role": &"impact_center",
    },
    &"vortex": {
        "frames": 8,
        "fps": 14.0,
        "loop": true,
        "origin_role": &"center",
    },
}

static func kinds() -> Array[StringName]:
    var result: Array[StringName] = []
    for key in PROFILES.keys():
        result.append(StringName(key))
    return result

static func profile(kind: StringName) -> Dictionary:
    if not PROFILES.has(kind):
        return {}
    return (PROFILES[kind] as Dictionary).duplicate(true)

static func frame_count(kind: StringName) -> int:
    return int(profile(kind).get("frames", 0))

static func fps(kind: StringName) -> float:
    return float(profile(kind).get("fps", 0.0))

static func loops(kind: StringName) -> bool:
    return bool(profile(kind).get("loop", false))

static func origin_role(kind: StringName) -> StringName:
    return StringName(profile(kind).get("origin_role", &""))
