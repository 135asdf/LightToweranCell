extends Area2D

@export var heal_amount: int = 100
@onready var heal_timer: Timer = $HealTimer

# 范围内敌人 id -> 节点
var _in_range: Dictionary = {}

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	heal_timer.timeout.connect(_on_heal_tick)

#进入圈内加入治疗名单
func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("enemy"):
		return

	_in_range[body.get_instance_id()] = body

#退出圈内退出治疗名单
func _on_body_exited(body: Node) -> void:
	_in_range.erase(body.get_instance_id())


func _on_heal_tick() -> void:
	var lowest: Node = null
	var lowest_hp := 2147483647
	# 组装候选：圈内敌人（可选 + 自己）
	var candidates: Array = _in_range.values()
	
	for body in candidates:
		if body == null or not is_instance_valid(body):
			continue
		var health := body.get_node_or_null("%HealthComponent") as HealthComponent
		if health == null or health.is_dead():
			continue
		# 已满血可跳过，避免无效治疗
		if health.get_health() >= health.get_max_health():
			continue
		var hp := health.get_health()
		if hp < lowest_hp:
			lowest_hp = hp
			lowest = body
	
	if lowest == null:
		return
	
	var target_health := lowest.get_node_or_null("%HealthComponent") as HealthComponent
	
	if target_health:
		target_health.heal(heal_amount)
