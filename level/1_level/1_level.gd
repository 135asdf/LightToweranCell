extends Node2D

@export var crystal_max_hp: int = 100

const CELL_TYPES := [
	{
		"name": "浆细胞",
		"texture": preload("res://Textures/towers/tower_plasma_cell/tower_plasma_cell.png"),
		"scene": preload("res://scenes/towers/tower_plasma_cell.tscn"),
		"stats": { "fire_rate": 1.0, "damage": 20, "bullet_speed": 320.0 },
	},
]
# 本关会刷的怪物（和上面的塔一样，用多少就声明多少）。
const ENEMY_TYPES := [
	preload("res://scenes/enemies/enemy_streptococcus.tscn"),
]
const SLOT_SIZE := Vector2(64, 64)
# 整片网格的列数、行数与格子间距（64×64 格子，奇数行列保证水晶落在正中央格子里）。
const GRID_COLS: int = 19
const GRID_ROWS: int = 11
const GRID_SPACING: int = 64

var crystal_hp: int

@onready var towers_node: Node2D = $Towers
@onready var crystal_hp_bar: ProgressBar = $HUD/CrystalHealthBar
@onready var crystal_hp_text: Label = $HUD/CrystalHPText

var slots: Array[Area2D] = []
var slot_occupied: Dictionary = {}


# 就绪时初始化：设满水晶血量、刷新 UI，再生成地图格子并连接水晶碰撞。
func _ready() -> void:
	crystal_hp = crystal_max_hp
	_update_crystal_ui()
	_setup_world_slots()
	$Background/Grid/Crystal.body_entered.connect(_on_crystal_body_entered)


# 生成铺满整屏的放置格（GRID_COLS×GRID_ROWS），格子仅靠碰撞判定，
# 中央格子预留给水晶并标记为已占用。
func _setup_world_slots() -> void:
	var shape := RectangleShape2D.new()
	shape.size = SLOT_SIZE
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			var slot := Area2D.new()
			slot.name = "slot_%d_%d" % [col, row]
			slot.position = _grid_position(col, row)
			var cs := CollisionShape2D.new()
			cs.shape = shape
			slot.add_child(cs)
			$Background/Grid/Slots.add_child(slot)
			slots.append(slot)
			# 水晶占位：奇数网格占正中央一格，偶数网格占正中央 2×2 四格。
			var is_center := false
			if GRID_COLS % 2 == 1 and GRID_ROWS % 2 == 1:
				is_center = (col == GRID_COLS / 2 and row == GRID_ROWS / 2)
			else:
				is_center = (col >= GRID_COLS / 2 - 1 and col <= GRID_COLS / 2
					and row >= GRID_ROWS / 2 - 1 and row <= GRID_ROWS / 2)
			slot_occupied[slot.name] = is_center


# 返回指定列/行格子相对 Grid 的局部坐标（网格整体居中，水晶落在网格正中央，偶数网格同样居中）。
func _grid_position(col: int, row: int) -> Vector2:
	return Vector2(
		(col - (GRID_COLS - 1) / 2.0) * GRID_SPACING,
		(row - (GRID_ROWS - 1) / 2.0) * GRID_SPACING
	)


# 水晶碰撞回调：敌人撞到水晶时对水晶造成伤害并销毁该敌人。
func _on_crystal_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		var dmg: int = body.get("damage")
		_damage_crystal(dmg)
		body.queue_free()


# 扣除水晶血量并刷新 UI，血尽则触发游戏结束。
func _damage_crystal(amount: int) -> void:
	crystal_hp = clampi(crystal_hp - amount, 0, crystal_max_hp)
	_update_crystal_ui()
	if crystal_hp <= 0:
		_game_over()


# 刷新水晶血条与血量文本。
func _update_crystal_ui() -> void:
	crystal_hp_bar.max_value = crystal_max_hp
	crystal_hp_bar.value = crystal_hp
	crystal_hp_text.text = "%d/%d" % [crystal_hp, crystal_max_hp]


# 游戏结束：暂停游戏并弹出结算界面。
func _game_over() -> void:
	get_tree().paused = true
	_show_game_over_ui()


# 动态构建并显示游戏结束界面（标题、提示与三个按钮）。
func _show_game_over_ui() -> void:
	var overlay := Control.new()
	overlay.name = "GameOver"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	$HUD.add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.05, 0.08, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.9, 0.4, 0.5, 0.6)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.content_margin_left = 48.0
	style.content_margin_right = 48.0
	style.content_margin_top = 32.0
	style.content_margin_bottom = 32.0
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 28)
	panel.add_child(box)

	var title := Label.new()
	title.text = "游戏结束"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.85))
	box.add_child(title)

	var hint := Label.new()
	hint.text = "水晶被摧毁了"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.85, 0.7, 0.72))
	box.add_child(hint)

	var restart := Button.new()
	restart.text = "重新开始"
	restart.custom_minimum_size = Vector2(200, 48)
	restart.add_theme_font_size_override("font_size", 20)
	restart.pressed.connect(_on_restart_pressed)
	box.add_child(restart)

	var level_select := Button.new()
	level_select.text = "返回关卡选择"
	level_select.custom_minimum_size = Vector2(200, 48)
	level_select.add_theme_font_size_override("font_size", 20)
	level_select.pressed.connect(_on_level_select_pressed)
	box.add_child(level_select)

	var home := Button.new()
	home.text = "返回首页"
	home.custom_minimum_size = Vector2(200, 48)
	home.add_theme_font_size_override("font_size", 20)
	home.pressed.connect(_on_home_pressed)
	box.add_child(home)


# 重新开始按钮回调：解除暂停并重载当前关卡。
func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


# 返回关卡选择按钮回调：跳转到关卡选择界面。
func _on_level_select_pressed() -> void:
	SceneManager.goto("level_selection")


# 返回首页按钮回调：跳转到主界面。
func _on_home_pressed() -> void:
	SceneManager.goto("main")
