class_name TowerBase
extends Node2D

## ============================================================
##  塔基础类：所有塔的公共骨架
##  - 三模式（生产/攻击/充能），每个塔用 can_* 布尔声明支持哪些模式，
##    未启用的模式在切换时自动跳过
##  - 基础操作：点击切模式、右键供能方选中/链接、锁定、冷却、充能传导
##  - 具体效果由子类覆写：_on_mode_entered / _fire / _try_produce
##    / _link_gained / _on_linked / _do_overclock
##  - 数值全部来自 config（每塔一个 .tres，检查器里可调）
## ============================================================

enum Mode{
	PRODUCE,
	ATTACK,
	CONDUCTION
}

#循环
const MODE_ORDER: Array[int] = [Mode.PRODUCE, Mode.ATTACK, Mode.CONDUCTION]

@export var can_produce := false
@export var can_attack := false
@export var can_conduction := false

@export var config: TowerData

signal mode_changed(mode: int)
signal charging_changed(level: int)

## —— 状态 ——
var power_model : int = Mode.PRODUCE
var power_charging: int = 0
var is_locked := false##已建立供能链接，锁定不能切换模式
var is_cooling := false##超频后冷却，停止行动
var is_overclocked := false ##正在释放超频大招
var cooling_time_left := 0.0
var is_supplier := false
var light_energy := 0.0
var is_destroyed := false

## —— 供能链接（本塔作为供能方时）——
var outbound_link : Line2D = null
var outbound_arrow : Polygon2D = null
var outbound_target : TowerBase = null
var outbound_gained : int = 0

@onready var click_area: Area2D = $ClickArea
@onready var visual: TowerVisual = %Visual
@onready var attack_timer: Timer = $AttackTimer
@onready var production_timer: Timer = $ProductionTimer
@onready var health_component: HealthComponent = %HealthComponent
@onready var shield_component: ShieldComponent = %ShieldComponent
@onready var health_view_component: HealthViewComponent = get_node_or_null("HealthView") as HealthViewComponent
@onready var body_node: StaticBody2D = get_node_or_null("Body") as StaticBody2D

func _ready() -> void:
	add_to_group("tower")
	if config != null:
		attack_timer.wait_time = config.attack_interval
		production_timer.wait_time =  config.production_interval
		health_component.configure(config.max_health)
		shield_component.configure(config.max_shield, config.shield_regen_per_sec)
		if health_view_component != null:
			health_view_component.bind(health_component)
	attack_timer.timeout.connect(_try_attack)
	production_timer.timeout.connect(_try_produce)
	health_component.died.connect(_on_destroyed)
	_set_mode(Mode.PRODUCE)

func _process(delta: float) -> void:
	if is_cooling:
		cooling_time_left = maxf(0.0, cooling_time_left - delta)
		if visual:
			visual.show_cooling(cooling_time_left)
			

# ========== 模式切换 ==========
func cycle_mode() -> void:
	if is_cooling or is_overclocked or is_locked or is_destroyed:
		return
	var next := _next_avilable_mode(power_model)
	if next != power_model:
		_set_mode(next)
		mode_changed.emit(power_model)

func _next_avilable_mode(cur: int) -> int:
	var start := MODE_ORDER.find(cur)
	for i in range(1, MODE_ORDER.size() + 1):
		var m := MODE_ORDER[(start + i) % MODE_ORDER.size()]
		if _is_mode_available(m):
			return m
	return cur

func _is_mode_available(m: int) -> bool:
	match m:
		Mode.PRODUCE:
			return can_produce
		Mode.ATTACK:
			return can_attack
		Mode.CONDUCTION:
			return can_conduction
	return false

func _set_mode(m: int) -> void:
	if power_model != m:
		_on_mode_exited(power_model)
	power_model = m
	_apply_mode_timers(m)
	_on_mode_entered(m)
	if visual:
		visual.apply_visual(power_model, power_charging)

func _apply_mode_timers(m: int) -> void:
	attack_timer.stop()
	production_timer.stop()
	if is_cooling or is_overclocked:
		return
	match m:
		Mode.ATTACK:
			attack_timer.start()
		Mode.PRODUCE:
			production_timer.start()
		Mode.CONDUCTION:
			pass

