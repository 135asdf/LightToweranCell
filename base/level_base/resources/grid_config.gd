class_name GridConfig
extends Resource

@export_range(1, 128, 1) var columns: int = 19
@export_range(1, 128, 1) var rows: int = 11
@export_range(1.0, 256.0, 1.0, "suffix:px") var spacing: float = 64.0
@export var origin: Vector2 = Vector2(960, 540)
@export var blocked_cells: Array[Vector2i] = [Vector2i(9, 5)]
