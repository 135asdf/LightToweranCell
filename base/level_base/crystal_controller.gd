class_name CrystalController
extends Area2D

signal crystal_destroyed

@onready var health_component: HealthComponent = %HealthComponent

func _ready() -> void:
    health_component.died.connect(crystal_destroyed.emit)

func configure(max_health: int) -> void:
    health_component.configure(max_health)

func take_contact_damage(amount: int) -> void:
    health_component.take_damage(amount)
