extends SceneTree

const PlayerVFXEmitter = preload("res://scripts/player/player_vfx_emitter.gd")
const OUTPUT_PATH := "res://artifacts/player-vfx-preview.png"

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    root.size = Vector2i(960, 540)
    var output_dir := ProjectSettings.globalize_path("res://artifacts")
    DirAccess.make_dir_recursive_absolute(output_dir)

    var stage := Node2D.new()
    stage.name = "PlayerVFXPreview"
    root.add_child(stage)

    var background := Polygon2D.new()
    background.polygon = PackedVector2Array([
        Vector2(0, 0),
        Vector2(960, 0),
        Vector2(960, 540),
        Vector2(0, 540),
    ])
    background.color = Color(0.035, 0.055, 0.065, 1.0)
    stage.add_child(background)

    var emitter := PlayerVFXEmitter.new()
    emitter.name = "Emitter"
    stage.add_child(emitter)

    var muzzle := emitter.spawn_effect(&"muzzle_flash", Vector2(235, 260), Vector2.RIGHT, 2.4, 2.0)
    var blast := emitter.spawn_effect(&"air_blast", Vector2(585, 260), Vector2.RIGHT, 2.1, 2.0)
    if muzzle == null or blast == null:
        push_error("Failed to spawn player VFX preview nodes")
        quit(1)
        return

    _add_label(stage, "MUZZLE FLASH", Vector2(150, 350))
    _add_label(stage, "AIR BLAST", Vector2(540, 350))
    _add_label(stage, "FRAME-SYNCED FIRE VFX", Vector2(330, 70), 26)

    await process_frame
    await process_frame
    await process_frame

    var image := root.get_texture().get_image()
    if image == null or image.is_empty():
        push_error("Player VFX preview capture returned an empty image")
        quit(1)
        return

    var err := image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
    if err != OK:
        push_error("Failed to save player VFX preview PNG: %s" % error_string(err))
        quit(1)
        return

    print("VISUAL SNAPSHOT: %s" % OUTPUT_PATH)
    quit(0)

func _add_label(parent: Node, text_value: String, position_value: Vector2, font_size: int = 20) -> void:
    var label := Label.new()
    label.text = text_value
    label.position = position_value
    label.add_theme_color_override("font_color", Color(0.86, 0.93, 0.96, 1.0))
    label.add_theme_font_size_override("font_size", font_size)
    parent.add_child(label)
