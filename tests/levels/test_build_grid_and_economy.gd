extends SceneTree
const TestSuite = preload("res://tests/support/test_suite.gd")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite := TestSuite.new()
    var config := GridConfig.new()
    var grid := BuildGridComponent.new()
    var economy := EconomyComponent.new()
    root.add_child(grid)
    root.add_child(economy)
    grid.configure(config)
    suite.expect_eq(grid.world_to_cell(config.origin), Vector2i(9, 5), "center cell")
    suite.expect_true(not grid.can_build(Vector2i(9, 5)), "blocked crystal cell")
    suite.expect_true(grid.occupy(Vector2i(0, 0), Node2D.new()), "first occupancy")
    suite.expect_true(not grid.occupy(Vector2i(0, 0), Node2D.new()), "duplicate occupancy")
    economy.configure(20)
    suite.expect_true(economy.try_spend(15), "affordable spend")
    suite.expect_true(not economy.try_spend(10), "reject overspend")
    suite.expect_eq(economy.get_balance(), 5, "remaining balance")
    suite.finish(self)
