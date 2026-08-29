class_name MonsterBase
extends CharacterBody2D

@export var monster_data: MonsterData

var move_target: Node2D = null
var damage: int = 0   # 撞水晶伤害：1_level.gd 用 body.get("damage") 读，必须提供

var health_component: HealthComponent
var movement_component: MovementComponent

# 用 get_node_or_null：没有血条 UI 的怪物也不会崩
@onready var health_bar: ProgressBar = get_node_or_null("HealthBar") as ProgressBar
@onready var health_label: Label = get_node_or_null("HealthNumber") as Label


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("1_enemy")
	if monster_data == null:
		push_error("MonsterBase: 场景里没有配置 monster_data 资源")
		return
	damage = monster_data.damage
	health_component = HealthComponent.new()
	health_component.init(monster_data.max_health)
	health_component.health_changed.connect(_update_health_ui)
	health_component.died.connect(die)
	movement_component = MovementComponent.new()
	movement_component.init(monster_data.move_speed)
	_update_health_ui(health_component.get_health(), health_component.get_max_health())


func _physics_process(delta: float) -> void:
	if monster_data == null or move_target == null or not is_instance_valid(move_target):
		return
	if global_position.distance_to(move_target.global_position) < 20.0:
		return   # 到达水晶：停下，扣血和销毁交给关卡的水晶碰撞（1_level.gd）
	movement_component.move_toward(self, move_target.global_position, delta)


func setup_target(target: Node2D) -> void:
	move_target = target


func take_damage(amount: int) -> void:
	if health_component == null:
		return
	health_component.take_damage(amount)


func heal(amount: int) -> void:
	if health_component == null:
		return
	health_component.heal(amount)


func _update_health_ui(current_health: int, max_health: int) -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	if health_label:
		health_label.text = "%d/%d" % [current_health, max_health]


## 预留扩展点：击杀金币/特效以后在这里加
func die() -> void:
	queue_free()
