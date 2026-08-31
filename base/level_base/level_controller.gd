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
 
func _ready() -> void:
	if level_data == null or tower_catalog == null:
		push_error("LevelController requires LevelData and TowerCatalog")
		return
	build_grid.configure(level_data.grid_config)
	crystal.configure(level_data.crystal_max_health)
	economy.configure(level_data.starting_energy)
	placement.configure(tower_catalog, level_data.allowed_tower_ids, build_grid, economy, towers)
	spawner.configure(level_data.waves, enemies, crystal, _collect_spawn_points())
	goal.bind(spawner, crystal)
	hud.bind(self, crystal.health_component, economy, placement, goal)
	spawner.enemy_spawned.connect(_bind_enemy_reward)
	goal.level_won.connect(_finish_level.bind(true))
	goal.level_lost.connect(_finish_level.bind(false))
	result_panel.restart_requested.connect(_on_restart_requested)
	result_panel.level_select_requested.connect(_on_level_select_requested)
	result_panel.home_requested.connect(_on_home_requested)
	spawner.start()

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
	result_panel.show_result(won)
	get_tree().paused = true

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
