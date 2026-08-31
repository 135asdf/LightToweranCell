class_name MonsterBase
extends CharacterBody2D

signal died(enemy: MonsterBase)
signal reached_target(enemy: MonsterBase)
signal reward_requested(score: int, energy: int)

@export var monster_data: MonsterData
@onready var health_component: HealthComponent = %HealthComponent
@onready var target_component: TargetComponent = %TargetComponent
@onready var movement_component: MovementComponent = %MovementComponent
@onready var contact_damage_component: ContactDamageComponent = %ContactDamageComponent
@onready var status_effect_component: StatusEffectComponent = %StatusEffectComponent
@onready var reward_component: RewardComponent = %RewardComponent
@onready var health_view_component: HealthViewComponent = %HealthViewComponent
@onready var attack_component: EnemyAttackComponent = %EnemyAttackComponent

var _finished := false

## 兼容属性：旧水晶逻辑读 body.get("damage")；迁移完成后删除
var damage: int:
	get: return monster_data.contact_damage if monster_data != null else 0

func _ready() -> void:
	add_to_group("enemy")
	if monster_data == null:
		push_error("MonsterBase requires MonsterData")
		set_physics_process(false)
		return
	health_component.configure(monster_data.max_health, monster_data.armor)
	movement_component.configure(self, target_component, monster_data.move_speed, monster_data.reach_distance)
	contact_damage_component.configure(target_component, monster_data.contact_damage)
	status_effect_component.configure(monster_data.negative_status_resistance)
	reward_component.configure(monster_data.score_value, monster_data.energy_reward)
	attack_component.configure(self, target_component, movement_component, monster_data)
	health_view_component.bind(health_component)
	health_component.died.connect(_on_died)
	movement_component.destination_reached.connect(_on_destination_reached)
	status_effect_component.speed_multiplier_changed.connect(movement_component.set_speed_multiplier)
	reward_component.reward_requested.connect(reward_requested.emit)


func setup_target(target: Node2D) -> void:
	target_component.set_target(target)
	movement_component.start()

func take_damage(amount: int) -> void:
	health_component.take_damage(amount)

func heal(amount: int) -> void:
	health_component.heal(amount)

func _on_died() -> void:
	if _finished:
		return
	_finished = true
	movement_component.stop()
	attack_component.stop()
	reward_component.request_once()
	died.emit(self)
	queue_free()

func _on_destination_reached() -> void:
	if _finished or not contact_damage_component.apply_once():
		return
	_finished = true
	reached_target.emit(self)
	queue_free()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if monster_data == null:
		warnings.append("MonsterData is required")
	var required := ["HealthComponent", "TargetComponent", "MovementComponent", "ContactDamageComponent", "StatusEffectComponent", "RewardComponent", "HealthViewComponent"]
	for name in required:
		if get_node_or_null(name) == null:
			warnings.append("Missing required component: %s" % name)
	return warnings
