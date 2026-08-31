extends SceneTree
const TestSuite = preload("res://tests/support/test_suite.gd")
const LevelScene = preload("res://scenes/levels/level_01.tscn")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite := TestSuite.new()

    # --- Inventory 单元 ---
    var inv := Inventory.new()
    inv.add(&"plasma_cell")
    inv.add(&"plasma_cell", 2)
    suite.expect_eq(inv.count(&"plasma_cell"), 3, "inventory add counts")
    suite.expect_true(inv.remove(&"plasma_cell", 2), "inventory remove ok")
    suite.expect_eq(inv.count(&"plasma_cell"), 1, "inventory count after remove")
    suite.expect_true(not inv.remove(&"plasma_cell", 5), "inventory remove rejects overspend")
    suite.expect_eq(inv.count(&"plasma_cell"), 1, "inventory unchanged on failed remove")

    # --- 关卡：背包消耗/占格/回收（用全局背包，预置数量保证可选） ---
    GameState.inventory.add(&"plasma_cell", 5)
    var level := LevelScene.instantiate() as LevelController
    root.add_child(level)
    await process_frame
    var before := level.inventory.count(&"plasma_cell")
    suite.expect_true(before >= 1, "starting inventory has plasma cell")

    level.placement.select_tower(&"plasma_cell")
    var cell := Vector2i(0, 0)
    var tower := level.placement.place_at_world(level.build_grid.cell_to_world(cell))
    suite.expect_true(tower != null, "tower placed")
    suite.expect_eq(level.inventory.count(&"plasma_cell"), before - 1, "placement consumes one")
    suite.expect_true(level.build_grid.is_occupied(cell), "cell occupied after placement")

    # 塔损坏：仍占格、不释放
    tower.take_damage(100000)
    await process_frame
    suite.expect_true(tower.is_destroyed, "tower destroyed")
    suite.expect_true(level.build_grid.is_occupied(cell), "destroyed tower keeps cell occupied")

    # 结算回收：塔回背包
    level._finish_level(true)
    suite.expect_eq(level.inventory.count(&"plasma_cell"), before, "tower recovered to inventory")
    paused = false
    suite.finish(self)
