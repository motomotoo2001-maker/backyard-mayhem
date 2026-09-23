class_name CombatVFXTimingProfile
extends RefCounted

const HeroProfile = preload("res://scripts/art/hero_animation_profile.gd")

const EVENT_FRAMES := {
    &"fire": {
        &"muzzle": 1,
        &"recoil_peak": 1,
        &"air_blast": 1,
        &"recovery": 3,
    },
    &"dash": {
        &"trail_start": 0,
        &"trail_peak": 1,
        &"trail_end": 3,
    },
    &"hurt": {
        &"impact": 0,
        &"recovery": 2,
    },
}

static func has_event(action: StringName, event_name: StringName) -> bool:
    if not EVENT_FRAMES.has(action):
        return false
    var action_events: Dictionary = EVENT_FRAMES[action]
    return action_events.has(event_name)

static func event_frame(action: StringName, event_name: StringName) -> int:
    if not has_event(action, event_name):
        return -1
    var action_events: Dictionary = EVENT_FRAMES[action]
    return int(action_events[event_name])

static func event_time_seconds(action: StringName, event_name: StringName) -> float:
    var frame := event_frame(action, event_name)
    if frame < 0:
        return -1.0
    var animation_fps := HeroProfile.fps(action)
    if animation_fps <= 0.0:
        return -1.0
    return float(frame) / animation_fps
