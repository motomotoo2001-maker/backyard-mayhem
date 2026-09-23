class_name BulldogFrameManifest
extends RefCounted

const Profile = preload("res://scripts/art/bulldog_animation_profile.gd")
const EnemyPolicy = preload("res://scripts/art/enemy_asset_policy.gd")

static func required_filenames() -> Array[String]:
    var result: Array[String] = []
    for action in Profile.actions():
        for frame_index in range(Profile.frame_count(action)):
            result.append("%s_%02d.png" % [String(action), frame_index])
    return result

static func required_paths() -> Array[String]:
    var result: Array[String] = []
    for action in Profile.actions():
        for frame_index in range(Profile.frame_count(action)):
            var filename := "%s_%02d.png" % [String(action), frame_index]
            result.append("%sbulldog/%s/%s" % [EnemyPolicy.RUNTIME_ROOT, String(action), filename])
    return result
