extends Node2D
class_name LightPower

## 充能层数（0~3）
enum {
	ZERO_CHARGING,
	ONE_CHARGING,
	TWO_CHARGING,
	THREE_CHARGING,
}

## 三种模式（枚举顺序保持原样，用 NEXT_MODE 表控制循环顺序）
enum {
	CREATE_LIGHT_MODEL,   # 生产
	ATTACK_MODEL,         # 攻击
	CONDUCTION_MODEL,     # 充能
}

## 模式循环顺序：生产 → 攻击 → 充能 → 生产
const NEXT_MODE := {
	CREATE_LIGHT_MODEL: ATTACK_MODEL,
	ATTACK_MODEL: CONDUCTION_MODEL,
	CONDUCTION_MODEL: CREATE_LIGHT_MODEL,
}

signal mode_changed(mode: int)
signal charging_changed(level: int)

## 塔数值资源（tower_data.tres，检查器里可改）
const TowerConfig := preload("res://data/tower_data.tres")

var power_charging: int = ZERO_CHARGING
var is_attack = false
var power_model: int = CREATE_LIGHT_MODEL

var is_supplier := false      # 被右键选中为候选供能方
var is_locked := false        # 已建立供能链接，锁定不能切模式
var is_overclocked := false   # 正在释放超频大招
var is_cooling := false       # 超频后冷却中（停止行动）
var cooling_time_left := 0.0  # 冷却剩余秒数（用于 Label 显示）
var outbound_link: Line2D = null          # A→B 链接线（本塔作为供能方时）
var outbound_arrow: Polygon2D = null      # A→B 链接箭头（指向目标）
var outbound_target: LightPower = null    # 供能目标塔（断开时用来降级）
var outbound_gained: int = 0              # 本次链接给目标增加的层数

@onready var click_area: Area2D = $ClickArea
@onready var attack_timer: Timer = $AttackTimer
@onready var visual: TowerVisual = $Visual   # 外观/动画都交给 Visual 节点处理

func _ready() -> void:
	add_to_group("tower")
	attack_timer.wait_time = TowerConfig.attack_interval
	attack_timer.timeout.connect(_try_attack)
	visual.apply_visual(power_model, power_charging)   # 启动时刷新外观

func _process(delta: float) -> void:
	if is_cooling:
		cooling_time_left = maxf(0.0, cooling_time_left - delta)
		visual.show_cooling(cooling_time_left)   # 每帧刷新冷却倒计时

## 选中为供能方时绘制 400 传导范围圈
func _draw() -> void:
	if is_supplier:
		draw_arc(Vector2.ZERO, TowerConfig.charge_range, 0.0, TAU, 64, Color(0.3, 0.6, 1.0, 0.7), 2.0)
		draw_circle(Vector2.ZERO, TowerConfig.charge_range, Color(0.3, 0.6, 1.0, 0.05))

# ========== 模式切换 ==========

## 点击一次切换一次模式：生产 → 攻击 → 充能 → 生产
func cycle_mode() -> void:
	if is_cooling or is_overclocked:
		return   # 冷却/超频中不能切换模式
	_set_mode(NEXT_MODE[power_model])
	mode_changed.emit(power_model)

## 统一切换模式：更新 is_attack、启停攻击定时器、刷新外观（所有切模式的地方都用它）
func _set_mode(m: int) -> void:
	power_model = m
	is_attack = m == ATTACK_MODEL
	if is_attack:
		attack_timer.start()      # 进入攻击模式：开始每 0.2s 索敌开火
	else:
		attack_timer.stop()       # 离开攻击模式：停止开火
	visual.apply_visual(power_model, power_charging)

