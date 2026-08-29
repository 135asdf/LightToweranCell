class_name ContactDamageComponent
extends Node

signal contact_damage_applied(target: Node2D, amount: int)

var _target_component: TargetComponent
var _damage: int = 0
var _applied: bool = false

func configure(target: TargetComponent, damage: int) -> void:
    _target_component = target
    _damage = maxi(0, damage)
    _applied = false

func apply_once() -> bool:
    if _applied or _target_component == null:
        return false
    var target := _target_component.get_target()
    if target == null or not target.has_method("take_contact_damage"):
        return false
    _applied = true
    target.take_contact_damage(_damage)
    contact_damage_applied.emit(target, _damage)
    return true
