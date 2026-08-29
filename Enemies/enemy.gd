extends CharacterBody2D
class_name Enemy

@export var stats: EnemyStats
var max_health: int
var move_speed: int
var damage: int

var current_health: int
var move_target: Node2D = null

@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthNumber


# 节点就绪时初始化：加入 enemy 与 1_enemy 分组，把血量设为满血并刷新血条 UI。
func _ready() -> void:
	add_to_group("enemy")
	add_to_group("1_enemy")
	max_health = stats.health
	move_speed = float(stats.speed)
	damage = stats.damage
	current_health = max_health
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
	current_health = clampi(current_health - amount, 0, max_health)
	_update_health_ui()
#死亡清理自身
	if current_health <= 0:
		queue_free()


# 治疗：回血并刷新 UI，不超过血量上限。
func heal(amount: int) -> void:
	current_health = clampi(current_health + amount, 0, max_health)
	_update_health_ui()


# 刷新血条数值与血量文本显示。
func _update_health_ui() -> void:
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_label.text = "%d" % [current_health]