## 统一处理点击：点中塔→左键切模式/右键链接；点空地→取消选中
## 用命中测试代替 Area2D 拾取，避免 Label 遮挡 / 事件传播歧义
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var clicked := _tower_at(event.global_position)
		if clicked == null:
			_clear_supplier_selection()   # 点空地：取消供能方选中
			return
		get_viewport().set_input_as_handled()   # 关键：阻止其他塔的 _unhandled_input 重复处理同一次点击
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if clicked.is_locked:
					return   # 供能方被锁定，不能切模式
				clicked.cycle_mode()
			MOUSE_BUTTON_RIGHT:
				clicked._on_right_click()

## 命中测试：点击位置落在哪座塔的 ClickArea 碰撞形状内（返回最近的那座，没命中返回 null）
func _tower_at(pos: Vector2) -> LightPower:
	var best: LightPower = null
	var best_d := INF
	for node in get_tree().get_nodes_in_group("tower"):
		var t := node as LightPower
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

# ========== 充能链接 ==========

## 右键点击本塔：有选中供能方→本塔作为链接目标；否则自己是供能方→断开；否则选中/取消
func _on_right_click() -> void:
	if is_cooling:
		return   # 冷却中停止行动，不能链接
	var supplier := _find_supplier()
	if supplier != null and supplier != self:
		_try_link(supplier, self)   # 优先：让选中的供能方链接本塔（本塔可能是已锁定供能方，也不断开它）
		return
	if is_locked:
		_break_links()              # 没有新选中供能方，且自己是供能方 → 右键自己 = 断开全部
		return
	if supplier == self:
		_clear_supplier_selection()   # 取消选中自己
	else:
		_set_supplier_selection(self) # 选中自己为供能方

## 在 tower 组里找当前选中的供能方
func _find_supplier() -> LightPower:
	for node in get_tree().get_nodes_in_group("tower"):
		var t := node as LightPower
		if t != null and t.is_supplier:
			return t
	return null

## 把 t 设为唯一供能方（先清掉旧的），并自动切换到充能模式（文档：右键后不能生产/攻击）
func _set_supplier_selection(t: LightPower) -> void:
	_clear_supplier_selection()
	t.is_supplier = true
	t._set_mode(CONDUCTION_MODEL)   # 选中为供能方 → 自动切充能模式（停普攻）
	t.queue_redraw()   # 显示传导范围圈

## 清除所有供能方选中
func _clear_supplier_selection() -> void:
	for node in get_tree().get_nodes_in_group("tower"):
		var t := node as LightPower
		if t != null and t.is_supplier:
			t.is_supplier = false
			t.queue_redraw()

## 尝试建立 supplier → target 链接（集中式：供能方预算一次全部给目标塔）
func _try_link(supplier: LightPower, target: LightPower) -> void:
	if supplier == target:
		print("不能链接自己")
		return
	if supplier.is_cooling or target.is_cooling:
		print("冷却中，无法链接")
		return
	if supplier.global_position.distance_to(target.global_position) > TowerConfig.charge_range:
		print("超出传导范围，无法链接")
		return
	# 禁止互充：目标塔已经在给供能方充能（B→A 已存在时，禁止 A→B）
	if target.outbound_target == supplier:
		print("禁止互充：目标塔已在给供能方充能")
		return
	# 禁止多塔循环：沿 target 的出链链条追溯，若某塔指向 supplier → 会形成闭环（A→B→C→A）
	var node: LightPower = target
	var hops := 0
	while node != null and hops <= 10:
		if node.outbound_target == supplier:
			print("禁止循环充能：会形成闭环")
			return
		node = node.outbound_target
		hops += 1
	# 禁止重复链接同一目标（集中式一塔只供一个目标）
	if supplier.outbound_target == target:
		print("已链接该目标")
		return
	# 集中式：供能方层数决定可供给层数（0/1/2/3 → 1/2/3/4），一次全部给目标
	var budget: int = TowerConfig.supply_budget[clampi(supplier.power_charging, 0, 3)]
	var gained := mini(budget, THREE_CHARGING - target.power_charging)
	if gained <= 0:
		print("目标已达三层充能上限")
		return
	# 供能方锁定：进入充能模式，不能生产/攻击/切模式
	supplier.is_supplier = false
	supplier.queue_redraw()
	supplier.is_locked = true
	supplier._set_mode(CONDUCTION_MODEL)   # 强制充能模式：同时停掉普攻定时器
	# 目标塔获得充能（链式传导：B 有 1 层时给 C 2 层）
	target.set_charging(target.power_charging + gained)
	# 画带箭头的链接线并记录本次供给量（断开时用于降级）
	supplier._create_link_line(target, gained)
	# 超频触发：只有【三阶充能塔】给攻击塔充能时才释放超频大招
	if supplier.power_charging >= THREE_CHARGING and target.power_model == ATTACK_MODEL:
		target._trigger_overclock()

