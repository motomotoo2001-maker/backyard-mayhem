class_name BackyardBootstrapController
extends Node2D

const RuntimeCoordinator = preload("res://scripts/gameplay/backyard_runtime_coordinator.gd")
const HUDModel = preload("res://scripts/gameplay/backyard_hud_model.gd")
const VisualPresenter = preload("res://scripts/gameplay/backyard_visual_presenter.gd")

var runtime = RuntimeCoordinator.new()

@onready var title_label: Label = $BootstrapUI/Header/Title
@onready var subtitle_label: Label = $BootstrapUI/Header/Subtitle
@onready var badge_label: Label = $BootstrapUI/Badge/BadgeLabel
@onready var status_label: Label = $BootstrapUI/Status
@onready var footer_label: Label = $BootstrapUI/Footer
@onready var boss_alert: ColorRect = $BootstrapUI/BossAlert
@onready var boss_alert_label: Label = $BootstrapUI/BossAlert/Label

@onready var base_visual: Node2D = $BaseVisual
@onready var sandbags: Polygon2D = $BaseVisual/Sandbags
@onready var armor: Polygon2D = $BaseVisual/Armor
@onready var power_cable: Line2D = $BaseVisual/PowerCable
@onready var beacon: Polygon2D = $BaseVisual/Beacon
@onready var power_coils: Node2D = $BaseVisual/PowerCoils
@onready var turret_socket_1: Polygon2D = $BaseVisual/TurretSocket1
@onready var turret_socket_2: Polygon2D = $BaseVisual/TurretSocket2
@onready var turret_socket_3: Polygon2D = $BaseVisual/TurretSocket3

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
    var visual: Dictionary = VisualPresenter.from_runtime(state)

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

    status_label.text = "\n".join(lines)
    footer_label.text = "SPACE: complete/start wave    1/2/3: buy upgrade    R: reset preview"
    _apply_visual_state(visual)

func _apply_visual_state(visual: Dictionary) -> void:
    var base_scale := float(visual.get("base_scale", 1.0))
    base_visual.scale = Vector2.ONE * base_scale
    sandbags.visible = bool(visual.get("show_sandbags", false))
    armor.visible = bool(visual.get("show_armor", false))
    power_cable.visible = bool(visual.get("show_power_cables", false))
    beacon.visible = bool(visual.get("show_beacon", false))
    power_coils.visible = bool(visual.get("show_power_coils", false))

    var slots := int(visual.get("turret_slots", 0))
    turret_socket_1.visible = slots >= 1
    turret_socket_2.visible = slots >= 2
    turret_socket_3.visible = slots >= 3

    boss_alert.visible = bool(visual.get("boss_alert_visible", false))
    boss_alert_label.text = String(visual.get("boss_alert_text", "BOSS WAVE — WATCH THE TELEGRAPHS"))

func _offer_summary(offers: Array) -> String:
    var parts: Array[String] = []
    for offer_variant in offers:
        var offer: Dictionary = offer_variant
        parts.append("%s %d" % [String(offer.get("category", &"?")).to_upper(), int(offer.get("cost", 0))])
    return "   ".join(parts)
