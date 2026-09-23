class_name EnemyAnimationStateResolver
extends RefCounted

const ACTION_PRIORITY := {
    "idle": 0,
    "run": 0,
    "attack": 30,
    "hurt": 50,
    "death": 60,
}

const ONE_SHOT_ACTIONS := [
    "attack",
    "hurt",
    "death",
]

static func resolve_action(
    moving: bool,
    attacking: bool = false,
    hurt: bool = false,
    dead: bool = false,
    active_action: String = "",
    active_finished: bool = true
) -> String:
    var requested: String = _requested_action(moving, attacking, hurt, dead)

    if not active_finished and ONE_SHOT_ACTIONS.has(active_action):
        var active_priority: int = _priority(active_action)
        var requested_priority: int = _priority(requested)
        if requested_priority <= active_priority:
            return active_action

    return requested

static func _requested_action(
    moving: bool,
    attacking: bool,
    hurt: bool,
    dead: bool
) -> String:
    if dead:
        return "death"
    if hurt:
        return "hurt"
    if attacking:
        return "attack"
    return "run" if moving else "idle"

static func _priority(action: String) -> int:
    return int(ACTION_PRIORITY.get(action, -1))
