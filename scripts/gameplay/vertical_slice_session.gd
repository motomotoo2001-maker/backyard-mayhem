class_name VerticalSliceSession
extends RefCounted

const Waves = preload("res://scripts/gameplay/wave_progression_profile.gd")
const Upgrades = preload("res://scripts/gameplay/between_wave_upgrade_profile.gd")

const BASE_START_HP := 100.0
const BASE_HP_PER_TIER := 25.0

var current_wave: int = 1
var state: StringName = &"wave"
var coins: int = 0
var base_tier: int = 0
var base_hp: float = BASE_START_HP
var owned_upgrades: Array[StringName] = []
var offers: Array = []
var intermission_purchase_made: bool = false

func reset() -> void:
    current_wave = 1
    state = &"wave"
    coins = 0
    base_tier = 0
    base_hp = BASE_START_HP
    owned_upgrades.clear()
    offers.clear()
    intermission_purchase_made = false

func base_max_hp() -> float:
    return BASE_START_HP + float(base_tier) * BASE_HP_PER_TIER

func snapshot() -> Dictionary:
    var max_hp := base_max_hp()
    return {
        "current_wave": current_wave,
        "state": state,
        "coins": coins,
        "base_tier": base_tier,
        "base_hp": base_hp,
        "base_max_hp": max_hp,
        "base_health_ratio": clampf(base_hp / max_hp, 0.0, 1.0) if max_hp > 0.0 else 0.0,
        "owned_upgrades": owned_upgrades.duplicate(),
        "offers": offers.duplicate(true),
        "intermission_purchase_made": intermission_purchase_made,
    }

func damage_base(amount: float) -> bool:
    if amount <= 0.0 or state != &"wave" or base_hp <= 0.0:
        return false

    base_hp = maxf(base_hp - amount, 0.0)
    if base_hp <= 0.0:
        base_hp = 0.0
        state = &"defeat"
        offers.clear()
        intermission_purchase_made = false
    return true

func repair_base(amount: float) -> bool:
    if amount <= 0.0 or state == &"defeat" or base_hp <= 0.0:
        return false
    var repaired := minf(base_hp + amount, base_max_hp())
    if is_equal_approx(repaired, base_hp):
        return false
    base_hp = repaired
    return true

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
        var old_max := base_max_hp()
        base_tier = mini(base_tier + 1, 3)
        base_hp = minf(base_max_hp(), base_hp + (base_max_hp() - old_max))
    elif category == &"utility" and upgrade_id == &"emergency_repair":
        base_hp = base_max_hp()

    return true

func _cost_for(category: StringName) -> int:
    for offer_variant in offers:
        var offer: Dictionary = offer_variant
        if StringName(offer.get("category", &"")) == category:
            return int(offer.get("cost", -1))
    return -1
