class_name HealthComponent
extends Node

signal health_changed(current_health: int, max_health: int)
signal died

var _current_health: int = 0
var _max_health: int = 1
var _armor: float = 0.0
var _death_emitted: bool = false

func configure(max_health: int, armor: float = 0.0) -> void:
	_max_health = maxi(1, max_health)
	_current_health = _max_health
	_armor = clampf(armor, 0.0, 0.95)
	_death_emitted = false
	health_changed.emit(_current_health, _max_health)

func take_damage(amount: int) -> int:
	if amount <= 0 or is_dead():
		return 0
	var applied := maxi(1, roundi(amount * (1.0 - _armor)))
	applied = mini(applied, _current_health)
	_current_health -= applied
	health_changed.emit(_current_health, _max_health)
	if _current_health == 0 and not _death_emitted:
		_death_emitted = true
		died.emit()
	return applied

func heal(amount: int) -> int:
	if amount <= 0 or is_dead():
		return 0
	var before := _current_health
	_current_health = mini(_current_health + amount, _max_health)
	health_changed.emit(_current_health, _max_health)
	return _current_health - before

func get_health() -> int:
	return _current_health

func get_max_health() -> int:
	return _max_health

func is_dead() -> bool:
	return _current_health <= 0
