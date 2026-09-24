class_name PlayerVFXEmitter
extends Node2D

const MUZZLE_OUTER_COLOR := Color(1.0, 0.56, 0.12, 0.92)
const MUZZLE_CORE_COLOR := Color(1.0, 0.94, 0.62, 1.0)
const MUZZLE_SPARK_COLOR := Color(1.0, 0.76, 0.24, 0.82)
const AIR_INNER_COLOR := Color(0.82, 0.95, 1.0, 0.72)
const AIR_OUTER_COLOR := Color(0.52, 0.86, 1.0, 0.42)
const AIR_WISP_COLOR := Color(0.72, 0.92, 1.0, 0.5)

static func build_effect_node(effect_name: StringName, direction: Vector2, effect_scale: float = 1.0) -> Node2D:
    var normalized_direction := direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT
    var root := Node2D.new()
    root.rotation = normalized_direction.angle()
    root.scale = Vector2.ONE * maxf(effect_scale, 0.01)
    root.set_meta("effect_name", String(effect_name))

    match effect_name:
        &"muzzle_flash":
            root.name = "MuzzleFlash"
            _build_muzzle_flash(root)
        &"air_blast":
            root.name = "AirBlast"
            _build_air_blast(root)
        _:
            root.free()
            return null

    return root

func spawn_effect(
    effect_name: StringName,
    local_origin: Vector2,
    direction: Vector2,
    effect_scale: float = 1.0,
    lifetime: float = 0.1
) -> Node2D:
    var effect := build_effect_node(effect_name, direction, effect_scale)
    if effect == null:
        return null

    var safe_lifetime := maxf(lifetime, 0.01)
    effect.position = local_origin
    effect.set_meta("effect_lifetime", safe_lifetime)
    add_child(effect)

    if is_inside_tree():
        var target_scale := effect.scale * 1.18
        var tween := effect.create_tween()
        tween.set_parallel(true)
        tween.tween_property(effect, "modulate:a", 0.0, safe_lifetime)
        tween.tween_property(effect, "scale", target_scale, safe_lifetime)
        tween.set_parallel(false)
        tween.tween_callback(effect.queue_free)

    return effect

static func _build_muzzle_flash(root: Node2D) -> void:
    var outer := Polygon2D.new()
    outer.name = "OuterFlash"
    outer.polygon = PackedVector2Array([
        Vector2(0, 0),
        Vector2(17, -9),
        Vector2(46, 0),
        Vector2(17, 9),
    ])
    outer.color = MUZZLE_OUTER_COLOR
    root.add_child(outer)

    var core := Polygon2D.new()
    core.name = "CoreFlash"
    core.polygon = PackedVector2Array([
        Vector2(0, 0),
        Vector2(11, -4),
        Vector2(29, 0),
        Vector2(11, 4),
    ])
    core.color = MUZZLE_CORE_COLOR
    root.add_child(core)

    var spark_top := Line2D.new()
    spark_top.name = "SparkTop"
    spark_top.points = PackedVector2Array([
        Vector2(9, -4),
        Vector2(28, -15),
        Vector2(51, -21),
    ])
    spark_top.width = 2.4
    spark_top.default_color = MUZZLE_SPARK_COLOR
    spark_top.begin_cap_mode = Line2D.LINE_CAP_ROUND
    spark_top.end_cap_mode = Line2D.LINE_CAP_ROUND
    root.add_child(spark_top)

    var spark_bottom := Line2D.new()
    spark_bottom.name = "SparkBottom"
    spark_bottom.points = PackedVector2Array([
        Vector2(9, 4),
        Vector2(28, 15),
        Vector2(51, 21),
    ])
    spark_bottom.width = 2.4
    spark_bottom.default_color = MUZZLE_SPARK_COLOR
    spark_bottom.begin_cap_mode = Line2D.LINE_CAP_ROUND
    spark_bottom.end_cap_mode = Line2D.LINE_CAP_ROUND
    root.add_child(spark_bottom)

static func _build_air_blast(root: Node2D) -> void:
    var inner := Line2D.new()
    inner.name = "InnerArc"
    inner.points = PackedVector2Array([
        Vector2(12, -16),
        Vector2(29, -11),
        Vector2(43, 0),
        Vector2(29, 11),
        Vector2(12, 16),
    ])
    inner.width = 4.0
    inner.default_color = AIR_INNER_COLOR
    inner.begin_cap_mode = Line2D.LINE_CAP_ROUND
    inner.end_cap_mode = Line2D.LINE_CAP_ROUND
    root.add_child(inner)

    var outer := Line2D.new()
    outer.name = "OuterArc"
    outer.points = PackedVector2Array([
        Vector2(20, -27),
        Vector2(43, -18),
        Vector2(64, 0),
        Vector2(43, 18),
        Vector2(20, 27),
    ])
    outer.width = 2.5
    outer.default_color = AIR_OUTER_COLOR
    outer.begin_cap_mode = Line2D.LINE_CAP_ROUND
    outer.end_cap_mode = Line2D.LINE_CAP_ROUND
    root.add_child(outer)

    var upper_wisp := Line2D.new()
    upper_wisp.name = "UpperWisp"
    upper_wisp.points = PackedVector2Array([
        Vector2(10, -8),
        Vector2(28, -24),
        Vector2(52, -31),
        Vector2(78, -24),
    ])
    upper_wisp.width = 1.8
    upper_wisp.default_color = AIR_WISP_COLOR
    upper_wisp.begin_cap_mode = Line2D.LINE_CAP_ROUND
    upper_wisp.end_cap_mode = Line2D.LINE_CAP_ROUND
    root.add_child(upper_wisp)

    var lower_wisp := Line2D.new()
    lower_wisp.name = "LowerWisp"
    lower_wisp.points = PackedVector2Array([
        Vector2(10, 8),
        Vector2(28, 24),
        Vector2(52, 31),
        Vector2(78, 24),
    ])
    lower_wisp.width = 1.8
    lower_wisp.default_color = AIR_WISP_COLOR
    lower_wisp.begin_cap_mode = Line2D.LINE_CAP_ROUND
    lower_wisp.end_cap_mode = Line2D.LINE_CAP_ROUND
    root.add_child(lower_wisp)
