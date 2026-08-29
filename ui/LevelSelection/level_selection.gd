extends Control

@export var catalog: LevelCatalog
@onready var level_buttons: GridContainer = %LevelButtons


func _ready() -> void:
	for child in level_buttons.get_children():
		child.queue_free()
	if catalog == null:
		push_error("LevelSelection requires LevelCatalog")
		return
	for entry in catalog.entries:
		if entry == null or entry.scene == null:
			continue
		var button := Button.new()
		button.text = entry.display_name
		button.set_meta("level_id", entry.level_id)
		button.disabled = not entry.default_unlocked
		button.pressed.connect(_goto_level.bind(entry))
		level_buttons.add_child(button)


# 返回按钮回调：回到首页。SceneManager 是 autoload，但 headless 测试模式不加载，
# 故用节点查找代替标识符。
func _on_backbutton_pressed() -> void:
	var sm := get_node_or_null("/root/SceneManager")
	if sm != null and sm.has_method("goto"):
		sm.goto("main")


# 关卡按钮回调：进入选中的关卡。
func _goto_level(entry: LevelCatalogEntry) -> void:
	var sm := get_node_or_null("/root/SceneManager")
	if sm != null and sm.has_method("goto_level"):
		sm.goto_level(entry)
