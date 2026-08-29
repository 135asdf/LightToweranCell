extends SceneTree
const TestSuite = preload("res://tests/support/test_suite.gd")

class DamageTarget extends Node2D:
    var received: int = 0
    func take_contact_damage(amount: int) -> void:
        received += amount

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite := TestSuite.new()
    var body := CharacterBody2D.new()
    var target := DamageTarget.new()
    var target_component := TargetComponent.new()
    var movement := MovementComponent.new()
    var contact := ContactDamageComponent.new()
    root.add_child(body)
    root.add_child(target)
    body.add_child(target_component)
    body.add_child(movement)
    body.add_child(contact)
    target.position = Vector2(10, 0)
    target_component.set_target(target)
    movement.configure(body, target_component, 100.0, 2.0)
    movement.start()
    contact.configure(target_component, 12)
    movement.tick(0.05)
    suite.expect_true(body.position.x > 0.0, "body moves toward target")
    contact.apply_once()
    contact.apply_once()
    suite.expect_eq(target.received, 12, "contact damage applies once")
    suite.finish(self)
