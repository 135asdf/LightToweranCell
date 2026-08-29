class_name TowerData
extends Resource

## ========== 塔的数值资源 ==========
## 每座塔一个 .tres 实例（如 res://data/towers/light_tower_stats.tres），
## 数值在检查器里直接改；塔脚本通过 @export var config: TowerData 引用
## 不同塔共用同一份类，各自填各自的数值；塔有专属字段时再建子类资源
##（如 BlazingTowerData extends TowerData 加火元素增伤字段）

## —— 基础属性 ——
@export var attack_range := 300.0          # 攻击半径（策划：半径 300）
@export var attack_interval := 0.2         # 攻击间隔（秒）
@export var base_damage := 10.0            # 单发基础伤害（待定）
@export var charge_range := 400.0          # 传导范围（策划：半径 400）

## —— 生产模式 ——
@export var production_interval := 10.0    # 生产间隔（秒）（策划：每10秒）
@export var production_by_charge := [5.0, 12.0, 20.0, 30.0]
## 单次产量按充能层数取：0/1/2/3 层 → 5/12/20/30 光能（策划）

## —— 充能模式 ——
@export var supply_budget := [1, 2, 3, 3]
## 供能方充能层数 → 可供给目标的层数（策划：0/1/2/3 层 → 1/2/3/3 层）
## 3 层时给目标补满 3 层，并进入超频（超频触发条件在塔逻辑里判定）

## —— 攻击模式充能增幅 ——
@export var laser_count := [1, 2, 3, 4]
## 0/1/2/3 层充能 → 同时攻击的敌人数量（策划：1/2/3/4 道激光）
@export var damage_mult := [1.0, 1.2, 1.33, 1.5]
## 0/1/2/3 层充能 → 伤害倍率（策划：基础 / 1.2 / 1.33 / 1.5 倍）

## —— 攻击超频（攻击塔充能满 3 层时触发，数值可调） ——
@export var overclock_damage := 50.0       # 超频贯穿激光对每个命中敌人的伤害
@export var overclock_range := 600.0       # 超频大招最大扫射距离（沿野怪路线）
@export var overclock_cooldown := 30.0     # 超频后本塔与最强供能塔停止行动的时间（秒）

## —— 生产超频（生产塔充能满 3 层时触发） ——
@export var overclock_production := 60.0   # 生产塔超频一次性制造的光能（模拟文档：60）
