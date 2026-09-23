class_name BaseUpgradeVisualProfile
extends RefCounted

const MAX_LEVEL := 3

static func for_level(level: int) -> Dictionary:
    var clamped := clampi(level, 0, MAX_LEVEL)
    match clamped:
        0:
            return {
                "level": 0,
                "turret_slots": 0,
                "show_sandbags": false,
                "show_armor": false,
                "show_power_cables": false,
                "show_beacon": false,
                "show_power_coils": false,
                "silhouette_scale": 1.00,
            }
        1:
            return {
                "level": 1,
                "turret_slots": 1,
                "show_sandbags": true,
                "show_armor": false,
                "show_power_cables": false,
                "show_beacon": false,
                "show_power_coils": false,
                "silhouette_scale": 1.04,
            }
        2:
            return {
                "level": 2,
                "turret_slots": 2,
                "show_sandbags": true,
                "show_armor": true,
                "show_power_cables": true,
                "show_beacon": false,
                "show_power_coils": false,
                "silhouette_scale": 1.08,
            }
        _:
            return {
                "level": 3,
                "turret_slots": 3,
                "show_sandbags": true,
                "show_armor": true,
                "show_power_cables": true,
                "show_beacon": true,
                "show_power_coils": true,
                "silhouette_scale": 1.12,
            }
