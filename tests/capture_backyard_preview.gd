extends SceneTree

const SnapshotDriver = preload("res://scripts/qa/backyard_snapshot_driver.gd")
const SCENE_PATH := "res://scenes/levels/backyard.tscn"
const OUTPUT_DIR := "res://artifacts"

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var packed = load(SCENE_PATH)
    if packed == null or not packed is PackedScene:
        push_error("Failed to load backyard scene for visual capture")
        quit(1)
        return

    root.size = Vector2i(1280, 720)
    var output_dir := ProjectSettings.globalize_path(OUTPUT_DIR)
    DirAccess.make_dir_recursive_absolute(output_dir)

    for scenario_id in SnapshotDriver.scenario_ids():
        var scene := (packed as PackedScene).instantiate()
        root.add_child(scene)
        await process_frame
        await process_frame

        var runtime = scene.get("runtime")
        if runtime == null:
            push_error("Backyard scene does not expose runtime for visual capture")
            quit(1)
            return

        SnapshotDriver.prepare(runtime, scenario_id)
        if scene.has_method("_refresh_view"):
            scene.call("_refresh_view")

        await process_frame
        await process_frame
        await process_frame

        var image := root.get_texture().get_image()
        if image == null or image.is_empty():
            push_error("Backyard preview capture returned an empty image for %s" % String(scenario_id))
            quit(1)
            return

        var output_path := "%s/%s" % [OUTPUT_DIR, SnapshotDriver.file_name(scenario_id)]
        var err := image.save_png(ProjectSettings.globalize_path(output_path))
        if err != OK:
            push_error("Failed to save backyard preview PNG for %s: %s" % [String(scenario_id), error_string(err)])
            quit(1)
            return

        print("VISUAL SNAPSHOT: %s" % output_path)
        scene.queue_free()
        await process_frame

    quit(0)
