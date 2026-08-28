extends Control


# 音频按钮回调：切换主音量总线的静音状态。
func _on_audio_button_pressed() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus, not AudioServer.is_bus_mute(bus))


# 开始按钮回调：进入关卡选择界面。
func _on_start_button_pressed() -> void:
	SceneManager.goto("level_selection")


# 实验室按钮回调：进入实验室界面。
func _on_lab_button_pressed() -> void:
	SceneManager.goto("lab")
