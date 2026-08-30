class_name SlimeComponent
extends Node

@export var slime_scene: PackedScene


func _ready() -> void:
	var owner_enemy := owner as MonsterBase
	if owner_enemy == null:
		push_error("SlimeComponent 必须挂在 MonsterBase 根节点下")
		return
	owner_enemy.died.connect(_on_died)


func _on_died(enemy: MonsterBase) -> void:
	if slime_scene == null:
		push_error("SlimeComponent: 未设置 slime_scene")
		return
	var parent := enemy.get_parent()
	if parent == null:
		return
	var puddle := slime_scene.instantiate()
	parent.add_child(puddle)
	puddle.global_position = enemy.global_position
