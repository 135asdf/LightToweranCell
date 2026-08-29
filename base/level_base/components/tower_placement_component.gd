class_name TowerPlacementComponent
extends Node

signal tower_placed(tower: TowerBase, cell: Vector2i)
signal placement_failed(reason: String)

var _catalog: TowerCatalog
var _allowed_ids: Array[StringName] = []
var _grid: BuildGridComponent
var _economy: EconomyComponent
var _towers_container: Node2D
var _selected_tower_id: StringName = &""

func configure(
    catalog: TowerCatalog,
    allowed_ids: Array[StringName],
    grid: BuildGridComponent,
    economy: EconomyComponent,
    towers_container: Node2D
) -> void:
    _catalog = catalog
    _allowed_ids = allowed_ids
    _grid = grid
    _economy = economy
    _towers_container = towers_container

func select_tower(tower_id: StringName) -> bool:
    if tower_id not in _allowed_ids or _catalog.find_by_id(tower_id) == null:
        placement_failed.emit("tower_not_allowed")
        return false
    _selected_tower_id = tower_id
    return true

func place_at_world(world_position: Vector2) -> TowerBase:
    var entry := _catalog.find_by_id(_selected_tower_id)
    if entry == null or entry.scene == null or entry.data == null:
        placement_failed.emit("invalid_tower_entry")
        return null
    var cell := _grid.world_to_cell(world_position)
    if not _grid.can_build(cell):
        placement_failed.emit("cell_unavailable")
        return null
    var tower := entry.scene.instantiate() as TowerBase
    if tower == null:
        placement_failed.emit("scene_root_not_tower_base")
        return null
    if not _economy.try_spend(entry.data.build_cost):
        tower.free()
        placement_failed.emit("insufficient_energy")
        return null
    tower.config = entry.data
    _towers_container.add_child(tower)
    tower.global_position = _grid.cell_to_world(cell)
    if not _grid.occupy(cell, tower):
        _economy.add_energy(entry.data.build_cost)
        tower.queue_free()
        placement_failed.emit("occupancy_race")
        return null
    tower_placed.emit(tower, cell)
    return tower
