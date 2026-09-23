class_name HeroSpriteFramesValidator
extends RefCounted

const Profile = preload("res://scripts/art/hero_animation_profile.gd")

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
            for frame_index in range(frame_limit):
                if frames.get_frame_texture(animation, frame_index) == null:
                    missing_textures.append("%s:%02d" % [String(animation), frame_index])

    var ok := (
        missing.is_empty()
        and bad_frame_counts.is_empty()
        and bad_speeds.is_empty()
        and bad_loops.is_empty()
        and missing_textures.is_empty()
    )
    return {
        "ok": ok,
        "checked_animations": checked_animations,
        "missing": missing,
        "bad_frame_counts": bad_frame_counts,
        "bad_speeds": bad_speeds,
        "bad_loops": bad_loops,
        "missing_textures": missing_textures,
    }
