extends RefCounted

var failures: Array[String] = []

func expect_true(value: bool, message: String) -> void:
    if not value:
        failures.append(message)

func expect_eq(actual: Variant, expected: Variant, message: String) -> void:
    if actual != expected:
        failures.append("%s: expected=%s actual=%s" % [message, expected, actual])

func finish(tree: SceneTree) -> void:
    for failure in failures:
        push_error(failure)
    tree.quit(0 if failures.is_empty() else 1)
