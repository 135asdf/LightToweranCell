extends SceneTree
const TestSuite = preload("res://tests/support/test_suite.gd")
const EnemyScene = preload("res://scenes/enemies/enemy_streptococcus.tscn")

class DamageTarget extends Node2D:
    var received := 0
    func take_contact_damage(amount: int) -> void:
        received += amount

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite := TestSuite.new()
    var enemy := EnemyScene.instantiate() as MonsterBase
    var target := DamageTarget.new()
    root.add_child(target)
    root.add_child(enemy)
    suite.expect_true(enemy != null, "enemy scene root is MonsterBase")
    suite.expect_true(enemy.get_node_or_null("HealthComponent") is HealthComponent, "health node exists")
    suite.expect_true(enemy.get_node_or_null("MovementComponent") is MovementComponent, "movement node exists")
    enemy.setup_target(target)
    enemy.take_damage(25)
    suite.expect_eq(enemy.health_component.get_health(), 75, "damage delegates to health")
    suite.expect_true(enemy.is_in_group("enemy"), "canonical group")
    suite.expect_true(not enemy.is_in_group("1_enemy"), "legacy group removed")
    suite.finish(self)
