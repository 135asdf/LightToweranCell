extends Node

# 全局场景切换器（autoload）。
# 关卡由 LevelCatalog 驱动，界面场景单独登记；历史记录保存实际场景路径。

@export var level_catalog: LevelCatalog

const SCENES := {
	"main": "res://ui/Main/main.tscn",
	"level_selection": "res://ui/LevelSelection/level_selection.tscn",
	"lab": "res://ui/Lab/lab.tscn",
}

var _history: Array[String] = []


# 从目录解析关卡场景；未登记返回 null。
func resolve_level_scene(level_id: StringName) -> PackedScene:
	var entry := level_catalog.find_by_id(level_id) if level_catalog != null else null
	return entry.scene if entry != null else null


# 进入目录条目对应的关卡。
func goto_level(entry: LevelCatalogEntry) -> void:
	if entry == null or entry.scene == null:
		push_error("SceneManager: invalid LevelCatalogEntry")
		return
	_remember_current_scene()
	get_tree().paused = false
	var err := get_tree().change_scene_to_packed(entry.scene)
	if err != OK:
		push_error("SceneManager: level change failed with %d" % err)


# 切换到指定界面场景：先记录当前场景到历史，再执行切换。
func goto(scene_name: String) -> void:
	var path := _scene_path(scene_name)
	if path == "":
		push_error("SceneManager: 未登记的场景名 '%s'" % scene_name)
		return
	_remember_current_scene()
	_change(path)


# 记录当前场景的实际文件路径到历史。
func _remember_current_scene() -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.scene_file_path != "":
		_history.append(scene.scene_file_path)


# 返回历史记录中的上一个场景；无历史则不做任何事。
func back() -> void:
	if _history.is_empty():
		return
	_change(_history.pop_back())


# 重新加载当前场景（先解除暂停，避免新场景被冻结）。
func reload() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


# 根据界面场景名解析出场景文件路径；无法识别则返回空字符串。
func _scene_path(scene_name: String) -> String:
	if SCENES.has(scene_name):
		return SCENES[scene_name]
	return ""


# 实际执行场景切换：先解除暂停再切换，失败时输出错误日志。
func _change(path: String) -> void:
	get_tree().paused = false
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("SceneManager: 切换场景失败 '%s'（错误码 %d）" % [path, err])
