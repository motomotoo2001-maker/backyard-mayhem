class_name BackyardSnapshotDriver
extends RefCounted

const SCENARIOS: Array[StringName] = [
    &"start",
    &"damaged_upgrade",
    &"boss",
]

const FILE_NAMES := {
    &"start": "backyard-wave1.png",
    &"damaged_upgrade": "backyard-damaged-tier1.png",
    &"boss": "backyard-boss-wave5.png",
}

static func scenario_ids() -> Array[StringName]:
    return SCENARIOS.duplicate()

static func file_name(scenario_id: StringName) -> String:
    return String(FILE_NAMES.get(scenario_id, "backyard-preview.png"))

static func prepare(runtime, scenario_id: StringName) -> Dictionary:
    runtime.reset()

    match scenario_id:
        &"damaged_upgrade":
            runtime.complete_wave()
            runtime.purchase_upgrade(&"base", &"base_fortification")
            runtime.start_next_wave()
            runtime.damage_base(50.0)
        &"boss":
            while int(runtime.snapshot().get("current_wave", 1)) < 5:
                runtime.complete_wave()
                if StringName(runtime.snapshot().get("state", &"")) == &"intermission":
                    runtime.start_next_wave()
        _:
            pass

    return runtime.snapshot()
