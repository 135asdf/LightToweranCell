class_name LightTower
extends TowerBase

func _link_gained(level: int) -> int:
	return config.supply_budget[clamp(level, 0, 3)]

func _fire(target: Node2D, mult: float) -> void:
	target.take_damage(int(config.base_damage * mult))
	_show_laser(target)
	
func _do_overclock() -> void:
	match power_model:
		Mode.ATTACK:
			_do_overclock_laser()
		Mode.PRODUCE:
			light_energy += config.overclock_production
		Mode.CONDUCTION:
			pass

func _show_laser(target: Node2D) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array([
		Vector2.ZERO,
		target.global_position - global_position,
	])
	line.width = 3.0
	line.default_color =  Color(1.0, 0.9, 0.2, 0.9)
	add_child(line)
	var tw := create_tween()
	tw.tween_property(line, "default_color", 0.0, 0.15)
	tw.tween_callback(line.queue_free)

## 攻击超频：沿野怪路线扫贯穿激光；工程暂无路径时兜底为范围内全体伤害
func _do_overclock_laser() -> void:
	var path_node := get_tree().get_first_node_in_group("enemy_path") as Path2D
	if path_node == null or path_node.curve == null:
		_fallback_overclock()   # 无路径：对攻击范围内所有敌人结算
		return
	var curve: Curve2D = path_node.curve
	var start_progress := curve.get_closest_offset(global_position)
	var end_progress := minf(start_progress + config.overclock_range, curve.get_baked_length())
	# 激光视觉：从塔身下方到路线终点
	var line := Line2D.new()
	line.points = PackedVector2Array([
		Vector2(0, 20),
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
		var enemy := node as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		var enemy_prog := _enemy_progress(enemy)
		if enemy_prog >= start_progress and enemy_prog <= end_progress:
			enemy.take_damage(int(config.overclock_damage))

## 无路径兜底：对攻击范围内所有敌人结算超频伤害
func _fallback_overclock() -> void:
	for node in get_tree().get_nodes_in_group("enemy"):
		var enemy := node as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) <= config.attack_range:
			enemy.take_damage(int(config.overclock_damage))
