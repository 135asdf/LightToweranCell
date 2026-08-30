extends Area2D

@export var speed_boost: float = 1.5   # 1.5 = 加速 50%
@export var lifetime: float = 5.0

var _boosted: Dictionary = {}  # instance_id -> MovementComponent


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

#过滤加速对象，实现加速，获取加速对象并记录方便恢复速度
func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("enemy"):
		return
	var move := body.get_node_or_null("%MovementComponent") as MovementComponent
	if move == null:
		return
	_boosted[body.get_instance_id()] = move
	move.set_speed_multiplier(speed_boost)


func _on_body_exited(body: Node) -> void:
	var id := body.get_instance_id()
	if not _boosted.has(id):
		return
	var move: MovementComponent = _boosted[id]
	if is_instance_valid(move):
		move.set_speed_multiplier(1.0)
	_boosted.erase(id)


func _exit_tree() -> void:
	for move in _boosted.values():
		if is_instance_valid(move):
			move.set_speed_multiplier(1.0)
	_boosted.clear()
