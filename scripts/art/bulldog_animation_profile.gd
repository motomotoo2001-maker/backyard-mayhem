class_name BulldogAnimationProfile
extends RefCounted

const CANVAS_SIZE := Vector2i(288, 288)
const GROUND_ANCHOR := Vector2i(144, 268)
const ALLOW_HORIZONTAL_FLIP := true

const ACTIONS := {
    &"idle": {"frames": 4, "fps": 5.0, "loop": true},
    &"run": {"frames": 8, "fps": 9.0, "loop": true},
    &"attack": {"frames": 7, "fps": 10.0, "loop": false, "events": {&"hit": 4}},
    &"hurt": {"frames": 3, "fps": 9.0, "loop": false},
    &"death": {"frames": 6, "fps": 8.0, "loop": false},
}

static func actions() -> Array[StringName]:
    var result: Array[StringName] = []
    for action_variant in ACTIONS.keys():
        result.append(StringName(action_variant))
    return result

static func profile(action: StringName) -> Dictionary:
    if not ACTIONS.has(action):
        return {}
    return (ACTIONS[action] as Dictionary).duplicate(true)

static func frame_count(action: StringName) -> int:
    return int(profile(action).get("frames", 0))

static func fps(action: StringName) -> float:
    return float(profile(action).get("fps", 0.0))

static func loops(action: StringName) -> bool:
    return bool(profile(action).get("loop", false))

static func event_frame(action: StringName, event_name: StringName) -> int:
    var action_profile := profile(action)
    var events: Dictionary = action_profile.get("events", {})
    if not events.has(event_name):
        return -1
    return int(events[event_name])

static func total_frames() -> int:
    var total := 0
    for action in actions():
        total += frame_count(action)
    return total
