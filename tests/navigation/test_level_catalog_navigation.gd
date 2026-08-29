extends SceneTree
const TestSuite = preload("res://tests/support/test_suite.gd")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite := TestSuite.new()
    var catalog := load("res://data/catalogs/level_catalog.tres") as LevelCatalog
    suite.expect_true(catalog != null, "LevelCatalog loads")
    suite.expect_eq(catalog.entries.size(), 1, "one available level")
    suite.expect_true(catalog.entries[0].scene != null, "catalog scene assigned")
    # -s 模式不加载 autoload：手动实例化 SceneManager 模拟
    var sm: Node = (load("res://base/Managers/SceneManager.gd") as GDScript).new()
    sm.set("level_catalog", catalog)
    sm.name = "SceneManager"
    root.add_child(sm)
    suite.expect_true(sm.resolve_level_scene(&"level_01") == catalog.entries[0].scene, "SceneManager resolves catalog scene")

    var selection_scene := load("res://ui/LevelSelection/level_selection.tscn") as PackedScene
    var selection := selection_scene.instantiate()
    root.add_child(selection)
    await process_frame
    var buttons := selection.get_node("VBoxContainer/LevelButtons").get_children()
    suite.expect_eq(buttons.size(), 1, "one generated level button")
    suite.expect_eq(buttons[0].get_meta("level_id"), &"level_01", "button level id")
    suite.expect_true(not buttons[0].disabled, "default level unlocked")
    suite.finish(self)
