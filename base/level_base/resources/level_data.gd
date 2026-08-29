class_name LevelData
extends Resource

@export_group("Identity")
@export var level_id: StringName = &"level_01"
@export var display_name: String = "Level 1"
@export_group("Crystal")
@export_range(1, 100000, 1) var crystal_max_health: int = 100
@export_group("Economy")
@export_range(0, 100000, 1) var starting_energy: int = 100
@export_group("Build")
@export var grid_config: GridConfig
@export var allowed_tower_ids: Array[StringName] = []
@export_group("Waves")
@export var waves: Array[WaveData] = []
