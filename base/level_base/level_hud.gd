class_name LevelHUD
extends CanvasLayer

@onready var crystal_health_bar: ProgressBar = %CrystalHealthBar
@onready var crystal_health_label: Label = %CrystalHealthLabel
@onready var energy_label: Label = %EnergyLabel
@onready var plasma_button: Button = %PlasmaButton
@onready var light_button: Button = %LightButton

var _placement: TowerPlacementComponent

func bind(
	_level: LevelController,
	health: HealthComponent,
	economy: EconomyComponent,
	placement: TowerPlacementComponent,
	_goal: LevelGoalComponent
) -> void:
	_placement = placement
	health.health_changed.connect(_on_health_changed)
	economy.balance_changed.connect(_on_balance_changed)
	plasma_button.pressed.connect(placement.select_tower.bind(&"plasma_cell"))
	light_button.pressed.connect(placement.select_tower.bind(&"light_tower"))
	_on_health_changed(health.get_health(), health.get_max_health())
	_on_balance_changed(economy.get_balance())

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_placement.place_at_world(event.position)

func _on_health_changed(current: int, maximum: int) -> void:
	crystal_health_bar.max_value = maximum
	crystal_health_bar.value = current
	crystal_health_label.text = "%d/%d" % [current, maximum]

func _on_balance_changed(balance: int) -> void:
	energy_label.text = str(balance)
