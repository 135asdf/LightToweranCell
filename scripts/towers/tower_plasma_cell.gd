class_name PlasmaCellTower
extends TowerBase

const BULLET_SCENE := preload("res://scenes/towers/tower_plasma_cell_bullet.tscn")

@export var bullet_speed: float = 320.0
@onready var projectile_origin: Marker2D = %ProjectileOrigin

func _fire(target: Node2D, mult: float) -> void:
    if target == null or not target.has_method("take_damage"):
        return
    var bullet := BULLET_SCENE.instantiate()
    get_tree().current_scene.add_child(bullet)
    bullet.global_position = projectile_origin.global_position
    bullet.setup(target, roundi(config.base_damage * mult), bullet_speed)