## 供能方画一条带箭头的链接线指向目标塔，并记录目标与供给层数
func _create_link_line(target: LightPower, gained: int) -> void:
	var dir: Vector2 = target.global_position - global_position
	outbound_link = Line2D.new()
	outbound_link.points = PackedVector2Array([Vector2.ZERO, dir])
	outbound_link.width = 2.0
	outbound_link.default_color = Color(0.3, 0.8, 1.0, 0.8)
	add_child(outbound_link)
	# 箭头：三角形，尖端朝 +x，放在线中间更明显，旋转指向目标方向
	outbound_arrow = Polygon2D.new()
	outbound_arrow.polygon = PackedVector2Array([Vector2(0, -5), Vector2(14, 0), Vector2(0, 5)])
	outbound_arrow.position = dir * 0.5   # 线的中点
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
	is_supplier = false      # 断开后取消供能方选中态
	queue_redraw()
	_set_mode(CREATE_LIGHT_MODEL)   # 断开后回到制造模式（停普攻）

# ========== 攻击逻辑 ==========

## 攻击定时器触发：按充能层数的增幅同时攻击多个敌人
func _try_attack() -> void:
	if is_cooling or is_overclocked:
		return   # 冷却/超频中不普攻
	# 增幅数值来自 tower_data.tres（激光数 / 伤害倍率）
	var count: int = TowerConfig.laser_count[clampi(power_charging, 0, 3)]
	var mult: float = TowerConfig.damage_mult[clampi(power_charging, 0, 3)]
	var targets := _acquire_targets(count)
	if targets.is_empty():
		return   # 没有敌人/没有敌人在范围内 → 不开火
	for target in targets:
		target.take_damage(TowerConfig.base_damage * mult)
		_show_laser(target)

## 索敌：范围内按"最前列"（path_follow.progress 最大）排序，取前 n 个
## 充能层数越高 n 越大（1/2/3 层 → 同时打 2/3/4 个敌人）
func _acquire_targets(n: int) -> Array:
	var in_range: Array = []
	for node in get_tree().get_nodes_in_group("enemy"):
		var enemy := node as Enemy
		if enemy == null or not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) > TowerConfig.attack_range:
			continue   # 不在攻击范围内
		in_range.append(enemy)
	in_range.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		var pa := 0.0
		var pb := 0.0
		if a.path_follow != null:
			pa = a.path_follow.progress
		if b.path_follow != null:
			pb = b.path_follow.progress
		return pa > pb)
	return in_range.slice(0, n)

## 攻击视觉：从塔到目标画一条激光线，短暂发光后淡出销毁
func _show_laser(target: Enemy) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array([
		Vector2.ZERO,
		target.global_position - global_position,
	])
	line.width = 3.0
	line.default_color = Color(1.0, 0.9, 0.2, 0.9)
	add_child(line)
	var tw := create_tween()
	tw.tween_property(line, "default_color:a", 0.0, 0.15)
	tw.tween_callback(line.queue_free)

# ========== 充能层数 ==========

