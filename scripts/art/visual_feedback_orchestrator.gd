class_name VisualFeedbackOrchestrator
extends RefCounted

const CombatVFX = preload("res://scripts/art/combat_vfx_timing_profile.gd")
const DefenseVisuals = preload("res://scripts/art/defense_visual_state_resolver.gd")
const BaseVisuals = preload("res://scripts/art/base_upgrade_visual_profile.gd")
const BossTelegraphs = preload("res://scripts/art/boss_telegraph_profile.gd")
const HUDProfile = preload("res://scripts/art/hud_readability_profile.gd")
const EnemyHitFeedback = preload("res://scripts/art/enemy_hit_feedback_profile.gd")

static func hero_frame_events(action: StringName, frame: int) -> Array[StringName]:
    var result: Array[StringName] = []
    if not CombatVFX.EVENT_FRAMES.has(action):
        return result

    var action_events: Dictionary = CombatVFX.EVENT_FRAMES[action]
    for event_variant in action_events.keys():
        var event_name := StringName(event_variant)
        if int(action_events[event_variant]) == frame:
            result.append(event_name)
    return result

static func defense_visual_snapshot(
    current_hp: float,
    max_hp: float,
    electrified: bool = false,
    upgrade_level: int = 0,
    is_base: bool = false
) -> Dictionary:
    var result: Dictionary = DefenseVisuals.build_visual_flags(
        current_hp,
        max_hp,
        electrified,
        upgrade_level
    )

    if is_base:
        var base_visual: Dictionary = BaseVisuals.for_level(upgrade_level)
        for key in base_visual.keys():
            result[key] = base_visual[key]

    return result

static func boss_telegraph_snapshot(attack: StringName) -> Dictionary:
    var result: Dictionary = BossTelegraphs.for_attack(attack)
    result["attack"] = attack
    result["hud_kind"] = &"boss_warning"
    result["card_min_size"] = HUDProfile.card_min_size(&"boss_warning")
    result["hud_priority"] = HUDProfile.priority(&"boss_warning")
    return result

static func enemy_hit_snapshot(enemy_class: StringName, lethal: bool = false) -> Dictionary:
    var result: Dictionary = EnemyHitFeedback.profile(enemy_class)
    result["animation"] = &"death" if lethal else &"hurt"
    result["play_death_burst"] = lethal
    result["lethal"] = lethal
    return result
