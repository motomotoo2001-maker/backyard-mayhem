extends SceneTree

const OUTPUT_PATH := "res://artifacts/backyard-preview.png"

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var packed = load("res://scenes/levels/backyard.tscn")
    if packed == null or not packed is PackedScene:
        push_error("Failed to load backyard scene for visual capture")
        quit(1)
        return

    var scene := (packed as PackedScene).instantiate()
    root.size = Vector2i(1280, 720)
    root.add_child(scene)

    await process_frame
    await process_frame
    await process_frame

    var image := root.get_texture().get_image()
    if image == null or image.is_empty():
        push_error("Backyard preview capture returned an empty image")
        quit(1)
        return

    var output_dir := ProjectSettings.globalize_path("res://artifacts")
    DirAccess.make_dir_recursive_absolute(output_dir)
    var err := image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
    if err != OK:
        push_error("Failed to save backyard preview PNG: %s" % error_string(err))
        quit(1)
        return

    print("VISUAL SNAPSHOT: %s" % OUTPUT_PATH)
    quit(0)
