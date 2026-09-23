class_name HeroAnimationStateResolver
extends RefCounted

const ACTION_PRIORITY := {
    "idle": 0,
    "run": 0,
    "fire": 20,
    "build": 30,
    "dash": 40,
    "hurt": 50,
    "death": 60,
}

const ONE_SHOT_ACTIONS := [
    "fire",
    "build",
    "dash",
    "hurt",
    "death",
]

static func resolve_action(
    moving: bool,
    firing: bool = false,
    building: bool = false,
    dashing: bool = false,
    hurt: bool = false,
    dead: bool = false,
    active_action: String = "",
    active_finished: bool = true
) -> String:
    var requested: String = _requested_action(moving, firing, building, dashing, hurt, dead)

    if not active_finished and ONE_SHOT_ACTIONS.has(active_action):
        var active_priority: int = _priority(active_action)
        var requested_priority: int = _priority(requested)
        if requested_priority <= active_priority:
            return active_action

    return requested

static func _requested_action(
    moving: bool,
    firing: bool,
    building: bool,
    dashing: bool,
    hurt: bool,
    dead: bool
) -> String:
    if dead:
        return "death"
    if hurt:
        return "hurt"
    if dashing:
        return "dash"
    if building:
        return "build"
    if firing:
        return "fire"
    return "run" if moving else "idle"

static func _priority(action: String) -> int:
    return int(ACTION_PRIORITY.get(action, -1))
