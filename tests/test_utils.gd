class_name TestUtils
extends RefCounted

static var failures: Array[String] = []

static func reset() -> void:
    failures.clear()

static func assert_true(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)

static func assert_eq(actual: Variant, expected: Variant, message: String) -> void:
    if actual != expected:
        failures.append("%s | actual=%s expected=%s" % [message, actual, expected])

static func assert_near(actual: float, expected: float, epsilon: float, message: String) -> void:
    if absf(actual - expected) > epsilon:
        failures.append("%s | actual=%f expected=%f" % [message, actual, expected])
