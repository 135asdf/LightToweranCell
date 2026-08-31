extends SceneTree
const TestSuite = preload("res://tests/support/test_suite.gd")
const PlasmaScene = preload("res://scenes/towers/tower_plasma_cell.tscn")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite := TestSuite.new()
    var data := TowerData.new()
    data.max_health = 100
    data.max_shield = 30
    data.shield_regen_per_sec = 10.0
    var tower := PlasmaScene.instantiate() as TowerBase
    tower.config = data
    root.add_child(tower)
    await process_frame

    # 先扣护盾，血量不动
    tower.take_damage(20)
    suite.expect_eq(tower.shield_component.get_shield(), 10, "shield absorbs 20")
    suite.expect_eq(tower.health_component.get_health(), 100, "health untouched")
    # 护盾耗尽后溢出扣血
    tower.take_damage(30)
    suite.expect_eq(tower.shield_component.get_shield(), 0, "shield depleted")
    suite.expect_eq(tower.health_component.get_health(), 80, "overflow hits health")

    # 护盾回复（10/s，等 2 秒）
    for i in range(120):
        await process_frame
    suite.expect_true(tower.shield_component.get_shield() > 0, "shield regens over time")

    # 摧毁
    tower.take_damage(10000)
    suite.expect_true(tower.is_destroyed, "tower destroyed")
    var mode_before := tower.power_model
    tower.cycle_mode()
    suite.expect_eq(tower.power_model, mode_before, "destroyed tower cannot switch mode")
    suite.finish(self)
