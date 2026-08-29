class_name EnemySpawnEntry
extends Resource

@export var enemy_scene: PackedScene
@export_range(1, 10000, 1) var count: int = 1
@export_range(0.0, 60.0, 0.05, "suffix:s") var interval: float = 1.0
@export var spawn_point_id: StringName = &"north"
