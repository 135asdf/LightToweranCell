class_name LevelGoalComponent
extends Node

signal level_won
signal level_lost

enum Outcome { RUNNING, WON, LOST }

var outcome := Outcome.RUNNING
var _all_waves_spawned := false
var _active_enemies := 0

func bind(spawner: WaveSpawnerComponent, crystal: CrystalController) -> void:
    spawner.enemy_spawned.connect(register_enemy)
    spawner.all_waves_spawned.connect(_on_all_waves_spawned)
    crystal.crystal_destroyed.connect(_on_crystal_destroyed)

func register_enemy(enemy: MonsterBase) -> void:
    _active_enemies += 1
    enemy.tree_exiting.connect(_on_enemy_exiting, CONNECT_ONE_SHOT)

func _on_enemy_exiting() -> void:
    _active_enemies = maxi(0, _active_enemies - 1)
    _evaluate_win()

func _on_all_waves_spawned() -> void:
    _all_waves_spawned = true
    _evaluate_win()

func _evaluate_win() -> void:
    if outcome == Outcome.RUNNING and _all_waves_spawned and _active_enemies == 0:
        outcome = Outcome.WON
        level_won.emit()

func _on_crystal_destroyed() -> void:
    if outcome == Outcome.RUNNING:
        outcome = Outcome.LOST
        level_lost.emit()
