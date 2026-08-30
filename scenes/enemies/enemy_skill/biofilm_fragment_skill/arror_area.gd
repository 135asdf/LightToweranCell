extends Area2D

@export var armor_multiplier: float = 1.2

var _boosted: Dictionary = {}

func _ready() -> void:
	# 监听进出光环
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

#进入时提高抗性
func _on_body_entered(body: Node) -> void:
	# 只处理敌人
	if not body.is_in_group("enemy"):
		return

	var health := body.get_node_or_null("%HealthComponent") as HealthComponent
	
	if health == null:
		return
	var id := body.get_instance_id()
	# 已在光环内则跳过，避免重复
	if _boosted.has(id):
		return
	
	var base := health.get_armor()
	_boosted[id] = base
	# 抗性 ×1.2
	health.set_armor(base * armor_multiplier)

#离开时恢复抗性
func _on_body_exited(body: Node) -> void:
	var id := body.get_instance_id()
	if not _boosted.has(id):
		return
	var health := body.get_node_or_null("%HealthComponent") as HealthComponent
	# 离开：改回进入前的抗性
	if health != null and is_instance_valid(health):
		health.set_armor(_boosted[id])
	_boosted.erase(id)

# 碎块销毁时，把还在范围内的怪全部还原
func _exit_tree() -> void:
	for id in _boosted.keys():
		var body := instance_from_id(id) as Node
		if body == null:
			continue
		var health := body.get_node_or_null("%HealthComponent") as HealthComponent
		if health != null and is_instance_valid(health):
			health.set_armor(_boosted[id])
	_boosted.clear()
