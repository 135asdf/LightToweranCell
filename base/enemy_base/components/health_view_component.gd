class_name HealthViewComponent
extends Node

@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label = %HealthNumber

func bind(health: HealthComponent) -> void:
	health.health_changed.connect(_on_health_changed)
	_on_health_changed(health.get_health(), health.get_max_health())

func _on_health_changed(current: int, maximum: int) -> void:
	if health_bar != null:
		health_bar.max_value = maximum
		health_bar.value = current
	if health_label != null:
		health_label.text = "%d/%d" % [current, maximum]
