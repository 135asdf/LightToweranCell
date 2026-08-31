class_name LevelHUD
extends CanvasLayer

@onready var energy_label: Label = %EnergyLabel
@onready var inventory_box: VBoxContainer = %InventoryBox

var _placement: TowerPlacementComponent
var _inventory: Inventory
var _catalog: TowerCatalog


func bind(
	_level: LevelController,
	economy: EconomyComponent,
	placement: TowerPlacementComponent,
	_goal: LevelGoalComponent,
	inventory: Inventory,
	catalog: TowerCatalog
) -> void:
	_placement = placement
	_inventory = inventory
	_catalog = catalog
	economy.balance_changed.connect(_on_balance_changed)
	_on_balance_changed(economy.get_balance())
	refresh_inventory()


## 从背包重建塔按钮：数量 0 灰显，点击选中塔（接 TowerPlacementComponent）
func refresh_inventory() -> void:
	for child in inventory_box.get_children():
		child.queue_free()
	if _inventory == null or _catalog == null:
		return
	for tower_id: StringName in _inventory.get_counts().keys():
		var count := _inventory.count(tower_id)
		var entry := _catalog.find_by_id(tower_id)
		var button := Button.new()
		var display := String(tower_id)
		if entry != null and entry.data != null and entry.data.display_name != "":
			display = entry.data.display_name
		button.text = "%s x%d" % [display, count]
		button.disabled = count <= 0
		button.pressed.connect(_placement.select_tower.bind(tower_id))
		inventory_box.add_child(button)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_placement.place_at_world(event.position)


func _on_balance_changed(balance: int) -> void:
	energy_label.text = str(balance)
