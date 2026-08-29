extends Area2D

@export var speed: float = 320.0
@export var damage: int = 20

var target: Node2D = null
var life: float = 3.0


# 初始化子弹：记录追踪目标、伤害与飞行速度。
func setup(t: Node2D, dmg: int, spd: float) -> void:
	target = t
	damage = dmg
	speed = spd


# 就绪时连接碰撞信号，用于命中检测。
func _ready() -> void:
	body_entered.connect(_on_body_entered)


# 每帧：倒计时寿命，超时或目标失效则销毁；否则朝目标方向飞行。
func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0 or target == null or not is_instance_valid(target):
		queue_free()
		return
	var dir := (target.global_position - global_position).normalized()
	global_position += dir * speed * delta


# 命中目标：若对方可受伤则造成伤害，随后销毁自身。
func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
