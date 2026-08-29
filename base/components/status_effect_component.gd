class_name StatusEffectComponent
extends Node

signal speed_multiplier_changed(multiplier: float)

var _resistance := 0.0
var _slow_percent := 0.0
var _remaining := 0.0

func configure(resistance: float) -> void:
    _resistance = clampf(resistance, 0.0, 1.0)

func apply_slow(percent: float, duration: float) -> void:
    _slow_percent = clampf(percent * (1.0 - _resistance), 0.0, 0.8)
    _remaining = maxf(duration * (1.0 - _resistance), 0.0)
    speed_multiplier_changed.emit(1.0 - _slow_percent)

func _process(delta: float) -> void:
    if _remaining <= 0.0:
        return
    _remaining = maxf(0.0, _remaining - delta)
    if _remaining == 0.0:
        _slow_percent = 0.0
        speed_multiplier_changed.emit(1.0)
