extends SceneTree
const TestSuite = preload("res://tests/support/test_suite.gd")
const LevelScene = preload("res://scenes/levels/level_01.tscn")
const EnemyScene = preload("res://scenes/enemies/enemy_streptococcus.tscn")

func _init() -> void:
    call_deferred("_run")

func _single_enemy_level_data(source: LevelData) -> LevelData:
    var data := source.duplicate(true) as LevelData
    var entry := EnemySpawnEntry.new()
    entry.enemy_scene = EnemyScene
    entry.count = 1
    entry.interval = 0.0
    entry.spawn_point_id = &"north"
    var wave := WaveData.new()
    wave.start_delay = 0.0
    wave.end_delay = 0.0
    wave.wait_for_clear = false
    wave.entries = [entry]
    data.waves = [wave]
    data.starting_energy = 100
    return data

func _run() -> void:
    var suite := TestSuite.new()
    var level := LevelScene.instantiate() as LevelController
    level.level_data = _single_enemy_level_data(level.level_data)
    root.add_child(level)
    await process_frame
    suite.expect_true(level.placement.select_tower(&"plasma_cell"), "select plasma tower")
    var build_cell := Vector2i(0, 0)
    var placed_tower := level.placement.place_at_world(level.build_grid.cell_to_world(build_cell))
    suite.expect_true(placed_tower is TowerBase, "tower placed through component")
    for _step in range(4):
        level.spawner.tick(1.0)
    var enemies := get_nodes_in_group("enemy")
    suite.expect_eq(enemies.size(), 1, "one enemy spawned")
    (enemies[0] as MonsterBase).take_damage(100000)
    await process_frame
    await process_frame
    suite.expect_eq(level.goal.outcome, LevelGoalComponent.Outcome.WON, "level reaches win")
    suite.expect_eq(get_nodes_in_group("1_enemy").size(), 0, "legacy group absent")

    paused = false
    level.queue_free()
    await process_frame
    var loss_level := LevelScene.instantiate() as LevelController
    loss_level.level_data = _single_enemy_level_data(loss_level.level_data)
    root.add_child(loss_level)
    await process_frame
    var loss_count := [0]
    loss_level.goal.level_lost.connect(func(): loss_count[0] += 1)
    loss_level.crystal.take_contact_damage(100000)
    loss_level.crystal.take_contact_damage(100000)
    suite.expect_eq(loss_count[0], 1, "level loss emits once")
    suite.expect_eq(loss_level.goal.outcome, LevelGoalComponent.Outcome.LOST, "loss blocks later win")
    paused = false
    suite.finish(self)