## —— 子类覆写点（进入/离开模式时做自己的事，覆写时记得 super）——
func _on_mode_entered(m: int) -> void:
	pass

func _on_mode_exited(m: int) -> void:
	pass

# ========== 基础操作：点击交互 ==========
## 统一处理点击：点中塔→左键切模式/右键链接；点空地→取消选中
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var clicked := _tower_at(event.global_position)
		if clicked == null:
			_clear_supplier_selection() # 点空地：取消供能方选中
			return
		get_viewport().set_input_as_handled() # 阻止其它塔重复处理同一次点击
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if clicked.is_locked:
					return
				clicked.cycle_mode()
			MOUSE_BUTTON_RIGHT:
				clicked._on_right_click()

func _tower_at(pos:Vector2) -> TowerBase:
	var best: TowerBase = null
	var best_d := INF
	for node in get_tree().get_nodes_in_group("tower"):
		var t := node as TowerBase
		if t == null or t.click_area == null:
			continue
		var shape_node := t.click_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
		var rect := shape_node.shape as RectangleShape2D if shape_node != null else null
		if rect == null:
			continue
		var local := t.click_area.to_local(pos)
		if absf(local.x) <= rect.size.x * 0.5 and absf(local.y) <= rect.size.y * 0.5:
			var d := t.global_position.distance_squared_to(pos)
			if d < best_d:
				best_d = d
				best = t
	return best

# ========== 供能方选中 ==========
## 右键点击本塔：有选中供能方→本塔作为链接目标；否则自己是供能方→断开；否则选中/取消
func _on_right_click() -> void:
	if is_cooling or is_destroyed:
		return
	var supplier := _find_supplier()
	if supplier != null and supplier != self:
		_try_link(supplier,self)
		return
	if is_locked:
		_break_links()
		return
	if supplier == self:
		_clear_supplier_selection()
	elif can_conduction:
		_set_supplier_selection(self)

## 在 tower 组里找当前选中的供能方
func _find_supplier() -> TowerBase:
	for node in get_tree().get_nodes_in_group("tower"):
		var t := node as TowerBase
		if t != null and t.is_supplier:
			return t
	return null

## 把 t 设为唯一供能方（先清掉旧的），并自动切换到充能模式
func _set_supplier_selection(t: TowerBase) -> void:
	_clear_supplier_selection()
	t.is_supplier = true
	t._set_mode(Mode.CONDUCTION)   # 选中为供能方 → 自动切充能模式（停普攻/生产）
	t.queue_redraw()  

## 清除所有供能方选中
func _clear_supplier_selection() -> void:
	for node in get_tree().get_nodes_in_group("tower"):
		var t := node as TowerBase
		if t != null and t.is_supplier:
			t.is_supplier = false
			t.queue_redraw()

## 选中供能方时绘制传导范围圈
func _draw() -> void:
	if is_supplier and config != null:
		draw_arc(Vector2.ZERO, config.charge_range, 0.0, TAU, 64, Color(0.3, 0.6, 1.0, 0.7), 2.0)
		draw_circle(Vector2.ZERO, config.charge_range, Color(0.3, 0.6, 1.0, 0.05))

# ========== 充能链接 ==========

## 尝试建立 supplier → target 链接（通用规则；供给量/超频由子类覆写决定）
func _try_link(supplier: TowerBase, target: TowerBase) -> void:
	if supplier == target or supplier.is_destroyed or target.is_destroyed:
		return
	if supplier.is_cooling or target.is_cooling:
		return
	if supplier.config == null or supplier.global_position.distance_to(target.global_position) > supplier.config.charge_range:
		return   # 超出传导范围
	if target.outbound_target == supplier:
		return   # 禁止互充：目标塔已在给供能方充能
	# 禁止多塔循环：沿 target 的出链追溯，若某塔指向 supplier → 会形成闭环
	var node: TowerBase = target
	var hops := 0
	while node != null and hops <= 10:
		if node.outbound_target == supplier:
			return
		node = node.outbound_target
		hops += 1
	if supplier.outbound_target == target:
		return   # 禁止重复链接同一目标
	# 供给量：由子类 _link_gained 决定（光能塔按层数给 1/2/3/3 层）
	var gained := mini(supplier._link_gained(supplier.power_charging), 3 - target.power_charging)
	if gained <= 0:
		return   # 目标已达三层充能上限
	# 供能方锁定：进入充能模式，不能生产/攻击/切模式
	supplier.is_supplier = false
	supplier.queue_redraw()
	supplier.is_locked = true
	supplier._set_mode(Mode.CONDUCTION)
	# 目标塔获得充能（链式传导）
	target.set_charging(target.power_charging + gained)
	# 画带箭头的链接线并记录本次供给量（断开时用于降级）
	supplier._create_link_line(target, gained)
	# 链接完成钩子：子类在这里判断是否触发超频等特殊效果
	supplier._on_linked(target, gained)

