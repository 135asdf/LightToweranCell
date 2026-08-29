class_name BuildGridComponent
extends Node2D

signal occupancy_changed(cell: Vector2i, occupied: bool)

var _config: GridConfig
var _occupied: Dictionary[Vector2i, Node2D] = {}

func configure(config: GridConfig) -> void:
    _config = config
    _occupied.clear()

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
