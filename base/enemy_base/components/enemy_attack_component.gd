class_name EnemyAttackComponent
extends Node

## 敌人拆塔：在移动方向前方找最近塔，进入攻击范围则停下周期攻击；
## 塔被拆毁（is_destroyed）后恢复移动，继续走向水晶。

var _body: CharacterBody2D
var _target_component: TargetComponent
var _movement: MovementComponent
var _damage := 0
var _interval := 1.0
var _range := 60.0
var _timer := 0.0
var _current_tower: TowerBase = null
var _running := true


func configure(
    body: CharacterBody2D,
    target: TargetComponent,
    movement: MovementComponent,
    data: MonsterData
) -> void:
    _body = body
    _target_component = target
    _movement = movement
    _damage = maxi(0, data.tower_attack_damage)
    _interval = maxf(0.1, data.tower_attack_interval)
    _range = maxf(1.0, data.tower_attack_range)


func stop() -> void:
    _running = false


func _physics_process(delta: float) -> void:
    if not _running or _body == null or _target_component == null:
        return
    var tower := _find_blocking_tower()
    if tower != null:
        if _current_tower != tower:
            _current_tower = tower
            _timer = 0.0
        _movement.stop()
        _timer -= delta
        if _timer <= 0.0:
            _timer = _interval
            tower.take_damage(_damage)
            if tower.is_destroyed:
                _current_tower = null
                _movement.start()
    elif _current_tower != null:
        _current_tower = null
        _movement.start()


## 找移动方向前方、距离最近且未损坏的塔
func _find_blocking_tower() -> TowerBase:
    var target := _target_component.get_target()
    if target == null:
        return null
    var dir := (target.global_position - _body.global_position).normalized()
    var best: TowerBase = null
    var best_d := INF
    for node in get_tree().get_nodes_in_group("tower"):
        var t := node as TowerBase
        if t == null or t.is_destroyed:
            continue
        var to_tower := t.global_position - _body.global_position
        if to_tower.dot(dir) < 0.0:
            continue   # 塔在移动方向后方，跳过
        var d := to_tower.length()
        if d <= _range and d < best_d:
            best_d = d
            best = t
    return best
