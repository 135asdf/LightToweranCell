class_name WaveData
extends Resource

@export_range(0.0, 120.0, 0.1, "suffix:s") var start_delay: float = 0.0
@export_range(0.0, 120.0, 0.1, "suffix:s") var end_delay: float = 1.0
@export var wait_for_clear: bool = true
@export var entries: Array[EnemySpawnEntry] = []
