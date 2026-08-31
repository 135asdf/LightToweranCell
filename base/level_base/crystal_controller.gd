class_name CrystalController
extends Area2D

signal crystal_destroyed

@onready var health_component: HealthComponent = %HealthComponent
@onready var health_view_component: HealthViewComponent = %HealthViewComponent


func _ready() -> void:
	health_component.died.connect(crystal_destroyed.emit)
	health_view_component.bind(health_component)

func configure(max_health: int) -> void:
	health_component.configure(max_health)

func take_contact_damage(amount: int) -> void:
	health_component.take_damage(amount)
