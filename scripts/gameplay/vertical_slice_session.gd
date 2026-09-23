class_name VerticalSliceSession
extends RefCounted

const Waves = preload("res://scripts/gameplay/wave_progression_profile.gd")
const Upgrades = preload("res://scripts/gameplay/between_wave_upgrade_profile.gd")

var current_wave: int = 1
var state: StringName = &"wave"
var coins: int = 0
var base_tier: int = 0
var owned_upgrades: Array[StringName] = []
var offers: Array = []
var intermission_purchase_made: bool = false

func reset() -> void:
    current_wave = 1
    state = &"wave"
    coins = 0
    base_tier = 0
    owned_upgrades.clear()
    offers.clear()
    intermission_purchase_made = false

func snapshot() -> Dictionary:
    return {
        "current_wave": current_wave,
        "state": state,
        "coins": coins,
        "base_tier": base_tier,
        "owned_upgrades": owned_upgrades.duplicate(),
        "offers": offers.duplicate(true),
        "intermission_purchase_made": intermission_purchase_made,
    }

func complete_current_wave() -> Dictionary:
    if state != &"wave":
        return snapshot()

    var wave_data: Dictionary = Waves.wave(current_wave)
    coins += int(wave_data.get("reward_coins", 0))

    if current_wave >= Waves.wave_count():
        state = &"victory"
        offers.clear()
        intermission_purchase_made = false
        return snapshot()

    state = &"intermission"
    offers = Upgrades.offer_slots_after_wave(current_wave)
    intermission_purchase_made = false
    return snapshot()

func start_next_wave() -> bool:
    if state != &"intermission":
        return false
    if current_wave >= Waves.wave_count():
        return false

    current_wave += 1
    state = &"wave"
    offers.clear()
    intermission_purchase_made = false
    return true

func purchase_upgrade(category: StringName, upgrade_id: StringName) -> bool:
    if state != &"intermission" or intermission_purchase_made:
        return false
    if owned_upgrades.has(upgrade_id):
        return false

    var pool: Array = Upgrades.pool_for(category)
    if not pool.has(upgrade_id):
        return false

    var cost := _cost_for(category)
    if cost < 0 or coins < cost:
        return false

    coins -= cost
    owned_upgrades.append(upgrade_id)
    intermission_purchase_made = true

    if category == &"base" and (upgrade_id == &"base_fortification" or upgrade_id == &"turret_socket"):
        base_tier = mini(base_tier + 1, 3)

    return true

func _cost_for(category: StringName) -> int:
    for offer_variant in offers:
        var offer: Dictionary = offer_variant
        if StringName(offer.get("category", &"")) == category:
            return int(offer.get("cost", -1))
    return -1
