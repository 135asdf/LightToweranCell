class_name MovementComponent
extends Node

signal destination_reached

var _body: CharacterBody2D
var _target_component: TargetComponent
var _speed: float
var _reach_distance: float
var _speed_multiplier: float = 1.0
var _running: bool = false
var _reached: bool = false

func configure(body: CharacterBody2D, target: TargetComponent, speed: float, reach_distance: float) -> void:
    _body = body
    _target_component = target
    _speed = maxf(0.0, speed)
    _reach_distance = maxf(1.0, reach_distance)
    _reached = false

func start() -> void:
    _running = true

func stop() -> void:
    _running = false
    if _body != null:
        _body.velocity = Vector2.ZERO

func set_speed_multiplier(value: float) -> void:
    _speed_multiplier = clampf(value, 0.0, 1.0)

func tick(delta: float) -> void:
    if not _running:
        return
    var target := _target_component.get_target() if _target_component != null else null
    if _body == null or target == null or _reached:
        return
    var distance := _body.global_position.distance_to(target.global_position)
    if distance <= _reach_distance:
        _reached = true
        stop()
        destination_reached.emit()
        return
    _body.velocity = _body.global_position.direction_to(target.global_position) * _speed * _speed_multiplier
    _body.move_and_slide()

func _physics_process(delta: float) -> void:
    if _running:
        tick(delta)