## 供能方当前层数 → 能供给目标的层数（子类覆写；默认固定 1 层）
func _link_gained(level: int) -> int:
	return 1

## 链接建立完成后的钩子（子类覆写：如光能塔 3 层供能方 + 攻击塔 → 触发超频）
func _on_linked(target: TowerBase, gained: int) -> void:
	pass

## 供能方画一条带箭头的链接线指向目标塔，并记录目标与供给层数
func _create_link_line(target: TowerBase, gained: int) -> void:
	var dir: Vector2 = target.global_position - global_position
	outbound_link = Line2D.new()
	outbound_link.points = PackedVector2Array([Vector2.ZERO, dir])
	outbound_link.width = 2.0
	outbound_link.default_color = Color(0.3, 0.8, 1.0, 0.8)
	add_child(outbound_link)
	outbound_arrow = Polygon2D.new()
	outbound_arrow.polygon = PackedVector2Array([Vector2(0, -5), Vector2(14, 0), Vector2(0, 5)])
	outbound_arrow.position = dir * 0.5
	outbound_arrow.rotation = dir.angle()
	outbound_arrow.color = Color(0.3, 0.8, 1.0, 0.9)
	add_child(outbound_arrow)
	outbound_target = target
	outbound_gained = gained

## 解除本塔作为供能方的链接：移除线/箭头，目标塔按本次供给量降级
func _break_links() -> void:
	if outbound_link != null:
		outbound_link.queue_free()
		outbound_link = null
	if outbound_arrow != null:
		outbound_arrow.queue_free()
		outbound_arrow = null
	if outbound_target != null:
		outbound_target.set_charging(outbound_target.power_charging - outbound_gained)
		outbound_target = null
	outbound_gained = 0
	is_locked = false
	is_supplier = false
	queue_redraw()
	_set_mode(Mode.PRODUCE)   # 断开后回到生产模式（停普攻；无生产模式的塔可覆写为其它模式）


# ========== 充能层数（链式传导） ==========

## 设置充能层数（0~3）并刷新外观。本塔是供能方时，层数变化会按新预算
## 重算下游已链接塔的供给量（升级补层/降级扣层），_visited 防 A→B→A 循环
func set_charging(level: int, _visited: Array = []) -> void:
	power_charging = clampi(level, 0, 3)
	if outbound_target != null:
		var new_gained: int = _link_gained(power_charging)
		var diff := new_gained - outbound_gained
		if diff != 0 and not (outbound_target in _visited):
			_visited.append(self)
			outbound_target.set_charging(outbound_target.power_charging + diff, _visited)
			outbound_gained = new_gained
	if visual:
		visual.apply_visual(power_model, power_charging)
	charging_changed.emit(power_charging)


# ========== 攻击（节奏在基类，发射效果子类覆写） ==========

## 攻击定时器触发：按充能层数增幅同时攻击多个敌人
func _try_attack() -> void:
	if is_cooling or is_overclocked or is_destroyed:
		return
	var mult := _damage_mult()
	for target in _acquire_targets(_laser_count()):
		_fire(target, mult)

## 同时攻击的敌人数量（默认按层数从 config 读，子类可覆写）
func _laser_count() -> int:
	return config.laser_count[clampi(power_charging, 0, 3)]

## 伤害倍率（默认按层数从 config 读；子类可覆写，如炽光塔额外叠加火元素增伤）
func _damage_mult() -> float:
	return config.damage_mult[clampi(power_charging, 0, 3)]

