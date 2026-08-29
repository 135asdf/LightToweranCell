extends SceneTree
const TestSuite = preload("res://tests/support/test_suite.gd")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite := TestSuite.new()
    var health := HealthComponent.new()
    root.add_child(health)
    var death_count := [0]
    health.died.connect(func(): death_count[0] += 1)
    health.configure(100, 0.25)
    suite.expect_eq(health.take_damage(40), 30, "armor-adjusted damage")
    suite.expect_eq(health.get_health(), 70, "health after damage")
    suite.expect_eq(health.heal(100), 30, "healing is capped")
    health.take_damage(1000)
    health.take_damage(1000)
    suite.expect_eq(death_count[0], 1, "death emits once")
    suite.expect_true(health.is_dead(), "dead state")
    suite.finish(self)
