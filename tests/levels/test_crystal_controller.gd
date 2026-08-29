extends SceneTree
const TestSuite = preload("res://tests/support/test_suite.gd")
const CrystalScene = preload("res://base/level_base/crystal_base.tscn")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite := TestSuite.new()
    var crystal := CrystalScene.instantiate() as CrystalController
    root.add_child(crystal)
    var destroyed := [0]
    crystal.crystal_destroyed.connect(func(): destroyed[0] += 1)
    crystal.configure(20)
    crystal.take_contact_damage(7)
    suite.expect_eq(crystal.health_component.get_health(), 13, "contact damage")
    crystal.take_contact_damage(20)
    crystal.take_contact_damage(20)
    suite.expect_eq(destroyed[0], 1, "destroyed once")
    suite.finish(self)
