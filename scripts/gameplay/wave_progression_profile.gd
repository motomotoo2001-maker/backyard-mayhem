class_name WaveProgressionProfile
extends RefCounted

const WAVES := [
    {
        "number": 1,
        "threat_budget": 10,
        "reward_coins": 100,
        "intermission_seconds": 10.0,
        "enemy_pool": [&"raccoon"],
        "is_boss_wave": false,
        "focus": &"fundamentals",
    },
    {
        "number": 2,
        "threat_budget": 18,
        "reward_coins": 140,
        "intermission_seconds": 10.0,
        "enemy_pool": [&"raccoon", &"cat"],
        "is_boss_wave": false,
        "focus": &"speed_pressure",
    },
    {
        "number": 3,
        "threat_budget": 29,
        "reward_coins": 190,
        "intermission_seconds": 12.0,
        "enemy_pool": [&"raccoon", &"cat", &"bulldog", &"pigeon"],
        "is_boss_wave": false,
        "focus": &"heavy_and_air",
    },
    {
        "number": 4,
        "threat_budget": 43,
        "reward_coins": 240,
        "intermission_seconds": 12.0,
        "enemy_pool": [&"raccoon", &"cat", &"bulldog", &"pigeon", &"neighbor_kid", &"skateboard_teen"],
        "is_boss_wave": false,
        "focus": &"mixed_pressure",
    },
    {
        "number": 5,
        "threat_budget": 65,
        "reward_coins": 350,
        "intermission_seconds": 10.0,
        "enemy_pool": [&"raccoon", &"cat", &"bulldog", &"pigeon", &"neighbor_kid", &"skateboard_teen", &"boss"],
        "is_boss_wave": true,
        "focus": &"finale",
    },
]

static func wave_count() -> int:
    return WAVES.size()

static func wave(wave_number: int) -> Dictionary:
    var index := clampi(wave_number, 1, wave_count()) - 1
    return (WAVES[index] as Dictionary).duplicate(true)
