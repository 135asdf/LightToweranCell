class_name ShieldComponent
extends Node

signal shield_changed(current: int, max: int)

var _current: int = 0
var _max: int = 0
var _regen_per_sec: float = 0.0
var _regen_acc: float = 0.0

func configure(max_shield: int, regen_per_sec: float) -> void:
	_max = maxi(0, max_shield)
	_current = _max
	_regen_per_sec = maxf(0.0, regen_per_sec)
	_regen_acc = 0.0
	shield_changed.emit(_current, _max)
	
##扣护盾，返回没能吸收，溢出到血量的伤害
func take_damage(amount: int) -> int:
	if amount <= 0 or _current <= 0:
		return amount
	var absorbed := mini(amount, _current)
	_current -= absorbed
	shield_changed.emit(_current, _max)
	return amount - absorbed

func heal_shield(amount: int) -> void:
	if amount <= 0:
		return
	_current = mini(_max, _current + amount)
	shield_changed.emit(_current, _max)
	
func get_shield() -> int:
	return _current

func get_max_shield() -> int:
	return _max

func is_broken() -> bool:
	return _current <= 0

##护盾随时间回复
func _process(delta: float) -> void:
	if _current >= _max or _regen_per_sec <= 0.0:
		return
	_regen_acc += _regen_per_sec * delta
	if _regen_acc >= 1.0:
		var gain := int(_regen_acc)
		_regen_acc -= gain
		_current = mini(_max, _current + gain)
		shield_changed.emit(_current, _max)
