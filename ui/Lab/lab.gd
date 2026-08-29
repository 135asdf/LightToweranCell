extends Control


# 返回按钮回调：回到首页。
func _on_backbutton_pressed() -> void:
	SceneManager.goto("main")
