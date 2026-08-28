extends Control


# 返回按钮回调：回到首页。
func _on_backbutton_pressed() -> void:
	SceneManager.goto("main")


# 关卡按钮回调：进入选中的关卡场景。
func _on_level_button_pressed(level: String) -> void:
	SceneManager.goto(level)
