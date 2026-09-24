class_name HeroSpriteFramesValidator
extends RefCounted

const Profile = preload("res://scripts/art/hero_animation_profile.gd")
const RunMotionValidator = preload("res://scripts/art/hero_run_motion_validator.gd")

const ACTIONS := [
    &"idle",
    &"run",
    &"fire",
    &"build",
    &"hurt",
    &"dash",
    &"death",
]

static func validate(frames: SpriteFrames) -> Dictionary:
    var missing := PackedStringArray()
    var bad_frame_counts := PackedStringArray()
    var bad_speeds := PackedStringArray()
    var bad_loops := PackedStringArray()
    var missing_textures := PackedStringArray()
    var bad_motion_diversity := PackedStringArray()
    var checked_animations := 0

    if frames == null:
        return {
            "ok": false,
            "checked_animations": 0,
            "missing": PackedStringArray(["<SpriteFrames>"]),
            "bad_frame_counts": bad_frame_counts,
            "bad_speeds": bad_speeds,
            "bad_loops": bad_loops,
            "missing_textures": missing_textures,
            "bad_motion_diversity": bad_motion_diversity,
        }

    for action in ACTIONS:
        for direction in Profile.DIRECTIONS:
            checked_animations += 1
            var animation := StringName(Profile.animation_name(action, direction))
            if not frames.has_animation(animation):
                missing.append(String(animation))
                continue

            var expected_count := Profile.frame_count(action)
            var actual_count := frames.get_frame_count(animation)
            if actual_count != expected_count:
                bad_frame_counts.append(String(animation))

            if not is_equal_approx(frames.get_animation_speed(animation), Profile.fps(action)):
                bad_speeds.append(String(animation))

            if frames.get_animation_loop(animation) != Profile.loops(action):
                bad_loops.append(String(animation))

            var frame_limit := mini(actual_count, expected_count)
            var run_images: Array[Image] = []
            var run_has_missing_texture := false
            for frame_index in range(frame_limit):
                var texture := frames.get_frame_texture(animation, frame_index)
                if texture == null:
                    missing_textures.append("%s:%02d" % [String(animation), frame_index])
                    if action == &"run":
                        run_has_missing_texture = true
                    continue
                if action == &"run":
                    var image := texture.get_image()
                    if image == null or image.is_empty():
                        run_has_missing_texture = true
                    else:
                        run_images.append(image)

            # A correctly named 8-frame RUN still fails production QA if all
            # normalized silhouettes are effectively the same. This filters out
            # legacy whole-body bob/translation masquerading as authored motion.
            if (
                action == &"run"
                and actual_count == expected_count
                and not run_has_missing_texture
                and run_images.size() == expected_count
            ):
                var motion_result: Dictionary = RunMotionValidator.validate_sequence(run_images)
                if not motion_result.get("ok", false):
                    bad_motion_diversity.append(String(animation))

    var ok := (
        missing.is_empty()
        and bad_frame_counts.is_empty()
        and bad_speeds.is_empty()
        and bad_loops.is_empty()
        and missing_textures.is_empty()
        and bad_motion_diversity.is_empty()
    )
    return {
        "ok": ok,
        "checked_animations": checked_animations,
        "missing": missing,
        "bad_frame_counts": bad_frame_counts,
        "bad_speeds": bad_speeds,
        "bad_loops": bad_loops,
        "missing_textures": missing_textures,
        "bad_motion_diversity": bad_motion_diversity,
    }
