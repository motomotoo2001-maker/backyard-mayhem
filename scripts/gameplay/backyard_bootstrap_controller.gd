class_name BackyardBootstrapController
extends Node2D

const RuntimeCoordinator = preload("res://scripts/gameplay/backyard_runtime_coordinator.gd")
const HUDModel = preload("res://scripts/gameplay/backyard_hud_model.gd")

var runtime = RuntimeCoordinator.new()

@onready var title_label: Label = $BootstrapUI/Header/Title
@onready var subtitle_label: Label = $BootstrapUI/Header/Subtitle
@onready var badge_label: Label = $BootstrapUI/Badge/BadgeLabel
@onready var status_label: Label = $BootstrapUI/Status
@onready var footer_label: Label = $BootstrapUI/Footer

func _ready() -> void:
    _refresh_view()

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey:
        return
    var key_event := event as InputEventKey
    if not key_event.pressed or key_event.echo:
        return

    match key_event.keycode:
        KEY_SPACE:
            _advance_flow()
        KEY_1:
            _purchase_first_available(&"hero")
        KEY_2:
            _purchase_first_available(&"base")
        KEY_3:
            _purchase_first_available(&"utility")
        KEY_R:
            runtime.reset()
            _refresh_view()

func _advance_flow() -> void:
    var state := StringName(runtime.snapshot().get("state", &"wave"))
    match state:
        &"wave":
            runtime.complete_wave()
        &"intermission":
            runtime.start_next_wave()
        &"victory":
            runtime.reset()
    _refresh_view()

func _purchase_first_available(category: StringName) -> void:
    var state: Dictionary = runtime.snapshot()
    if StringName(state.get("state", &"")) != &"intermission":
        return

    var owned: Array = state.get("owned_upgrades", []) as Array
    var offers: Array = state.get("offers", []) as Array
    for offer_variant in offers:
        var offer: Dictionary = offer_variant
        if StringName(offer.get("category", &"")) != category:
            continue
        var pool: Array = offer.get("upgrade_pool", []) as Array
        for upgrade_variant in pool:
            var upgrade_id := StringName(upgrade_variant)
            if owned.has(upgrade_id):
                continue
            runtime.purchase_upgrade(category, upgrade_id)
            _refresh_view()
            return

func _refresh_view() -> void:
    var state: Dictionary = runtime.snapshot()
    var view: Dictionary = HUDModel.from_runtime(state)

    title_label.text = "BACKYARD MAYHEM — %s" % String(view.get("wave_text", "WAVE"))
    subtitle_label.text = String(view.get("state_text", "DEFEND THE YARD"))
    badge_label.text = String(view.get("primary_card", &"status")).replace("_", " ").to_upper()

    var lines: Array[String] = [
        "%s    %s" % [String(view.get("coins_text", "COINS 0")), String(view.get("base_text", "BASE TIER 0"))],
        "%s    %s" % [String(view.get("threat_text", "THREAT 0")), String(view.get("focus_text", ""))],
    ]

    if StringName(state.get("state", &"")) == &"intermission":
        lines.append("")
        lines.append("1 HERO   2 BASE   3 UTILITY")
        lines.append(_offer_summary(state.get("offers", []) as Array))
    elif bool(state.get("is_boss_wave", false)):
        lines.append("")
        lines.append("BOSS WAVE — WATCH THE TELEGRAPHS")

    status_label.text = "\n".join(lines)
    footer_label.text = "SPACE: complete/start wave    1/2/3: buy upgrade    R: reset preview"

func _offer_summary(offers: Array) -> String:
    var parts: Array[String] = []
    for offer_variant in offers:
        var offer: Dictionary = offer_variant
        parts.append("%s %d" % [String(offer.get("category", &"?")).to_upper(), int(offer.get("cost", 0))])
    return "   ".join(parts)
