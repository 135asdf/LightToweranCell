class_name TowerCatalog
extends Resource

@export var entries: Array[TowerCatalogEntry] = []

func find_by_id(id: StringName) -> TowerCatalogEntry:
	for entry in entries:
		if entry != null and entry.tower_id == id:
			return entry
	return null
