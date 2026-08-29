extends SceneTree

const TestSuite = preload("res://tests/support/test_suite.gd")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite := TestSuite.new()
    var monster := MonsterData.new()
    suite.expect_eq(monster.monster_id, &"basic_monster", "monster id default")
    suite.expect_eq(monster.contact_damage, 10, "contact damage default")

    var grid := GridConfig.new()
    suite.expect_eq(grid.columns, 19, "grid columns")
    suite.expect_eq(grid.rows, 11, "grid rows")

    var spawn := EnemySpawnEntry.new()
    spawn.count = 3
    var wave := WaveData.new()
    wave.entries = [spawn]
    var level := LevelData.new()
    level.waves = [wave]
    suite.expect_eq(level.waves[0].entries[0].count, 3, "nested wave data")

    var level_entry := LevelCatalogEntry.new()
    level_entry.level_id = &"level_01"
    var catalog := LevelCatalog.new()
    catalog.entries = [level_entry]
    suite.expect_true(catalog.find_by_id(&"level_01") == level_entry, "catalog lookup")
    suite.finish(self)
