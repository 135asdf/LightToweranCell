class_name LevelCatalog
extends Resource

@export var entries: Array[LevelCatalogEntry] = []

func find_by_id(id: StringName) -> LevelCatalogEntry:
    for entry in entries:
        if entry != null and entry.level_id == id:
            return entry
    return null
