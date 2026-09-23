class_name HeroDirectionResolver
extends RefCounted

const VALID_DIRECTIONS: PackedStringArray = PackedStringArray([
    "right",
    "front_right",
    "front",
    "front_left",
    "left",
    "back_left",
    "back",
    "back_right",
])

const DIRECTION_CENTERS := {
    "right": 0.0,
    "front_right": 45.0,
    "front": 90.0,
    "front_left": 135.0,
    "left": 180.0,
    "back_left": -135.0,
    "back": -90.0,
    "back_right": -45.0,
}

const HALF_SECTOR_DEGREES := 22.5

static func resolve(
    vector: Vector2,
    previous_direction: String = "front",
    deadzone: float = 0.15,
    hysteresis_degrees: float = 6.0
) -> String:
    var previous := previous_direction if VALID_DIRECTIONS.has(previous_direction) else "front"
    if vector.length() < maxf(deadzone, 0.0):
        return previous

    var angle_degrees := rad_to_deg(atan2(vector.y, vector.x))
    var candidate := _direction_for_angle(angle_degrees)
    if candidate == previous:
        return candidate

    var previous_center := float(DIRECTION_CENTERS.get(previous, 90.0))
    var previous_delta := absf(_wrapped_delta_degrees(angle_degrees, previous_center))
    var retain_limit := HALF_SECTOR_DEGREES + maxf(hysteresis_degrees, 0.0)
    if previous_delta <= retain_limit:
        return previous

    return candidate

static func _direction_for_angle(angle_degrees: float) -> String:
    var best_direction := "right"
    var best_delta := INF

    for direction in VALID_DIRECTIONS:
        var center := float(DIRECTION_CENTERS[direction])
        var delta := absf(_wrapped_delta_degrees(angle_degrees, center))
        if delta < best_delta:
            best_delta = delta
            best_direction = direction

    return best_direction

static func _wrapped_delta_degrees(a: float, b: float) -> float:
    return wrapf(a - b, -180.0, 180.0)
