extends Node2D

@export var spawn_interval_start: float = 2.5
@export var spawn_interval_min: float = 0.5
@export var ramp_duration: float = 60.0
@export var margin: float = 40.0

@onready var enemies_node: Node2D = $"../Enemies"
@onready var crystal: Node2D = $"../Background/Grid/Crystal"

var elapsed: float = 0.0
var timer: float = 0.0


# 就绪时把首次刷怪计时设为初始间隔。
func _ready() -> void:
	timer = spawn_interval_start


# 每帧：累计游戏时长并倒计时，计时归零则刷一只怪并按当前难度重置计时。
func _process(delta: float) -> void:
	elapsed += delta
	timer -= delta
	if timer <= 0.0:
		_spawn_enemy()
		timer = _current_interval()


# 根据已进行时长在初始与最短刷怪间隔之间线性插值，实现难度递增。
func _current_interval() -> float:
	var t := clampf(elapsed / ramp_duration, 0.0, 1.0)
	return lerpf(spawn_interval_start, spawn_interval_min, t)


# 随机从本关怪物类型中挑一种，实例化到敌人节点下并设置目标与出生位置。
func _spawn_enemy() -> void:
	var level: Variant = get_parent()
	var types: Array = level.ENEMY_TYPES
	if types.is_empty():
		return
	var scene: PackedScene = types.pick_random()
	var enemy := scene.instantiate() as MonsterBase
	if enemy == null:
		push_error("生成的场景不是 MonsterBase")
		return
	enemies_node.add_child(enemy)
	enemy.global_position = _random_edge_position()
	enemy.setup_target(crystal)


# 返回屏幕四条边外侧的一个随机出生点。
func _random_edge_position() -> Vector2:
	var size := Vector2(1280, 720)
	match randi_range(0, 3):
		0:
			return Vector2(randf_range(0.0, size.x), -margin)
		1:
			return Vector2(randf_range(0.0, size.x), size.y + margin)
		2:
			return Vector2(-margin, randf_range(0.0, size.y))
		_:
			return Vector2(size.x + margin, randf_range(0.0, size.y))
