extends SceneTree
const TestSuite = preload("res://tests/support/test_suite.gd")
const EnemyScene = preload("res://scenes/enemies/normal/enemy_streptococcus.tscn")
const CrystalScene = preload("res://base/level_base/crystal_base.tscn")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite := TestSuite.new()
    var enemies := Node2D.new()
    var marker := Marker2D.new()
    var crystal := CrystalScene.instantiate() as CrystalController
    var spawner := WaveSpawnerComponent.new()
    var goal := LevelGoalComponent.new()
    root.add_child(enemies)
    root.add_child(marker)
    root.add_child(crystal)
    root.add_child(spawner)
    root.add_child(goal)
    crystal.configure(20)

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

    var spawned: Array[MonsterBase] = []
    var all_spawned := [false]
    var win_count := [0]
    spawner.enemy_spawned.connect(func(enemy: MonsterBase): spawned.append(enemy))
    spawner.all_waves_spawned.connect(func(): all_spawned[0] = true)
    goal.level_won.connect(func(): win_count[0] += 1)
    spawner.configure([wave], enemies, crystal, {&"north": marker})
    goal.bind(spawner, crystal)
    spawner.start()
    for _step in range(4):
        spawner.tick(1.0)
    suite.expect_eq(spawned.size(), 1, "configured enemy count")
    suite.expect_true(all_spawned[0], "all waves signal")
    suite.expect_eq(win_count[0], 0, "no win while enemy is active")
    spawned[0].queue_free()
    await process_frame
    suite.expect_eq(win_count[0], 1, "win after final enemy exits")

    var loss_goal := LevelGoalComponent.new()
    var loss_spawner := WaveSpawnerComponent.new()
    var loss_crystal := CrystalScene.instantiate() as CrystalController
    root.add_child(loss_goal)
    root.add_child(loss_spawner)
    root.add_child(loss_crystal)
    loss_crystal.configure(5)
    var loss_count := [0]
    loss_goal.level_lost.connect(func(): loss_count[0] += 1)
    loss_goal.bind(loss_spawner, loss_crystal)
    loss_crystal.take_contact_damage(5)
    loss_crystal.take_contact_damage(5)
    suite.expect_eq(loss_count[0], 1, "loss emits once")
    suite.finish(self)
