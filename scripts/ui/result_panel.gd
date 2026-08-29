class_name ResultPanel
extends Control

signal restart_requested
signal level_select_requested
signal home_requested

@onready var title_label: Label = %TitleLabel
@onready var restart_button: Button = %RestartButton
@onready var level_select_button: Button = %LevelSelectButton
@onready var home_button: Button = %HomeButton

func _ready() -> void:
    restart_button.pressed.connect(restart_requested.emit)
    level_select_button.pressed.connect(level_select_requested.emit)
    home_button.pressed.connect(home_requested.emit)
    hide_result()

func show_result(won: bool) -> void:
    title_label.text = "胜利" if won else "失败"
    visible = true

func hide_result() -> void:
    visible = false
