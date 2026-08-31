class_name HealthViewComponent
extends Node2D

## 头顶血条：纯 _draw 绘制，不依赖 Control，适用于 Node2D 场景。
## 敌人 / 水晶 / 塔共用；bind 到 HealthComponent 后自动跟随。

@export var bar_width := 48.0
@export var bar_height := 5.0
@export var bar_offset_y := -40.0

var _current := 0
var _maximum := 1


func bind(health: HealthComponent) -> void:
	health.health_changed.connect(_on_health_changed)
	_on_health_changed(health.get_health(), health.get_max_health())


func _on_health_changed(current: int, maximum: int) -> void:
	_current = current
	_maximum = maximum
	queue_redraw()


func _draw() -> void:
	if _maximum <= 0:
		return
	var ratio := clampf(float(_current) / float(_maximum), 0.0, 1.0)
	var bg := Rect2(Vector2(-bar_width * 0.5, bar_offset_y), Vector2(bar_width, bar_height))
	draw_rect(bg, Color(0.15, 0.15, 0.15, 0.85))
	if ratio > 0.0:
		draw_rect(Rect2(bg.position, Vector2(bar_width * ratio, bar_height)), Color(0.3, 0.8, 0.3, 1.0))
	var font := ThemeDB.fallback_font
	var text := "%d/%d" % [_current, _maximum]
	draw_string(font, Vector2(-60.0, bar_offset_y - 8.0), text, HORIZONTAL_ALIGNMENT_CENTER, 120.0, 12, Color.WHITE)
