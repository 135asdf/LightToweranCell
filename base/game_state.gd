class_name GameState
extends RefCounted

## 全局运行时状态（进程级静态）：塔背包跨关卡持久。
## 用 class_name + static 而非 autoload，避免 -s 测试模式不加载 autoload 的问题。

static var inventory: Inventory = Inventory.new()
static var _starting_initialized := false


## 首次调用时填充初始背包：1 座光能塔 + 4 座随机塔（从 TowerCatalog 池随机）。
## 每个进程只初始化一次；已在背包里加过塔（或已初始化）则跳过。
static func ensure_starting_inventory(catalog: TowerCatalog) -> void:
	if _starting_initialized:
		return
	_starting_initialized = true
	inventory.add(&"light_tower", 1)
	if catalog == null:
		return
	var pool: Array[StringName] = []
	for entry in catalog.entries:
		if entry != null and entry.data != null and entry.data.tower_id != &"light_tower":
			pool.append(entry.data.tower_id)
	for i in range(4):
		if pool.is_empty():
			break
		inventory.add(pool.pick_random(), 1)


## 测试用：重置全局状态（每个测试进程独立，互不影响）
static func reset() -> void:
	inventory = Inventory.new()
	_starting_initialized = false
