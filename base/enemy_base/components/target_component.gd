class_name TargetComponent
extends Node

signal target_changed(target: Node2D)
signal target_lost

var _target: Node2D

func set_target(target: Node2D) -> void:
    _target = target
    target_changed.emit(_target)

func get_target() -> Node2D:
    if _target != null and is_instance_valid(_target):
        return _target
    if _target != null:
        _target = null
        target_lost.emit()
    return null
