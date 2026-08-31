class_name LevelController
extends Node2D

@export var level_data: LevelData
@export var tower_catalog: TowerCatalog

@onready var build_grid: BuildGridComponent = %BuildGrid
@onready var crystal: CrystalController = %Crystal
@onready var economy: EconomyComponent = %Economy
@onready var spawner: WaveSpawnerComponent = %WaveSpawner
@onready var placement: TowerPlacementComponent = %TowerPlacement
@onready var goal: LevelGoalComponent = %LevelGoal
@onready var hud: LevelHUD = %HUD
@onready var result_panel: ResultPanel = %ResultPanel
@onready var enemies: Node2D = %Enemies
@onready var towers: Node2D = %Towers

## 本局塔背包：关卡结束时场上塔回收进这里（第五阶段接全局背包/UI）
## 本局塔背包：指向全局 GameState.inventory（跨关卡持久；第五阶段背包系统）
var inventory: Inventory = GameState.inventory
 
func _ready() -> void:
	if level_data == null or tower_catalog == null:
		push_error("LevelController requires LevelData and TowerCatalog")
		return
	GameState.ensure_starting_inventory(tower_catalog)
	build_grid.configure(level_data.grid_config)
	crystal.configure(level_data.crystal_max_health)
	var crystal_cell: Vector2i = level_data.grid_config.blocked_cells[0]
	crystal.global_position = build_grid.cell_to_world(crystal_cell)
	economy.configure(level_data.starting_energy)
	placement.configure(tower_catalog, level_data.allowed_tower_ids, build_grid, economy, towers, GameState.inventory)
	spawner.configure(level_data.waves, enemies, crystal, _collect_spawn_points())
	goal.bind(spawner, crystal)
	hud.bind(self, economy, placement, goal, GameState.inventory, tower_catalog)
	spawner.enemy_spawned.connect(_bind_enemy_reward)
	placement.tower_placed.connect(_on_tower_placed)
	goal.level_won.connect(_finish_level.bind(true))
	goal.level_lost.connect(_finish_level.bind(false))
	result_panel.restart_requested.connect(_on_restart_requested)
	result_panel.level_select_requested.connect(_on_level_select_requested)
	result_panel.home_requested.connect(_on_home_requested)
	spawner.start()


## 放置成功后刷新背包栏（数量变化）
func _on_tower_placed(_tower: TowerBase, _cell: Vector2i) -> void:
	hud.refresh_inventory()

## SceneManager 是 autoload；headless 测试模式不加载 autoload，故用节点查找代替标识符
func _scene_manager() -> Node:
	return get_node_or_null("/root/SceneManager")

func _on_restart_requested() -> void:
	var sm := _scene_manager()
	if sm != null and sm.has_method("reload"):
		sm.reload()

func _on_level_select_requested() -> void:
	var sm := _scene_manager()
	if sm != null and sm.has_method("goto"):
		sm.goto("level_selection")

func _on_home_requested() -> void:
	var sm := _scene_manager()
	if sm != null and sm.has_method("goto"):
		sm.goto("main")

func _bind_enemy_reward(enemy: MonsterBase) -> void:
	enemy.reward_requested.connect(func(_score: int, energy: int): economy.add_energy(energy))

func _finish_level(won: bool) -> void:
	spawner.stop()
	_recover_towers()
	result_panel.show_result(won)
	get_tree().paused = true


## 关卡结束：场上所有塔回背包（含损坏塔，下关可重新放置）。
## 每关重新布防，所以未损坏的塔也一并回收。
func _recover_towers() -> void:
	for child in towers.get_children():
		var t := child as TowerBase
		if t != null and t.config != null:
			inventory.add(t.config.tower_id)

func _collect_spawn_points() -> Dictionary[StringName, Marker2D]:
	var result: Dictionary[StringName, Marker2D] = {}
	for child in %SpawnPoints.get_children():
		var marker := child as Marker2D
		if marker != null:
			result[StringName(marker.name.to_snake_case())] = marker
	return result

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if level_data == null:
		warnings.append("LevelData is required")
	if tower_catalog == null:
		warnings.append("TowerCatalog is required")
	return warnings
