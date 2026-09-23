class_name BetweenWaveUpgradeProfile
extends RefCounted

const POOLS := {
    &"hero": [
        &"golden_slipper",
        &"super_soaker",
        &"leaf_blower_power",
        &"dash_cooldown",
    ],
    &"base": [
        &"base_fortification",
        &"turret_socket",
        &"electric_fence",
        &"sprinkler_overdrive",
    ],
    &"utility": [
        &"emergency_repair",
        &"coin_magnet",
        &"pickup_radius",
        &"wave_start_shield",
    ],
}

const COSTS := {
    &"hero": [80, 110, 150, 200],
    &"base": [90, 120, 160, 210],
    &"utility": [60, 80, 110, 140],
}

static func pool_for(category: StringName) -> Array:
    return (POOLS.get(category, []) as Array).duplicate()

static func offer_slots_after_wave(completed_wave: int) -> Array:
    if completed_wave >= 5:
        return []

    var stage := clampi(completed_wave, 1, 4) - 1
    return [
        _slot(&"hero", stage),
        _slot(&"base", stage),
        _slot(&"utility", stage),
    ]

static func _slot(category: StringName, stage: int) -> Dictionary:
    var costs: Array = COSTS.get(category, []) as Array
    var safe_stage := clampi(stage, 0, maxi(costs.size() - 1, 0))
    var cost := int(costs[safe_stage]) if not costs.is_empty() else 0
    return {
        "category": category,
        "upgrade_pool": pool_for(category),
        "cost": cost,
    }
