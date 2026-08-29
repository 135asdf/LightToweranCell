extends Node2D

@export var fire_rate: float = 1.0
@export var bullet_speed: float = 320.0
@export var damage: int = 20

const BULLET_SCENE := preload("res://scenes/towers/tower_plasma_cell_bullet.tscn")

@onready var attack_range: Area2D = $AttackRange

var enemies_in_range: Array = []
var cooldown: float = 0.0


# 就绪时连接攻击范围的进入/离开信号，用于维护范围内敌人列表。
func _ready() -> void:
	attack_range.body_entered.connect(_on_body_entered)
	attack_range.body_exited.connect(_on_body_exited)


# 每帧：扣冷却、清理已失效的敌人，冷却结束后向最近敌人开火并重置冷却。
func _process(delta: float) -> void:
	cooldown -= delta
	enemies_in_range = enemies_in_range.filter(func(e): return is_instance_valid(e))
	if enemies_in_range.is_empty() or cooldown > 0.0:
		return
	var target := _nearest_target()
	if target != null:
		_shoot(target)
		cooldown = 1.0 / fire_rate


# 敌人进入攻击范围时：若属于 enemy 分组且尚未记录，则加入目标列表。
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy") and not enemies_in_range.has(body):
		enemies_in_range.append(body)


# 敌人离开攻击范围时：从目标列表中移除。
func _on_body_exited(body: Node) -> void:
	enemies_in_range.erase(body)


# 返回范围内距离最近的有效敌人，作为开火目标。
func _nearest_target() -> Node2D:
	var nearest: Node2D = null
	var best := INF
	for e in enemies_in_range:
		if not is_instance_valid(e):
			continue
		var d := global_position.distance_squared_to(e.global_position)
		if d < best:
			best = d
			nearest = e
	return nearest


# 向目标发射一枚子弹：实例化子弹场景并传入目标、伤害与速度。
func _shoot(target: Node2D) -> void:
	var bullet := BULLET_SCENE.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = global_position
	bullet.setup(target, damage, bullet_speed)
