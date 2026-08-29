extends SceneTree
const TestSuite = preload("res://tests/support/test_suite.gd")
const PlasmaScene = preload("res://scenes/towers/tower_plasma_cell.tscn")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite := TestSuite.new()
    var grid := BuildGridComponent.new()
    var economy := EconomyComponent.new()
    var towers := Node2D.new()
    var placement := TowerPlacementComponent.new()
    root.add_child(grid)
    root.add_child(economy)
    root.add_child(towers)
    root.add_child(placement)
    var config := GridConfig.new()
    config.blocked_cells = []
    grid.configure(config)
    economy.configure(100)

    var data := TowerData.new()
    data.tower_id = &"plasma_cell"
    data.build_cost = 20
    var entry := TowerCatalogEntry.new()
    entry.tower_id = &"plasma_cell"
    entry.data = data
    entry.scene = PlasmaScene
    var catalog := TowerCatalog.new()
    catalog.entries = [entry]
    placement.configure(catalog, [&"plasma_cell"], grid, economy, towers)
    suite.expect_true(placement.select_tower(&"plasma_cell"), "tower selection")
    var placed := placement.place_at_world(grid.cell_to_world(Vector2i(0, 0)))
    suite.expect_true(placed is TowerBase, "placed root uses TowerBase")
    suite.expect_eq(economy.get_balance(), 80, "build cost deducted")
    suite.expect_true(grid.is_occupied(Vector2i(0, 0)), "cell occupied")
    suite.expect_true(placement.place_at_world(grid.cell_to_world(Vector2i(0, 0))) == null, "duplicate placement rejected")
    suite.finish(self)