## 设置充能层数（0~3）并刷新外观——充能链接系统调这里
## 链式传导：本塔是供能方时，层数变化会同步调整下游已链接塔（升级补层/降级扣层）
func set_charging(level: int, _visited: Array = []) -> void:
	power_charging = clampi(level, ZERO_CHARGING, THREE_CHARGING)
	# 链式传导：按本塔最新预算重算已建链接的供给量
	if outbound_target != null:
		var new_gained: int = TowerConfig.supply_budget[clampi(power_charging, 0, 3)]
		var diff := new_gained - outbound_gained
		if diff != 0 and not (outbound_target in _visited):
			_visited.append(self)   # 记录本塔，防止 A→B→A 循环
			outbound_target.set_charging(outbound_target.power_charging + diff, _visited)
			outbound_gained = new_gained
	visual.apply_visual(power_model, power_charging)
	charging_changed.emit(power_charging)

# ========== 超频 ==========

## 触发攻击超频：停止普攻 → 沿野怪路线扫射贯穿激光 → 进入冷却
func _trigger_overclock() -> void:
	is_overclocked = true
	attack_timer.stop()   # 原本攻击停止
	_do_overclock_laser()
	_start_overclock_cooldown()

## 超频大招：从塔身下方沿野怪路线扫射贯穿激光，命中沿途所有敌人，不超过最大距离
func _do_overclock_laser() -> void:
	var path_node := get_tree().get_first_node_in_group("enemy_path") as Path2D
	if path_node == null or path_node.curve == null:
		is_overclocked = false
		return
	var curve: Curve2D = path_node.curve
	var start_progress := curve.get_closest_offset(global_position)   # 塔在路线上的投影
	var end_progress := minf(start_progress + TowerConfig.overclock_range, curve.get_baked_length())
	# 激光视觉：从塔身下方到路线终点
	var line := Line2D.new()
	line.points = PackedVector2Array([
		Vector2(0, 20),   # 塔身下方
		curve.sample_baked(end_progress) - global_position,
	])
	line.width = 6.0
	line.default_color = Color(1.0, 0.4, 0.1, 0.9)
	add_child(line)
	var tw := create_tween()
	tw.tween_property(line, "default_color:a", 0.0, 0.6)
	tw.tween_callback(line.queue_free)
	# 伤害结算：路线区间内的所有敌人
	for node in get_tree().get_nodes_in_group("enemy"):
		var enemy := node as Enemy
		if enemy == null or not is_instance_valid(enemy):
			continue
		var enemy_prog := 0.0
		if enemy.path_follow != null:
			enemy_prog = enemy.path_follow.progress
		if enemy_prog >= start_progress and enemy_prog <= end_progress:
			enemy.take_damage(TowerConfig.overclock_damage)

## 超频释放完成：本塔与给本塔充能最多的塔一起停止行动（冷却）
func _start_overclock_cooldown() -> void:
	is_overclocked = false
	_begin_cooling()   # 本塔停止行动
	var feeder := _find_strongest_feeder()
	if feeder != null:
		feeder._begin_cooling()   # 给本塔充能最多的塔也停止行动

## 找到给本塔充能层数最多的供能塔（入链中 outbound_gained 最大）
func _find_strongest_feeder() -> LightPower:
	var best: LightPower = null
	var best_gained := 0
	for node in get_tree().get_nodes_in_group("tower"):
		var t := node as LightPower
		if t != null and t.outbound_target == self:
			if t.outbound_gained > best_gained:
				best_gained = t.outbound_gained
				best = t
	return best

## 开始冷却：停止行动（不能生产/攻击/切模式/链接），Label 显示倒计时，冷却结束恢复
func _begin_cooling() -> void:
	is_cooling = true
	cooling_time_left = TowerConfig.overclock_cooldown
	attack_timer.stop()
	var tw := get_tree().create_timer(TowerConfig.overclock_cooldown)
	tw.timeout.connect(_end_cooling)

func _end_cooling() -> void:
	is_cooling = false
	cooling_time_left = 0.0
	visual.apply_visual(power_model, power_charging)   # 恢复模式/层数显示
	if is_attack and not is_locked:
		attack_timer.start()   # 恢复攻击模式普攻
