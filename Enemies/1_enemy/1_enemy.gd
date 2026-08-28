extends CharacterBody2D

@export var max_health: int = 100
@export var move_speed: float = 80.0
@export var damage: int = 10

var health: int
var move_target: Node2D = null

@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthNumber


# 节点就绪时初始化：加入 enemy 与 1_enemy 分组，把血量设为满血并刷新血条 UI。
func _ready() -> void:
	add_to_group("enemy")
	add_to_group("1_enemy")
	health = max_health
	_update_health_ui()


# 每物理帧：朝目标移动，靠近到一定距离后销毁自身（视为到达水晶）。
func _physics_process(delta: float) -> void:
	if move_target == null or not is_instance_valid(move_target):
		return
	var dir := (move_target.global_position - global_position).normalized()
	global_position += dir * move_speed * delta
	if global_position.distance_to(move_target.global_position) < 20.0:
		queue_free()


# 设置移动目标（通常由刷怪器传入水晶节点）。
func setup_target(target: Node2D) -> void:
	move_target = target


# 受到伤害：扣血并刷新 UI，血量归零则死亡。
func take_damage(amount: int) -> void:
	health = clampi(health - amount, 0, max_health)
	_update_health_ui()
	if health <= 0:
		die()


# 治疗：回血并刷新 UI，不超过血量上限。
func heal(amount: int) -> void:
	health = clampi(health + amount, 0, max_health)
	_update_health_ui()


# 刷新血条数值与血量文本显示。
func _update_health_ui() -> void:
	health_bar.max_value = max_health
	health_bar.value = health
	health_label.text = "%d/%d" % [health, max_health]


# 死亡：销毁自身节点。
func die() -> void:
	queue_free()
