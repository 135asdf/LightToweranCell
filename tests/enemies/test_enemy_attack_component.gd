extends SceneTree
const TestSuite = preload("res://tests/support/test_suite.gd")
const EnemyScene = preload("res://scenes/enemies/normal/enemy_streptococcus.tscn")
const PlasmaScene = preload("res://scenes/towers/tower_plasma_cell.tscn")

class DamageTarget extends Node2D:
    var received := 0
    func take_contact_damage(amount: int) -> void:
        received += amount

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite := TestSuite.new()
    # 塔：20 血、无护盾，放在敌人行进路线上
    var tower_data := TowerData.new()
    tower_data.max_health = 20
    tower_data.max_shield = 0
    var tower := PlasmaScene.instantiate() as TowerBase
    tower.config = tower_data
    tower.position = Vector2(0, 0)
    root.add_child(tower)
    # 目标（模拟水晶）
    var target := DamageTarget.new()
    target.position = Vector2(200, 0)
    root.add_child(target)
    # 敌人：可拆塔参数
    var md := MonsterData.new()
    md.max_health = 100
    md.move_speed = 80.0
    md.contact_damage = 5
    md.tower_attack_damage = 5
    md.tower_attack_interval = 0.2
    md.tower_attack_range = 60.0
    var enemy := EnemyScene.instantiate() as MonsterBase
    enemy.monster_data = md
    enemy.position = Vector2(-100, 0)
    root.add_child(enemy)
    enemy.setup_target(target)

    # 阶段 1：等塔被拆毁（最多 6 秒真实时间）
    var elapsed := 0.0
    while not tower.is_destroyed and elapsed < 6.0:
        await create_timer(0.1).timeout
        elapsed += 0.1
    suite.expect_true(tower.is_destroyed, "tower destroyed by enemy")
    suite.expect_true(tower.health_component.get_health() < tower_data.max_health, "tower took damage")

    # 阶段 2：塔毁后碰撞体移除，敌人继续前进到达目标（最多 8 秒）
    var elapsed2 := 0.0
    while target.received == 0 and elapsed2 < 8.0:
        await create_timer(0.1).timeout
        elapsed2 += 0.1
    suite.expect_true(target.received > 0, "enemy reaches target after tower falls")
    suite.finish(self)
