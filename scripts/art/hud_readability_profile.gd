class_name HUDReadabilityProfile
extends RefCounted

const CARD_SIZES := {
    &"dash": Vector2i(240, 46),
    &"health": Vector2i(280, 54),
    &"wave_transition": Vector2i(300, 56),
    &"upgrade_hint": Vector2i(320, 54),
    &"boss_warning": Vector2i(360, 64),
    &"status": Vector2i(220, 44),
}

const PRIORITIES := {
    &"status": 10,
    &"upgrade_hint": 40,
    &"wave_transition": 65,
    &"critical_health": 90,
    &"boss_warning": 100,
}

const MAX_TRANSIENT_CARDS := 2

static func card_min_size(kind: StringName) -> Vector2i:
    return CARD_SIZES.get(kind, Vector2i(220, 44)) as Vector2i

static func priority(kind: StringName) -> int:
    return int(PRIORITIES.get(kind, 0))

static func should_replace(current_kind: StringName, incoming_kind: StringName) -> bool:
    return priority(incoming_kind) > priority(current_kind)

static func max_transient_cards() -> int:
    return MAX_TRANSIENT_CARDS
