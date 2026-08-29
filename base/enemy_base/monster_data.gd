class_name MonsterData
extends Resource
##名字
@export var monster_name: String = "Basic Monster"
##最大生命值
@export var max_health: int = 100
##移速
@export var move_speed: float = 80.0
##伤害
@export var damage: int = 10
##击杀得分
@export var score_value: int = 10
## 怪物类别
enum MonsterType {
	NORMAL,
	ELITE,
	BOSS,
}
##类别（普通/精英/Boss）
@export var monster_type: MonsterType = MonsterType.NORMAL

## 基础抗性：实际承伤 = 伤害 × (1 - armor)
@export var armor: float = 0.0
##负面效果抗性（减速/灼烧时长修正）
@export var negative_status_resistance: float = 0.0
