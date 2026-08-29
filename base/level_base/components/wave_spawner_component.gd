class_name WaveSpawnerComponent
extends Node

signal enemy_spawned(enemy: MonsterBase)
signal wave_started(index: int)
signal wave_completed(index: int)
signal all_waves_spawned

enum State { IDLE, START_DELAY, SPAWNING, END_DELAY, COMPLETE }

var _waves: Array[WaveData] = []
var _enemies_container: Node2D
var _target: Node2D
var _spawn_points: Dictionary[StringName, Marker2D] = {}
var _state := State.IDLE
var _wave_index := 0
var _entry_index := 0
var _unit_index := 0
var _timer := 0.0
var _active_spawned := 0
var _running := false

func configure(
    waves: Array[WaveData],
    enemies_container: Node2D,
    target: Node2D,
    spawn_points: Dictionary[StringName, Marker2D]
) -> void:
    _waves = waves
    _enemies_container = enemies_container
    _target = target
    _spawn_points = spawn_points
    _state = State.IDLE
    _wave_index = 0
    _active_spawned = 0

func start() -> void:
    _running = true
    if _waves.is_empty():
        _state = State.COMPLETE
        all_waves_spawned.emit()
        return
    _wave_index = 0
    _state = State.START_DELAY
    _timer = _waves[0].start_delay

func stop() -> void:
    _running = false

func tick(delta: float) -> void:
    if not _running or _state == State.COMPLETE:
        return
    match _state:
        State.START_DELAY:
            _timer -= delta
            if _timer <= 0.0:
                _state = State.SPAWNING
                wave_started.emit(_wave_index)
                _timer = 0.0
        State.SPAWNING:
            _timer -= delta
            if _timer <= 0.0:
                _spawn_one()
        State.END_DELAY:
            _timer -= delta
            if _timer <= 0.0:
                _advance_wave()

func _process(delta: float) -> void:
    if _running:
        tick(delta)

func _spawn_one() -> void:
    var wave := _waves[_wave_index]
    while _entry_index < wave.entries.size():
        var entry := wave.entries[_entry_index]
        if entry == null or entry.enemy_scene == null:
            _entry_index += 1
            continue
        _spawn_enemy(entry)
        _unit_index += 1
        if _unit_index >= entry.count:
            _unit_index = 0
            _entry_index += 1
        _timer = entry.interval
        return
    wave_completed.emit(_wave_index)
    _state = State.END_DELAY
    _timer = wave.end_delay

func _spawn_enemy(entry: EnemySpawnEntry) -> void:
    var enemy := entry.enemy_scene.instantiate() as MonsterBase
    if enemy == null:
        push_error("EnemySpawnEntry scene root must be MonsterBase")
        return
    if _enemies_container != null:
        _enemies_container.add_child(enemy)
    else:
        get_parent().add_child(enemy)
    var spawn_point: Marker2D = _spawn_points.get(entry.spawn_point_id) as Marker2D
    if spawn_point != null:
        enemy.global_position = spawn_point.global_position
    if _target != null:
        enemy.setup_target(_target)
    _active_spawned += 1
    enemy.tree_exiting.connect(_on_enemy_exiting, CONNECT_ONE_SHOT)
    enemy_spawned.emit(enemy)

func _on_enemy_exiting() -> void:
    _active_spawned = maxi(0, _active_spawned - 1)

func _advance_wave() -> void:
    var wave := _waves[_wave_index]
    if wave.wait_for_clear and _active_spawned > 0:
        _timer = 0.0
        return
    _wave_index += 1
    if _wave_index >= _waves.size():
        _state = State.COMPLETE
        all_waves_spawned.emit()
        return
    _state = State.START_DELAY
    _timer = _waves[_wave_index].start_delay
