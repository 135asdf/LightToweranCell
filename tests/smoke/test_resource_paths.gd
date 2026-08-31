extends SceneTree

const TestSuite = preload("res://tests/support/test_suite.gd")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite := TestSuite.new()
    var required := [
        "res://ui/Main/main.tscn",
        "res://ui/LevelSelection/level_selection.tscn",
        "res://ui/Lab/lab.tscn",
        "res://scenes/levels/level_01.tscn",
        "res://base/enemy_base/enemy_base.tscn",
        "res://scenes/enemies/normal/enemy_streptococcus.tscn",
        "res://scenes/enemies/normal/enemy_flagellate.tscn",
        "res://scenes/towers/light_tower.tscn",
    ]
    for path in required:
        suite.expect_true(ResourceLoader.exists(path), "missing resource: %s" % path)
        if ResourceLoader.exists(path):
            suite.expect_true(ResourceLoader.load(path) != null, "failed to load: %s" % path)
    suite.finish(self)
