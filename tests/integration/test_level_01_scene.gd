extends SceneTree
const TestSuite = preload("res://tests/support/test_suite.gd")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite := TestSuite.new()
    var packed := load("res://scenes/levels/level_01.tscn") as PackedScene
    suite.expect_true(packed != null, "Level 1 scene loads")
    var level := packed.instantiate() as LevelController if packed != null else null
    suite.expect_true(level != null, "Level 1 root is LevelController")
    if level != null:
        suite.expect_true(level.level_data != null, "LevelData assigned")
        suite.expect_true(level.get_node_or_null("World/BuildGrid") is BuildGridComponent, "grid component")
        suite.expect_true(level.get_node_or_null("World/Crystal") is CrystalController, "crystal controller")
        suite.expect_true(level.get_node_or_null("Systems/WaveSpawner") is WaveSpawnerComponent, "wave spawner")
        suite.expect_true(level.get_node_or_null("Systems/TowerPlacement") is TowerPlacementComponent, "placement component")
        suite.expect_true(level.get_node_or_null("Systems/LevelGoal") is LevelGoalComponent, "goal component")
        suite.expect_true(level.get_node_or_null("HUD/ResultPanel") != null, "result panel")
        root.add_child(level)
        await process_frame
        suite.expect_eq(level.build_grid.world_to_cell(level.level_data.grid_config.origin), Vector2i(9, 5), "configured grid")
    suite.finish(self)
