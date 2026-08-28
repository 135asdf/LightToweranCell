class_name TowerData
extends Resource

## ========== 塔的数值资源 ==========
## 用 .tres 文件实例化（见 res://data/tower_data.tres），数值可在检查器里直接改
## 代码引用方式：
##   const TowerData := preload("res://data/tower_data.tres")
##   然后 TowerData.attack_range / TowerData.charge_range ...

@export var attack_range := 300.0          # 攻击半径（设计文档：半径 300）
@export var attack_interval := 0.2         # 攻击间隔（秒）
@export var base_damage := 10.0            # 单发基础伤害（待定）
@export var charge_range := 400.0          # 传导范围（设计文档：半径 400）

## 方案 a：供能方层数 → 可提供的充能层数预算（0/1/2/3 层 → 1/2/3/4 层）
@export var supply_budget := [1, 2, 3, 4]

## 攻击模式充能增幅：0/1/2/3 层充能 → 同时攻击的敌人数量（激光数）
@export var laser_count := [1, 2, 3, 4]

## 攻击模式充能增幅：0/1/2/3 层充能 → 伤害倍率（设计文档：1.2 / 1.33 / 1.5）
@export var damage_mult := [1.0, 1.2, 1.33, 1.5]

## 攻击超频：攻击模式塔充能满 3 层时触发（数值可调）
@export var overclock_damage := 50.0       # 超频贯穿激光对每个命中敌人的伤害
@export var overclock_range := 600.0       # 超频大招最大扫射距离（沿野怪路线）
@export var overclock_cooldown := 30.0     # 超频后本塔与最强供能塔停止行动的时间（秒）
