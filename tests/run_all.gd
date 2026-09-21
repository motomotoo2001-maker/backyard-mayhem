extends SceneTree

const TestUtils = preload("res://tests/test_utils.gd")

func _initialize() -> void:
    TestUtils.reset()
    var files := DirAccess.get_files_at("res://tests")
    files.sort()
    var executed := 0
    for file_name in files:
        if not file_name.begins_with("test_") or not file_name.ends_with(".gd"):
            continue
        if file_name == "test_utils.gd":
            continue
        var script := load("res://tests/%s" % file_name)
        if script == null:
            TestUtils.failures.append("Could not load %s" % file_name)
            continue
        var test_case = script.new()
        if not test_case.has_method("run"):
            TestUtils.failures.append("%s has no run()" % file_name)
            continue
        executed += 1
        test_case.run()
    for failure in TestUtils.failures:
        printerr("FAIL: %s" % failure)
    print("TEST SUMMARY: %d test files, %d failures" % [executed, TestUtils.failures.size()])
    quit(1 if not TestUtils.failures.is_empty() else 0)
