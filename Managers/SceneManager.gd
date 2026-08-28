extends Node

# 全局场景切换器（autoload）。
# 关卡路径按 Map/<编号>_level/<编号>_level.tscn 规则统一生成，界面场景单独登记。

const SCENES := {
	"main": "res://Main/main.tscn",
	"level_selection": "res://LevelSelection/level_selection.tscn",
	"lab": "res://Lab/lab.tscn",
}

const LEVEL_COUNT := 15

var _history: Array[String] = []


# 根据关卡编号生成该关卡的场景文件路径。
func _level_path(id: int) -> String:
	return "res://Map/%d_level/%d_level.tscn" % [id, id]


# 切换到指定场景：先记录当前场景到历史，再执行切换。
func goto(scene_name: String) -> void:
	var path := _scene_path(scene_name)
	if path == "":
		push_error("SceneManager: 未登记的场景名 '%s'" % scene_name)
		return
	var here := current_scene_name()
	if here != "":
		_history.append(here)
	_change(path)


# 返回历史记录中的上一个场景；无历史则不做任何事。
func back() -> void:
	if _history.is_empty():
		return
	_change(_scene_path(_history.pop_back()))


# 重新加载当前场景（先解除暂停，避免新场景被冻结）。
func reload() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


# 返回当前场景的逻辑名称（main / level_selection / lab / level_<编号> / 空字符串）。
func current_scene_name() -> String:
	var scene := get_tree().current_scene
	if scene == null:
		return ""
	if scene.scene_file_path == SCENES["main"]:
		return "main"
	if scene.scene_file_path == SCENES["level_selection"]:
		return "level_selection"
	if scene.scene_file_path == SCENES["lab"]:
		return "lab"
	for id in range(1, LEVEL_COUNT + 1):
		if scene.scene_file_path == _level_path(id):
			return "level_%d" % id
	return ""


# 根据场景逻辑名解析出场景文件路径；无法识别则返回空字符串。
func _scene_path(scene_name: String) -> String:
	if SCENES.has(scene_name):
		return SCENES[scene_name]
	if scene_name.begins_with("level_"):
		var id := scene_name.trim_prefix("level_").to_int()
		if id >= 1 and id <= LEVEL_COUNT:
			return _level_path(id)
	return ""


# 实际执行场景切换：先解除暂停再切换，失败时输出错误日志。
func _change(path: String) -> void:
	# 地图在游戏结束时会把 tree 暂停，切场景前必须解除，否则新场景是冻住的。
	get_tree().paused = false
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("SceneManager: 切换场景失败 '%s'（错误码 %d）" % [path, err])
