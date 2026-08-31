class_name MonsterData
extends Resource

enum MonsterType { NORMAL, ELITE, BOSS }

@export_group("Identity")
@export var monster_id: StringName = &"basic_monster"
@export var display_name: String = "Basic Monster"
@export var monster_type: MonsterType = MonsterType.NORMAL

@export_group("Health")
@export_range(1, 100000, 1) var max_health: int = 100
@export_range(0.0, 0.95, 0.01) var armor: float = 0.0

@export_group("Movement")
@export_range(0.0, 2000.0, 1.0, "suffix:px/s") var move_speed: float = 80.0

@export_group("Contact")
@export_range(0, 100000, 1) var contact_damage: int = 10
@export_range(1.0, 256.0, 1.0, "suffix:px") var reach_distance: float = 20.0

@export_group("Tower Attack")
@export_range(0, 100000, 1) var tower_attack_damage: int = 5
@export_range(0.1, 10.0, 0.1, "suffix:s") var tower_attack_interval: float = 1.0
@export_range(1.0, 256.0, 1.0, "suffix:px") var tower_attack_range: float = 60.0

@export_group("Status")
@export_range(0.0, 1.0, 0.01) var negative_status_resistance: float = 0.0

@export_group("Reward")
@export_range(0, 100000, 1) var score_value: int = 10
@export_range(0, 100000, 1) var energy_reward: int = 0
