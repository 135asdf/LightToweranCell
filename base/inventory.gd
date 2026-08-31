class_name Inventory
extends RefCounted

## 塔背包：塔 id → 数量。运行时数据，不写入 Resource。
## 第五阶段接背包 UI / 全局持久化时复用。

var _counts: Dictionary[StringName, int] = {}


func add(tower_id: StringName, amount: int = 1) -> void:
	if amount <= 0:
		return
	_counts[tower_id] = _counts.get(tower_id, 0) + amount


func remove(tower_id: StringName, amount: int = 1) -> bool:
	if amount <= 0:
		return true
	var current: int = _counts.get(tower_id, 0)
	if current < amount:
		return false
	if current == amount:
		_counts.erase(tower_id)
	else:
		_counts[tower_id] = current - amount
	return true


func count(tower_id: StringName) -> int:
	return _counts.get(tower_id, 0)


func total() -> int:
	var sum := 0
	for value: int in _counts.values():
		sum += value
	return sum


func get_counts() -> Dictionary:
	return _counts.duplicate()
