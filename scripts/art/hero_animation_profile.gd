class_name HeroAnimationProfile
extends RefCounted

const DIRECTIONS := [
    "front",
    "front_right",
    "right",
    "back_right",
    "back",
    "back_left",
    "left",
    "front_left",
]

const FRAME_COUNTS := {
    &"idle": 4,
    &"run": 8,
    &"fire": 4,
    &"build": 6,
    &"hurt": 3,
    &"dash": 4,
    &"death": 6,
}

const FPS := {
    &"idle": 5.0,
    &"run": 12.0,
    &"fire": 14.0,
    &"build": 11.0,
    &"hurt": 12.0,
    &"dash": 18.0,
    &"death": 8.0,
}

const LOOPING := {
    &"idle": true,
    &"run": true,
    &"fire": false,
    &"build": false,
    &"hurt": false,
    &"dash": false,
    &"death": false,
}

static func frame_count(action: StringName) -> int:
    return int(FRAME_COUNTS.get(action, 0))

static func fps(action: StringName) -> float:
    return float(FPS.get(action, 0.0))

static func loops(action: StringName) -> bool:
    return bool(LOOPING.get(action, false))

static func frame_name(action: StringName, direction: String, frame_index: int) -> String:
    return "%s_%s_%02d.png" % [String(action), direction, frame_index]

static func animation_name(action: StringName, direction: String) -> String:
    return "%s_%s" % [String(action), direction]

static func total_required_frames() -> int:
    var per_direction := 0
    for count in FRAME_COUNTS.values():
        per_direction += int(count)
    return per_direction * DIRECTIONS.size()