## 索敌：范围内按"最前列"（path_follow.progress 最大）排序，取前 n 个。
## 没有 path_follow 的敌人（直冲水晶型）回退为 0，排序不会报错
func _acquire_targets(n: int) -> Array:
	var in_range: Array = []
	for node in get_tree().get_nodes_in_group("enemy"):
		var e := node as Node2D
		if e == null or not is_instance_valid(e):
			continue
		if global_position.distance_to(e.global_position) > _attack_range():
			continue
		in_range.append(e)
	in_range.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return _enemy_progress(a) > _enemy_progress(b))
	return in_range.slice(0, n)

func _attack_range() -> float:
	return config.attack_range if config != null else 300.0

## 敌人在移动路径上的进度（用 get 兜底，敌人没有该属性时返回 0）
func _enemy_progress(e: Node2D) -> float:
	var pf: Variant = e.get("path_follow")
	if pf != null and pf is Node:
		var progress: Variant = (pf as Node).get("progress")
		if progress != null:
			return progress
	return 0.0

## 开火：子类必须覆写（光能塔画激光、炽光塔发火球…），mult 是当前伤害倍率
func _fire(target: Node2D, mult: float) -> void:
	push_error("_fire 未实现：子类需覆写")

# ========== 耐久（生命/护盾） ==========
## 敌人攻击塔的入口：先扣护盾，护盾吸收不了的部分扣血
func take_damage(amount: int) -> void:
	if is_destroyed:
		return
	var overflow := shield_component.take_damage(amount)
	if overflow > 0:
		health_component.take_damage(overflow)

## 生命归零：进入损坏状态，停止一切工作
func _on_destroyed() -> void:
	is_destroyed = true
	attack_timer.stop()
	production_timer.stop()
	if body_node != null:
		body_node.set_deferred("collision_layer", 0)   # 移除阻挡，敌人可继续前进
	if visual:
		visual.set_destroyed()   # 损坏外观（变灰）

# ========== 生产（先只做数值，不接 UI） ==========
## 生产定时器触发：产出光能（数值存 light_energy）
func _try_produce() -> void:
	if is_cooling or is_overclocked or is_destroyed:
		return
	light_energy += _production_amount()

## 单次产量（默认按层数从 config 读：5/12/20/30，子类可覆写）
func _production_amount() -> float:
	return config.production_by_charge[clampi(power_charging, 0, 3)]


# ========== 超频（基类只提供冷却机制，效果子类覆写） ==========

## 触发超频：停止行动 → 子类释放大招 → 本塔与最强供能塔一起进入冷却
func _trigger_overclock() -> void:
	is_overclocked = true
	attack_timer.stop()
	production_timer.stop()
	_do_overclock()              # 子类覆写：贯穿激光 / 一次性 60 光能 / 无效果
	_start_overclock_cooldown()

func _do_overclock() -> void:
	push_error("_do_overclock 未实现：子类需覆写")

func _start_overclock_cooldown() -> void:
	is_overclocked = false
	_begin_cooling()
	var feeder := _find_strongest_feeder()
	if feeder != null:
		feeder._begin_cooling()   # 供能方一起冷却（扩展设计，已确认保留）

## 找到给本塔充能层数最多的供能塔（入链中 outbound_gained 最大）
func _find_strongest_feeder() -> TowerBase:
	var best: TowerBase = null
	var best_gained := 0
	for node in get_tree().get_nodes_in_group("tower"):
		var t := node as TowerBase
		if t != null and t.outbound_target == self:
			if t.outbound_gained > best_gained:
				best_gained = t.outbound_gained
				best = t
	return best

## 开始冷却：停止行动（不能生产/攻击/切模式/链接），冷却结束按当前模式恢复
func _begin_cooling() -> void:
	is_cooling = true
	cooling_time_left = config.overclock_cooldown
	attack_timer.stop()
	production_timer.stop()
	var tw := get_tree().create_timer(config.overclock_cooldown)
	tw.timeout.connect(_end_cooling)

func _end_cooling() -> void:
	is_cooling = false
	cooling_time_left = 0.0
	if visual:
		visual.apply_visual(power_model, power_charging)
	match power_model:
		Mode.ATTACK:
			attack_timer.start()
		Mode.PRODUCE:
			production_timer.start()
		Mode.CONDUCTION:
			pass
