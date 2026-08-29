class_name MovementComponent
extends RefCounted

var _speed: float = 0.0
## 减速比例（寒光塔用）
var _slow_percent: float = 0.0


func init(speed: float) -> void:
	_speed = speed

func move_toward(node: Node2D, target_pos: Vector2, delta: float) -> void:
	var dir := (target_pos - node.global_position).normalized()
	node.global_position += dir * _speed * (1.0 - _slow_percent) * delta

func set_speed(new_speed: float) -> void:
	_speed = new_speed

func get_speed() -> float:
	return _speed

func set_slow(percent: float) -> void:
	_slow_percent = clamp(percent, 0.0, 0.8)
