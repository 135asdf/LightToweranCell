class_name HealthComponent
extends RefCounted

signal health_changed(current_health: int, max_health: int)
signal died

var _current_health: int = 0
var _max_health: int = 0

func init(max_health: int) -> void:
	_max_health = max_health
	_current_health = max_health

func take_damage(amount: int) -> void:
	_current_health = clampi(_current_health - amount, 0, _max_health)
	health_changed.emit(_current_health,_max_health)
	if _current_health <= 0:
		died.emit()

func heal(amount: int) -> void:
	_current_health = clampi(_current_health + amount, 0, _max_health)
	health_changed.emit(_current_health, _max_health)

func get_health() -> int:
	return _current_health

func get_max_health() -> int:
	return _max_health

func is_dead() -> bool:
	return _current_health <= 0
