class_name BuildGridComponent
extends Node2D

signal occupancy_changed(cell: Vector2i, occupied: bool)

##格子场景
@export var grid_cell_scene: PackedScene
@export var grid_z_index: int = -5

const GRID_CELL_DESIGN_SIZE := 64.0

var _config: GridConfig
var _occupied: Dictionary[Vector2i, Node2D] = {}

func configure(config: GridConfig) -> void:
	_config = config
	_occupied.clear()
	_clear_grid_cells()
	if grid_cell_scene != null:
		_spawn_grid_cells()

func world_to_cell(world_position: Vector2) -> Vector2i:
	var top_left := _config.origin - Vector2(_config.columns - 1, _config.rows - 1) * _config.spacing * 0.5
	var local := world_position - top_left
	return Vector2i(roundi(local.x / _config.spacing), roundi(local.y / _config.spacing))

func cell_to_world(cell: Vector2i) -> Vector2:
	var top_left := _config.origin - Vector2(_config.columns - 1, _config.rows - 1) * _config.spacing * 0.5
	return top_left + Vector2(cell) * _config.spacing

func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < _config.columns and cell.y < _config.rows

func can_build(cell: Vector2i) -> bool:
	return is_inside(cell) and cell not in _config.blocked_cells and not _occupied.has(cell)

func occupy(cell: Vector2i, tower: Node2D) -> bool:
	if not can_build(cell):
		return false
	_occupied[cell] = tower
	occupancy_changed.emit(cell, true)
	return true

func release(cell: Vector2i) -> bool:
	if not _occupied.erase(cell):
		return false
	occupancy_changed.emit(cell, false)
	return true

func is_occupied(cell: Vector2i) -> bool:
	return _occupied.has(cell)

func get_occupant(cell: Vector2i) -> Node2D:
	return _occupied.get(cell) as Node2D

func _clear_grid_cells() -> void:
	for child in get_children():
		if child is GridCell:
			child.queue_free()

## 按 GridConfig 铺满格子实例：位置由 cell_to_world 决定，纯视觉
func _spawn_grid_cells() -> void:
	if _config == null or grid_cell_scene == null:
		return
	for row in range(_config.rows):
		for col in range(_config.columns):
			var cell := Vector2i(col, row)
			var cell_node := grid_cell_scene.instantiate() as GridCell
			if cell_node == null:
				push_error("grid_cell_scene根节点必须为GridCell")
				continue
			add_child(cell_node)
			cell_node.z_index = grid_z_index
			cell_node.setup(cell)
			cell_node.position = to_local(cell_to_world(cell))
			cell_node.scale = Vector2(_config.spacing, _config.spacing) / GRID_CELL_DESIGN_SIZE
